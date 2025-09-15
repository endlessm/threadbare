<!--
SPDX-FileCopyrightText: The Threadbare Authors
SPDX-License-Identifier: MPL-2.0
-->
# Contributing to Threadbare

We welcome contributions to Threadbare! This document lays out some of the
requirements for a contribution to be expected. There is a corresponding
document for [reviewing contributions](./REVIEWING.md).

## Language

In-game text and dialogue for the main storyline should be written in English,
for translation into other languages. Text and dialogue in StoryQuests may
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

### Multiple authors

If multiple people have contributed to a single change, special care must be
taken to make sure they each receive credit for their work. If a pull request is
made up of several commits, with different authors, this is sufficient. But if
all commits on a pull request are made by the same person, the other
contributors must be identified with a specially-formatted tag in the commit
message or pull request description, as described in GitHub's
[Creating a commit with multiple authors][co-authored-by] guide. In brief, if
Jane Doe submits a pull request to add a new enemy, with original art created by
Alice Jones, the pull request description should end with:

```
Co-authored-by: Alice Jones <alice.jones@example.com>
```

If you're not sure how to do this, the Threadbare maintainers will be happy to
help.

[co-authored-by]: https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors

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

It is common for collections of free game assets to have licensing terms which
allow the assets to be used in free or commercial games, but do not allow
redistribution of the assets themselves. Unfortunately, assets under such
licenses cannot be used in Threadbare, because including the assets in the
(public) Threadbare Git repository constitutes redistribution. Some examples of
such unsuitable license terms:

- The [Pixabay Content License](https://pixabay.com/service/license-summary/),
  which states:

  > You cannot sell or distribute Content (either in digital or physical form)
  > on a Standalone basis. Standalone means where no creative effort has been
  > applied to the Content and it remains in substantially the same form as it
  > exists on our website.

- The current license for [Tiny
  Swords](https://pixelfrog-assets.itch.io/tiny-swords), which states:

  > You can share these assets as part of tutorials or educational content, as
  > long as you provide a link to Tiny Swords project page. However, you may not
  > redistribute, resell, or repackage the assets, even if the files are
  > modified.

  (The version of Tiny Swords included in `assets/third_party/tiny-swords` in
  this repository is an older version which was published under the
  [CC0-1.0](../LICENSES/CC0-1.0.txt) license.)

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

Assets may not knowingly infringe somebody else's intellectual property. For
example, a hand-drawn illustration of a Star Wars character cannot be accepted
by the project, even if the illustration itself is your own original work. By
contrast, fan art based on an original image where the original image is
licensed under CC-BY-SA-4.0 or another suitable license is allowed by that
license and so is acceptable, provided the copyright owner of the original work
is also cited as a joint owner of the fan art.

## AI-generated assets and code

**We strongly prefer that assets in Threadbare are created by hand, without
using generative AI.**

While AI tools can be useful as part of a creative process, at Endless Access we
aim to teach fundamental creative skills through game-making: animation, visual
design, sound design, game design, etc. We believe that having a solid grounding
in the underlying skills is necessary to create high-quality art, whatever tools
are used by the artist.

Handmade assets are also in keeping with the aesthetic of the Threadbare world
(an environment patched together from fabric, using traditional techniques and
tools) and our use of free and open source tools to create the game.

All this being said, we do accept assets which have been created partly or
wholly by AI, provided that:

1. the AI tool used is cited in a corresponding `.license` file;

2. the AI tool's terms of use allows the asset to be placed under a suitable
   license for this project;

3. the commit message or `.license` file describe who used the AI tool, whether
   the asset is purely AI-generated or whether the creator modified it after
   generation or provided another asset as input to the AI tool, and ideally the
   model (if known) and prompt used.

For example, the current
[main menu logo](../assets/first_party/logo/threadbare-logo.png)
was generated with Midjourney, with no modifications. It is accompanied by a
[`.license` file](../assets/first_party/logo/threadbare-logo.png.license)
which reads:

```
SPDX-FileCopyrightText: The Threadbare Authors
SPDX-License-Identifier: CC-BY-SA-4.0

This image was created using Midjourney by Joana Filizola.
```

The [Midjourney Terms of Service][midjourney-tos] state that:

> You own all Assets You create with the Services to the fullest extent possible
> under applicable law.

so we are able to place the resulting asset under
[CC-BY-SA-4.0](../LICENSES/CC-BY-SA-4.0.txt), the preferred asset license for
this project.

In their article
[*Understanding CC Licenses and Generative AI*][cc-ai],
the Creative Commons team recommends that assets whose creation did not involve
a significant degree of human creativity should be placed under
[CC0-1.0](../LICENSES/CC0-1.0.txt).

[midjourney-tos]: https://docs.midjourney.com/hc/en-us/articles/32083055291277-Terms-of-Service
[cc-ai]: https://creativecommons.org/2023/08/18/understanding-cc-licenses-and-generative-ai/
