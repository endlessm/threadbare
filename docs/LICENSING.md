<!--
SPDX-FileCopyrightText: The Threadbare Authors
SPDX-License-Identifier: MPL-2.0
-->
# Threadbare Licensing

All assets and code in Threadbare must be released under licenses that allow us
to distribute the game, both as an open-source project here on GitHub, and to
players on the web, PC, mobile devices and potentially consoles in future.

When we use third-party assets and code, we need to be sure we know what license
they are covered by, so that we can be sure we have the legal right to
distribute them; so that we appropriately credit their authors in the game; and
so that other games that want to reuse our assets in turn know their legal
rights and obligations.

Copyright licenses are a complicated topic! Please ask us if you're not sure
whether you can use an asset in Threadbare: we are always happy to help. It is
better to check sooner, rather than waiting until you have built a level or
quest using the asset and then discovering we cannot accept it.

## Asset Licensing

Original artwork and other non-code assets should use the [Creative Commons
Attribution-ShareAlike 4.0 International][CC-BY-SA-4.0] license.

Third-party assets covered by licenses other than CC-BY-SA-4.0 may be
used if their license allows redistribution, potentially commercially.
We prefer standard, widely-used licenses Creative Commons licenses because their
meanings are well-understood and their text has been rigorously reviewed by
legal experts. Note that not all Creative Commons licenses are usable in
Threadbare: see below for examples.

It is common for collections of free game assets to have custom licensing terms
which allow the assets to be used in free or commercial games, but do not allow
redistribution of the assets themselves. Unfortunately, assets under such
licenses cannot be used in Threadbare, because including the assets in the
(public) Threadbare Git repository constitutes redistribution. Some examples of
such licenses are given below.

### Acceptable asset licenses

* [CC0 1.0 Universal][CC0-1.0] is suitable: it permits commercial
  use, modification, and allows redistribution.
* [Creative Commons Attribution 4.0 International][CC-BY-4.0] is suitable: we
  will credit the copyright owners in our Credits.
  - For example, [Incompetech's Royalty-Free Music][Incompetech] page contains
    hundreds of pieces of music, published under this license. These can be
    used in Threadbare.

[CC0-1.0]: ../LICENSES/CC0-1.0
[CC-BY-4.0]: https://creativecommons.org/licenses/by/4.0/deed.en
[CC-BY-SA-4.0]: ../LICENSES/CC-BY-SA-4.0.txt
[Incompetech]: https://incompetech.com/music/royalty-free/music.html

### Unsuitable asset licenses

Assets under the following licenses cannot be used in Threadbare:

* [Creative Commons Attribution-NonCommercial-ShareAlike 4.0
  International][CC-BY-NC-SA-4.0] cannot be used in Threadbare because it does
  not allow commercial use. We would like to keep open the option of making a
  paid version of Threadbare available.

* The [Pixabay Content License][], which states:

  > You cannot sell or distribute Content (either in digital or physical form)
  > on a Standalone basis. Standalone means where no creative effort has been
  > applied to the Content and it remains in substantially the same form as it
  > exists on our website.

  However, section 4 of the [Pixabay Terms of Service][] says:

  > Some of the Content made available for download on the Service is subject to
  > and licensed under the Creative Commons Zero (CC0) license ("CC0 Content").
  > CC0 Content on the Service is any content which lists a "Published date"
  > prior to January 9, 2019.

  Such content **can** be used in Threadbare.

* The current license for [Tiny Swords][], which states (emphasis ours):

  > You can share these assets as part of tutorials or educational content, as
  > long as you provide a link to Tiny Swords project page. However, **you may
  > not redistribute**, resell, or repackage the assets, even if the files are
  > modified.

  This is an unusual case because an earlier version of Tiny Swords was
  published under the [CC0-1.0][] license. This older version of Tiny Swords is
  included in the game, in the `assets/third_party/tiny-swords` folder.

[Pixabay Content License]: https://pixabay.com/service/license-summary/
[Pixabay Terms of Service]: https://pixabay.com/service/terms/
[CC-BY-NC-SA-4.0]: https://creativecommons.org/licenses/by-nc-sa/4.0/deed.en
[Tiny Swords]: https://pixelfrog-assets.itch.io/tiny-swords

## Code Licensing

Original source code (including GDScript source files, Godot scene files, and
`.dialogue` files) should use the [MPL 2.0](../LICENSES/MPL-2.0.txt) license.

Third-party code covered by licenses other than MPL 2.0 may be used if its
license allows it to be combined with MPL-licensed code and with proprietary
code (such as Godot engine ports to games consoles). For example, the
[MIT](../LICENSES/MIT.txt) license is okay, while the GNU GPL is not.

## License Annotations

Source code and assets added to the project should have their copyright owner
and license described in machine-readable form following the
[REUSE](https://reuse.software/) specification. For source code, include a
comment like the following at the start of your source file:

```GDScript
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
```

For images, sounds, and other file formats that do not allow comments, you can
add a `.license` file adjacent to the file, or provide this information in
[REUSE.toml](../REUSE.toml). Use existing files in the repository as a
reference. If you're not sure how to do this, the Threadbare maintainers will be
happy to help.

For significant contributions, add yourself (or the copyright owner of your
work, if not you) to the [AUTHORS](../AUTHORS) file.

## No IP infringement

Assets may not knowingly infringe somebody else's intellectual property. For
example, a hand-drawn illustration of a Star Wars character cannot be accepted
by the project, even if the illustration itself is your own original work. By
contrast, fan art based on an original image where the original image is
licensed under [CC-BY-SA-4.0][] or another suitable license is allowed by that
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

For example, the previous main menu logo at `assets/first_party/logo/threadbare-logo.png`
was generated with Midjourney, with no modifications. It was accompanied by a
`threadbare-logo.png.license` file in the same folder which said:

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
