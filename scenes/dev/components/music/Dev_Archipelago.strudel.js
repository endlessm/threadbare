// @title Dev Archipelago
// @by wjt
// Copyright 2026 The Threadbare Authors
// SPDX-License-Identifier: CC-BY-SA-4.0

setcpm(136/4)

var transition = "<[Db^7@2 Db6] Db6 [Db^7@2 Db6] <Db6 [Db ~@7]>>"
var ch1 = "<[Db^7@2 Db6] Db6 [Db^9@2 Db69] [Db69@2 Do7] [Ebm7@2 Ao7@2 Ab7] Ab7 [Ebm7@3 Ao7] <[Ab7 ~@7] [Ab9 Ab7b9]>>"
var ch2 = "<[Ebm9@2 Ao7] [Ab11 Ab7] [Db^9 Db^7] <[Bb9@2 Eo7] [Db@1 ~@7]>>"
var p = "<0 1@2 2@2 3@2>/8"
var ch = p.pick([transition, ch1, ch2, ch2])

$: n(`[1?0.2,2?0.2,3?0.2,4?0.2,5?0.2]*3/2`).struct("x(7,16,2)/2")
  .chord(ch).anchor("Ab4").mode("below").voicing()
  .velocity("1.0 0.8@3".slow(2))
  .clip(1.2).s("gm_acoustic_guitar_nylon")
  .add(note(perlin.range(0,.1)))
  .color("cyan")
  .gain(0.6)
$: ch.rootNotes("<[2@3 1] [1@2 2] 2 [2|1]>").note().struct("<[x@3 x@3 x@2] [x@2 x x@2 x x@2]>")
  .velocity("1.0 0.7@3")
  .add(note(perlin.range(0,.1)))
  .gain(0.7)
  .clip(0.8).s("gm_acoustic_bass").color("magenta")

$: s("cabasa*8").velocity("[1.0 0.5 0.7 0.5]*2").gain(1.2)
$: s("clave:5(7,16,4)/2").gain(1.4)

S$: n(p.early(7/8).pick([
  "~",
  `<
    [~@3 -3 -2 0@2 2@2 0@3 -2@3 0]
    [~@4     2 3 4 2@2 0@3 -2@3 2]
    [1@7        3 -1@3 -3@4     2]
    [1@7       -3  4@8]
  >/2`,
  `<
    [~@2 5@2 3 1@2 -1@9]
    [~@2 4@2 2 0@2 -2@4 -2 5@4]
    [~@2 5@2 3 1@2 -1@4 0@3 1@2]
    [2@8 <~ [~@1 -2 -1 0 1 2 3 4]>@8]
    >/2
  `,
  `<
    [3@2 3@2 5 7@2 6@6     [6 7] 6 5]
    [4@3 4@1 6 8@2 7@4 [7 8] 9 8 7 6]
    [3@2 3@2 5 7@2 6@5       6 7 8 6]
    <[7 ~] [4@8 ~@5 [6 7] 6 5]>
  >/2`,
])
).scale("Db4:major").s("xylophone_medium_ff")
  .gain(0.6)
  .pan(cosine.range(0.25, 0.75).slow(8))

all(x => x.room("0.7:3"))
