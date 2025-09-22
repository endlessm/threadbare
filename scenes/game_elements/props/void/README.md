This is a CanvasItem material that is intended to be applied to a TileMapLayer
that is using the VoidChromakey terrain (or the constituent tiles). It replaces
the red key color with a procedurally-generated starfield that does not move as
the camera moves, implying that the stars are at a great distance from the
camera. The stars flicker slightly at a low rate.

You must set the TileMapLayer's texture filter to “nearest” to avoid an ugly
fringe where the key color meets the tile border.

<!--
SPDX-FileCopyrightText: The Threadbare Authors
SPDX-License-Identifier: MPL-2.0
-->
