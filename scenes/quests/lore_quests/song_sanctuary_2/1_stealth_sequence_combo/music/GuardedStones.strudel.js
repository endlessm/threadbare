// @title Guarded Stones
// @by Will Thompson
// Copyright The Threadbare Authors
// SPDX-License-Identifier: CC-BY-SA-4.0

setcpm(70/4)

$: stack(
  s("shaker_small:8").struct("x*16").velocity("[1 0.3 0.7 0.5]*4"),
  s("clave:2").struct(`<
    [~ x ~ [x x@3]]
    [~ x [~ x? ~ x] x]
  >`),
  s("bongo:3").struct("x*4"),
  s("fingercymbal").struct("x"),

  s("sus_cymbal").struct("<~@8 ~@7 x ~@3 x ~@3 x>"),
  s("clap:4").gain(0.2).struct("<x(5,16,2)!3 x(7,16,9)>").mask("<~ ~ x>/8".early(1/4)),
  s("clash2").struct("<x ~@3>").mask("<~ ~ x>/8").gain(0.3),
  s("crow").struct("<~@4 x ~@3>").mask("<~ ~ x>/8").gain(0.2).echo(10, 1/12, .6).pan(rand),
).room(".8:6")
  .color("green")
  ._pianoroll()

$: n(
    "<~@8 0@2 1@2 2@4 3@8>"
    .pick([
      `4 0@3`.color("red"),
      `~ 2 3@6`.color("green"),
      `<-2 1> -3@2 -3`.color("purple"),

      slowcat(
        `0@3 0@2 6 [7 | [7 9]]@2`,
        `10 3@4 10 11@2`,
        `[-2|2]@6 ~ -2`,
        `-3@2 -3 -1`,
      ).late(1/4).color("blue")
    ])
  )
  .early(1/4)
  .decay("1.2")
  .orbit(3)
  .gain(1.3)
  .room(".8:4")
  .scale("<A1:harmonic:minor>")
  .sound("gm_acoustic_bass:1")
  // .color("red")
._pianoroll()


$: n(
    "<~@8 0 ~ 1 ~ 3 ~ 3 3 0 1 2 3 0 1 2 3>"
    .pick([
      "~ 0 2 ~@5",
      "2 4 0 ~@5",
      "2 4 0 ~@5",
      "4 2 6 ~@5",
    ])
  )
  .mask(time.gte(8))
  .early(2/8)
  .scale("<A3:harmonic:minor>")
  .add(note(perlin.range(0,.1)))
  .clip(5)
  .sound("gm_acoustic_guitar_nylon:7")
  .orbit(2)
  .room(".8:6")
  .gain(.6)
  ._pianoroll()

$: n(
  "<0 1 2 3>"
  .pick([
    choose(0,2,4,7),
    choose(2,4,7,9),
    choose(4,7,9,11),
    choose(4,6,8,10),
  ]).early(2/8)
  // irand(7).sub("<0 4 2 3>".early(2/8))
  .struct("[x?]*16")
)
  .mask("<~ ~ x>/8")
  .scale("A4:harmonic:minor")
  .add(note(perlin.range(0,.1)))
  .sound("kalimba:9,folkharp:3")
  .gain(.2)
  .orbit(4)
  .room(".8:4")
  ._pianoroll()
