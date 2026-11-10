#!/usr/bin/env python3
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
"""
Credit the assignees of the issues that a pull request fixes.

Gather who is already credited in the pull request: its author, the authors of
its commits, and the Co-authored-by trailers in its description and commit
messages. Then add a Co-authored-by trailer to the description for every
assignee of a closing issue who is missing. Since pull requests are squash
merged with their description as the commit message, the trailers end up in
the commit.

Requires the GitHub CLI (gh), authenticated with permission to edit the pull
request.
"""

import argparse
import json
import os
import re
import subprocess
import sys

QUERY = """
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      body
      author { login }
      closingIssuesReferences(first: 50) {
        nodes {
          number
          assignees(first: 20) { nodes { login } }
        }
      }
      commits(first: 250) {
        nodes {
          commit {
            message
            authors(first: 20) { nodes { email user { login } } }
          }
        }
      }
    }
  }
}
"""

CO_AUTHORED_BY = re.compile(
    r"^co-authored-by:\s*(.*?)\s*<([^>]+)>\s*$", re.IGNORECASE | re.MULTILINE
)
# Requiring a space after the colon keeps a line ending in a URL from counting.
TRAILER = re.compile(r"^[\w-]+:\s+\S")


def gh(*args: str, stdin: str | None = None) -> str:
    result = subprocess.run(["gh", *args], input=stdin, capture_output=True, text=True, check=True)
    return result.stdout


def co_author_emails(text: str) -> set[str]:
    return {email.lower() for _name, email in CO_AUTHORED_BY.findall(text)}


def identity(login: str) -> tuple[str, set[str]]:
    """
    Return the Co-authored-by value for a user, and every email address that
    identifies them.

    This matches how the trailer is built by hand: the name falls back to the
    login, and the email falls back to the noreply address built from the user
    id.
    """
    user = json.loads(gh("api", f"/users/{login}"))
    noreply = f"{user['id']}+{user['login']}@users.noreply.github.com"
    name = user.get("name") or user["login"]
    email = user.get("email") or noreply
    emails = {email, noreply, f"{user['login']}@users.noreply.github.com"}
    return f"{name} <{email}>", {e.lower() for e in emails}


def append_trailers(body: str, trailers: list[str]) -> str:
    newline = "\r\n" if "\r\n" in body else "\n"
    body = body.rstrip()
    if not body:
        return newline.join(trailers)

    # Join an existing trailer block at the end, so all trailers stay together
    # in the last paragraph, as git expects.
    last_line = body.splitlines()[-1]
    separator = newline if TRAILER.match(last_line) else newline * 2
    return body + separator + newline.join(trailers)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("number", type=int, help="pull request number")
    parser.add_argument(
        "--repo",
        default=os.environ.get("GITHUB_REPOSITORY", "endlessm/threadbare"),
        help="repository as OWNER/NAME (default: %(default)s)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print the new description instead of editing the pull request",
    )
    args = parser.parse_args()

    owner, name = args.repo.split("/")
    response = json.loads(
        gh(
            "api",
            "graphql",
            "-f",
            f"query={QUERY}",
            "-F",
            f"owner={owner}",
            "-F",
            f"name={name}",
            "-F",
            f"number={args.number}",
        )
    )
    pull = response["data"]["repository"]["pullRequest"]
    body = pull["body"] or ""

    credited_logins = set()
    if pull["author"]:
        credited_logins.add(pull["author"]["login"].lower())
    credited_emails = co_author_emails(body)
    for node in pull["commits"]["nodes"]:
        commit = node["commit"]
        credited_emails |= co_author_emails(commit["message"])
        # These include the co-authors that GitHub recognized in the message.
        for author in commit["authors"]["nodes"]:
            if author["email"]:
                credited_emails.add(author["email"].lower())
            if author["user"]:
                credited_logins.add(author["user"]["login"].lower())

    assignees = sorted(
        {
            assignee["login"]
            for issue in pull["closingIssuesReferences"]["nodes"]
            for assignee in issue["assignees"]["nodes"]
        },
        key=str.lower,
    )

    trailers = []
    for login in assignees:
        if login.lower() in credited_logins:
            continue
        co_author, emails = identity(login)
        if emails & credited_emails:
            continue
        trailers.append(f"Co-authored-by: {co_author}")

    issues = ", ".join(f"#{issue['number']}" for issue in pull["closingIssuesReferences"]["nodes"])
    if not trailers:
        print(f"All assignees of the closing issues ({issues or 'none'}) are credited.")
        return 0

    print(f"Adding to the description of #{args.number}, for assignees of {issues}:")
    print("\n".join(trailers))
    new_body = append_trailers(body, trailers)

    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a") as summary:
            summary.write("Added to the pull request description:\n\n```\n")
            summary.write("\n".join(trailers) + "\n```\n")

    if args.dry_run:
        print("\n--- New description ---")
        print(new_body)
        return 0

    gh(
        "api",
        "--method",
        "PATCH",
        f"/repos/{args.repo}/pulls/{args.number}",
        "--input",
        "-",
        stdin=json.dumps({"body": new_body}),
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
