// @title Song Sanctuary theme
// @by Will Thompson
// Copyright The Threadbare Authors
// SPDX-License-Identifier: CC-BY-SA-4.0
setcpm(80 / 8);

$: stack(
  s("shaker_small:8").struct("[~ x]*4"),
  s("timpani:9").struct("x*2").mask("<~ x>/8"),
  s("bongo:2").struct("[~ [x x?]]*8").mask("<~ x>/8"),
  s("fingercymbal").struct("<x!4 x ~ ~ ~>/2"),
).room(".8:6");

var bar = "<0!2 1!2 2!2 3!2 0 1 2 3 4!4>";

$: n(
  bar.pick([
    "0@3 4 0@2 0@2",
    "1@3 5 1@2 1@2",
    "1@3 1 -3@2 4@2",
    "0@3 4 <0 7>@3 4",
    "0@3 4 <0 7>@3 4",
  ]),
)
  .orbit(3)
  .gain(1.3)
  .room(".8:4")
  .scale("Ab1:major")
  .sound("gm_acoustic_bass:1");

$: n(
  bar.pick([
    "[0  9 4 7]*4",
    "[1 10 5 8]*4",
    "[[1 10 5 7]*2 [1 10 4 6]*2]",
    "[0  9 4 7]*4",
    "[0  9 4 [6|7|7|8]]*4",
  ]),
)
  .scale("<Ab2:major>")
  .add(note(perlin.range(0, 0.1)))
  .clip(3)
  .sound("gm_acoustic_guitar_nylon:7")
  .gain(0.5)
  .pan("<.25!16 0.5!2>")
  .orbit(2)
  .room(".8:6")
  .mask("<~ 1>/8")
  .gain(0.6);

$: n(
  bar.pick([
    "[0 2@2 1] 2 ~@2",
    "[1 3@2 2] 3 ~@2",
    "[3@2 2 3] 1 ~@2",
    "[2@2 1 2] 0 ~@2",
    "[2@2 1 2] 0 ~@2",
  ]),
)
  .scale("Ab3:major")
  .add(note(perlin.range(0, 0.1)))
  .sound("kalimba:9,folkharp:3")
  .gain(0.3)
  .pan(0.75)
  .orbit(4)
  .room(".8:4")
  .mask("<~ ~ x ~>/4");
