@tool
extends RefCounted

const CONFIG_PATH = "res://addons/git_describe/platforms.cfg"
const REPOSITORY_PATH = "res://"

static var platform_config: ConfigFile = load_platform_config()


static func execute(command: String) -> Results:
	var platform_name: String = get_platform_name()
	var path: String = platform_config.get_value(platform_name, "path", "")

	var arguments: Array[String] = []
	arguments.assign(
			platform_config.get_value(platform_name, "arguments", "") as Array
	)
	arguments.append(command)

	var output: Array[String] = []
	var exit_code: int = OS.execute(path, arguments, output, true)
	return Results.new(output, exit_code)


static func get_git_describe(options := "") -> String:
	const DEFAULT_GIT_DESCRIBE = ""
	if not is_git_repository_found():
		return DEFAULT_GIT_DESCRIBE

	if not is_git_found():
		return DEFAULT_GIT_DESCRIBE

	var results: Results = execute("git describe " + options)
	if results.exit_code != 0:
		return DEFAULT_GIT_DESCRIBE

	return results.output[0].strip_edges()


static func get_platform_name() -> String:
	if is_in_steam_runtime():
		return "Steam Linux Runtime"

	return OS.get_name()


static func is_git_found() -> bool:
	var which: String = platform_config.get_value(
			get_platform_name(), "which", ""
	)
	var results: Results = execute(" ".join([which, "git"]))
	return results.exit_code == 0 and not results.output[0].is_empty()


static func is_git_repository_found() -> bool:
	return DirAccess.dir_exists_absolute(REPOSITORY_PATH.path_join(".git"))


# gdlint:ignore = max-line-length
# https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/blob/main/docs/slr-for-game-developers.md#detecting-the-container-environment
static func is_in_steam_runtime() -> bool:
	if OS.get_name() != "Linux":
		return false

	const CAT_COMMAND = "cat"
	var output: Array[String] = []
	OS.execute(CAT_COMMAND, ["/etc/os-release"], output)
	OS.execute(CAT_COMMAND, ["/run/host/container-manager"], output)
	return "steamrt" in output[0] or "pressure-vessel" in output[1]


static func is_platform_configured() -> bool:
	return get_platform_name() in platform_config.get_sections()


static func load_platform_config() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	return config


static func push_status() -> void:
	const PRINT_ID = "Godot Git Describe: "
	if not is_platform_configured():
		push_error(
				PRINT_ID,
				"\"%s\" configuration not found in \"%s\"." % [
					get_platform_name(),
					CONFIG_PATH
				]
		)

	elif not is_git_repository_found():
		push_error(
				PRINT_ID,
				"Git repository not found in \"%s\"."
				% ProjectSettings.globalize_path(REPOSITORY_PATH)
		)

	elif not is_git_found():
		push_error(PRINT_ID, "Git not found.")
		return

	var results: Results = execute("git status")
	if results.exit_code != 0:
		push_error(PRINT_ID, "\n", "".join(results.output))


class Results:
	var output: Array[String]
	var exit_code: int

	@warning_ignore("shadowed_variable")
	func _init(output: Array[String] = [], exit_code := 0) -> void:
		self.output = output
		self.exit_code = exit_code
