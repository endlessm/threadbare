<!--
SPDX-FileCopyrightText: The Threadbare Authors
SPDX-License-Identifier: MPL-2.0
-->
# Reviewing contributions

[We welcome contributions to Threadbare!](./CONTRIBUTING.md)
This document sets out the process of reviewing a contribution.

## Anyone can review a pull request

Although the Threadbare maintainers at Endless Access need to approve a change
for it to be merged to the game, **anybody can review pull requests**. Reviewing
other people's work helps everybody:

- For the person who submitted the pull request, your feedback can help them to
  improve their proposed change while waiting for review from the maintainers.

- For the reviewer, it is an excellent way to learn more about how the game is
  structured. Review is a contribution of its own, and can help you to find
  other ways to contribute, too.

- For the Threadbare maintainers, community reviews of pull requests helps us to
  focus on areas where our attention and assistance is particularly needed. We
  are just two developers, and there are only so many hours in the day, so
  community review is much appreciated!

## Playtesting

Play the game, focusing on the scenes related to the proposed change:

- Does the game build and run correctly?

- If it is a new quest, is the quest playable?

- Has the proposed change introduced bugs elsewhere in the game? (For example, a
  change to a shared component may fix a bug in one level, but introduce a
  problem in another.)

In general, a contribution should broadly improve or add to the game.
It's fine for a contribution to need further work in future; for example, a
StoryQuest may have only one challenge implemented, or a larger change to the
game's base resolution may need further testing and follow-up changes. Use your
judgement.

## Style, legal, and attribution

Pull requests should follow the guidelines laid out in the [contribution
guidelines](./CONTRIBUTING.md). In brief:

- In-game text and dialogue should be written in US English, with the exception
  of StoryQuests.

- The coding style checks, licensing checks, and automated web build should
  succeed.

- The provenance of all third-party assets and code must be identified, and
  their license checked to ensure we have the legal right to distribute them in
  the game.

- The pull request title and description must be clearly written, identifying
  any issues it will fix.

- Any co-authors are identified, following [Creating a commit with multiple
  authors][co-authored-by], if they did not author any of the commits in the
  pull request.

[co-authored-by]: https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors

## Fixing issues on behalf of the submitter

Threadbare contributors often have little to no previous experience of
contributing to an open-source project using Git. We are delighted to receive
these contributions!

Unlike in some open-source projects, where the submitter is expected to make all
requested changes themself, the Threadbare maintainers may choose to fix issues
directly, on behalf of the submitter. We do this to reduce the number of times
that a pull request must be bounced between submitter and reviewer; and because
it is sometimes more efficient to make a change than to describe it.

For example, if the pull request is ready to merge except for its title and
description not matching our style, the maintainer may rewrite the title and
description, then merge the pull request; if we notice a typo, the maintainer
may fix it themself, then merge the pull request. We will always explain in
the pull request why we have made such changes, to help the submitter to make an
even better contribution next time.

If there are several changes to make, or larger changes, the reviewer will
normally ask the submitter to make these changes themself. As each contributor
gains experience with the project and its workflow, we will tend to ask them to
address more feedback themself.

## Merge strategy

If the pull request is formatted as a series of 1 or more cleanly-separated
commits with well-structured commit messages, prefer to create a merge commit.

Otherwise, ensure that the pull request title and description matches our style
guide, and that all contributors are identified either as commit authors or with
`Co-authored-by` tags, then use the **Squash and merge** strategy, which uses
the pull request's title and description as the squashed commit message.
