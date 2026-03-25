# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Object
## Functions to determine the game version

static var _initialized := false
static var _version: String


## Gets the project version based on [code]git describe[/code],
## or [code]""[/code] if this fails.
static func git_describe(warn_on_error: bool) -> String:
	var output: Array[String] = []
	var ret := OS.execute("git", ["describe", "--tags"], output)
	if ret != 0:
		if warn_on_error:
			printerr("git describe --tags failed: %d" % ret)
		return ""

	var version := output[0].strip_edges()
	return version


## Gets the game version from the project configuration, falling back to
## calling [member git_describe].
static func get_version() -> String:
	if not _initialized:
		_version = ProjectSettings.get(&"application/config/version")

		if not _version:
			_version = git_describe(false)

		_initialized = true

	return _version
