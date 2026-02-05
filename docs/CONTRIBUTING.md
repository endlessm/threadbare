<!--
SPDX-FileCopyrightText: The Threadbare Authors
SPDX-License-Identifier: MPL-2.0
-->
# Contributing to Threadbare

We welcome contributions to Threadbare! This document lays out some of the
requirements for a contribution to be expected. There is a corresponding
document for [reviewing contributions](./REVIEWING.md).

## Licensing

Please see the separate [licensing documentation](./LICENSING.md). This is more
important than _anything else_ in this document. **If your contribution uses
code or assets under an unsuitable license, we cannot accept it**, even if it
meets the other requirements below.

(By constrast, the maintainers can normally fix suitably-licensed contributions
if they don't quite meet the requirements below.)

## Language

In-game text and dialogue for the main storyline should be written in English,
for translation into other languages. Text and dialogue in StoryQuests may
be written in another language if preferred.

Prefer US English spellings for in-game text and dialogue, as well as source
code, comments, and pull request descriptions:

- “Color”, not “colour”
- “Traveler”, not “traveller”

Use “dialogue” when referring to in-game speech (following the `DialogueManager`
API), but “dialog” if referring to a dialog box.

## Coding style

GDScript source code should follow the [GDScript style guide][]. This is
enforced using `gdlint` and `gdformat` from [godot-gdscript-toolkit][] when
changes are submitted to the project.

You can use [pre-commit][] to run the same checks locally. `pre-commit`.
`pre-commit` is written in Python, so if you don't have Python installed, you'll
also need to install Python. The Threadbare team recommends using [`uv`][uv] to
install and manage `pre-commit`, as well as installing Python if needed.

### Install `pre-commit` with `uv`

1. Install `uv` using
   [these instructions](https://docs.astral.sh/uv/#installation)

2. Install `pre-commit`:

   ```
   uv tool install pre-commit
   ```

3. If you need to upgrade `pre-commit` in future, use this command:

   ```
   uv tool upgrade pre-commit
   ```

> [!NOTE]
> If you prefer to install `pre-commit` another way, that's fine!

### Set up `pre-commit` for Threadbare

Run the following command in your Threadbare checkout to set up `pre-commit`:

   ```
   pre-commit install
   ```

Now, coding style checks will be enforced when you run `git commit`.

[GDScript style guide]: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
[godot-gdscript-toolkit]: https://github.com/Scony/godot-gdscript-toolkit
[pre-commit]: https://pre-commit.com/
[uv]: https://docs.astral.sh/uv/

## Pull request descriptions

Pull requests should have:

- A short title describing the intent of the change. The title should be in the
  [imperative mood][] and formatted in sentence case (i.e. with a leading
  capital letter) but no trailing full stop or other punctuation mark. If
  appropriate, prefix the title with the component being modified.

- One or more paragraphs explaining the change in more detail.

- If the pull request resolves an issue, [link the pull request to the
  issue][link-to-issue] with a line like this at the end of the description:

  > Resolves https://github.com/endlessm/threadbare/issues/XYZ

  If the pull request relates to an issue without resolving it, include the
  issue link but not the `Resolves` keyword.

[imperative mood]: https://en.wikipedia.org/wiki/Imperative_mood
[link-to-issue]: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword

Here is an example:

> **Ink combat: Add ink follow player feature**
>
> The ink can now have a Node2D to follow. A constant force in that node
> direction will be set every frame.
>
> The enemy has a boolean export to throw ink that follows the player node
> (the first and only node that should be in the "player" group).
>
> Resolves https://github.com/endlessm/threadbare/issues/71

Your pull request will be squashed into a single commit when it is merged, and
the title and description of the pull request will be used as the commit
message. If you want to make several separate changes, open a separate pull
request for each one. This is subjective, so use your judgement!

These articles and presentations give more background on how and why to craft a
good commit message:

- [How to Write a Git Commit Message](https://cbea.ms/git-commit/) by cbeams
- [Telling Stories Through Your Commits](https://blog.mocoso.co.uk/posts/talks/telling-stories-through-your-commits)
  by Joel Chippindale
- [Git (and how we Commit)](https://groengaard.dev/blog/git-and-how-we-commit)
  Christian Grøngaard

### Multiple authors

If multiple people have contributed to a single change, special care must be
taken to make sure they each receive credit for their work. If a pull request is
made up of several commits, with different authors, this is sufficient. But if
all commits on a pull request are made by the same person, the other
contributors must be identified with a specially-formatted tag in the
pull request description, as described in GitHub's
[Creating a commit with multiple authors][co-authored-by] guide. In brief, if
Jane Doe submits a pull request to add a new enemy, with original art created by
Alice Jones, the pull request description should end with:

```
Co-authored-by: Alice Jones <alice.jones@example.com>
```

If you're not sure how to do this, the Threadbare maintainers will be happy to
help.

[co-authored-by]: https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors
