# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Object
## Functions to determine the game version

const FULL_VERSION_KEY := &"application/config/full_version"
const VERSION_KEY := &"application/config/version"

static var _initialized := false
static var _full_version: String
static var _version: String


## Gets the project version based on [code]git describe[/code],
## or [code]"v0.0.0"[/code] if this fails.
static func git_describe(warn_on_error: bool) -> String:
	var output: Array[String] = []
	var ret := OS.execute("git", ["describe", "--tags"], output)
	if ret != 0:
		if warn_on_error:
			printerr("git describe --tags failed: %d" % ret)
		return "v0.0.0"

	var version := output[0].strip_edges()
	return version


static func simplify(full_version: String) -> String:
	var regex := RegEx.new()
	regex.compile("^v(?<base>\\d+(?:\\.\\d+)+)(?:-(?<count>\\d+).*)?$")
	var result := regex.search(full_version)
	if not result:
		return "0.0.0"
	return ".".join(result.strings.slice(1))


## Gets the full `git describe`-style version
static func get_full_version() -> String:
	if not _full_version:
		_full_version = ProjectSettings.get_setting(FULL_VERSION_KEY, "")

	if not _full_version:
		_full_version = git_describe(false)

	return _full_version


## Gets the game version in a Windows .exe-friendly x.y.z.w format
static func get_version() -> String:
	if not _version:
		_version = ProjectSettings.get_setting(VERSION_KEY, "")

	if not _version:
		_version = simplify(get_full_version())

	return _version
