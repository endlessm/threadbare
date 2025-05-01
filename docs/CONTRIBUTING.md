<!--
SPDX-FileCopyrightText: The Threadbare Authors
SPDX-License-Identifier: MPL-2.0
-->
# Contributing to Threadbare

We welcome contributions to Threadbare!

## Language

In-game text and dialogue for the main storyline should be written in English,
for translation into other languages. Learner-contributed text and dialogue may
be written in another language if preferred.

Prefer US English spellings for in-game text and dialogue, as well as source
code, comments, and commit messages:

- “Color”, not “colour”
- “Traveler”, not “traveller”

Use “dialogue” when referring to in-game speech (following the `DialogueManager`
API), but “dialog” if referring to a dialog box.

## Coding style

GDScript source code should follow the [GDScript style guide][]. This is
enforced using `gdlint` and `gdformat` from [godot-gdscript-toolkit][] when
changes are submitted to the project.

You can use [pre-commit][] to run the same checks locally. Install `pre-commit`
then run the following command in your Threadbare checkout:

```
pre-commit install
```

Now, coding style checks will be enforced when you run `git commit`.

[GDScript style guide]: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
[godot-gdscript-toolkit]: https://github.com/Scony/godot-gdscript-toolkit
[pre-commit]: https://pre-commit.com/

## Git commit messages and pull request descriptions

Commit messages should have:

- A short title describing the intent of the change. The title should be in the
  [imperative mood][] and formatted in sentence case (i.e. with a leading
  capital letter) but no trailing full stop or other punctuation mark. If
  appropriate, prefix the title with the component being modified.
- One or more paragraphs explaining the change in more detail.
- If the commit resolves an issue, include a link to the issue on a line by
  itself at the end of the message, in the form `Fixes
  https://github.com/endlessm/threadbare/issues/XYZ`. If the commit
  relates to an issue, include the issue link but not the `Fixes` tag.

[imperative mood]: https://en.wikipedia.org/wiki/Imperative_mood

Here is an example:

```
Ink combat: Add ink follow player feature

The ink can now have a Node2D to follow. A constant force in that node
direction will be set every frame.

The enemy has a boolean export to throw ink that follows the player node
(the first and only node that should be in the "player" group).

Fixes https://github.com/endlessm/threadbare/issues/71
```

If you open a pull request from a branch that contains only a single new commit,
the commit message will be used as the pull request title & description. If
your branch has 2 or more commits, the pull request title & description should
follow the same style guidelines above.

Pull requests should contain one commit per self-contained, logical change.
This is subjective so use your judgement!

If you are not a Git expert, you may prefer to submit pull requests without a
clean commit history. In this case, the maintainers will squash your changes
into a single commit when the pull request is merged. The title and description
of your pull request should still follow the guidelines above in this case. The
Threadbare maintainers will be happy to help if you're not sure how to do this.

These articles and presentations give more background on how and why to craft a
good commit message:

- [How to Write a Git Commit Message](https://cbea.ms/git-commit/) by cbeams
- [Telling Stories Through Your Commits](https://blog.mocoso.co.uk/posts/talks/telling-stories-through-your-commits)
  by Joel Chippindale
- [Git (and how we Commit)](https://groengaard.dev/blog/git-and-how-we-commit)
  Christian Grøngaard

## Licensing

Original source code (including GDScript source files, Godot scene files, and
`.dialogue` files) should use the [MPL 2.0](../LICENSES/MPL-2.0.txt) license.
Original artwork and other assets should use the [Creative Commons
Attribution-ShareAlike 4.0 International](../LICENSES/CC-BY-SA-4.0.txt) license.

Third-party code covered by licenses other than MPL 2.0 may be used if its
license allows it to be combined with MPL-licensed code and with proprietary
code (such as Godot engine ports to games consoles). For example, the
[MIT](../LICENSES/MIT.txt) license is okay, while the GNU GPL is not.

Similarly, third-party assets covered by licenses other than CC-BY-SA-4.0 may be
used if their license allows redistribution, potentially commercially. For
example, [CC0 1.0 Universal](../LICENSES/CC0-1.0) is okay, while
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0
International](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.en) is
not.

Source code and assets added to the project should have their copyright owner
and license described in machine-readable form following the
[REUSE](https://reuse.software/) specification. For source code, include a
comment like the following at the start of your source file:

```GDScript
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
```

For file formats that do not allow comments, you can add a `.license` file
adjacent to the file, or provide this information in
[REUSE.toml](../REUSE.toml). Use existing files in the repository as a
reference. If you're not sure how to do this, the Threadbare maintainers will be
happy to help.

For significant contributions, add yourself (or the copyright owner of your
work, if not you) to the [AUTHORS](../AUTHORS) file.
