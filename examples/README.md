# Examples

## Ringing the bell when a command runs for 60+ seconds
```bash
# notify on completion of a long-running command
source shellswain.bash

__ring_bell_after_long_commands(){
	# 1 minute in microseconds
	[[ ${swain[duration]} -gt 60000000 ]] && echo -e "\a"
}

event on swain:after_command __ring_bell_after_long_commands

```

## Set title after each invocation
```bash
# reset title after each command
source shellswain.bash

_set_terminal_title(){
	printf '\e]1;%s\a' "$*" # set "icon name"
	printf '\e]2;%s\a' "" # unset "window title"
}

event on swain:after_command _set_terminal_title "leave my title alone :("

```

## Defer plugin init to support inter-plugin dependency
```bash
# defer startup work until plugins/libs load
source shellswain.bash

load_plugins(){
	for plugin in "$@"; do
		source "plugins/$plugin" "$@"
	done
}

load_plugins "x" "y" "z"

# -- plugins/x --
__plugin_x_init(){
	if [[ -z "$__plugin_y_loaded" ]]; then
		echo "plugin x depends on plugin y, please install and load it" 1&>2
		exit 1
	fi
	# ...
}

event on swain:before_first_prompt __plugin_x_init

```

## Register cleanup functions as needed
```bash
# register cleanup functions as needed
source shellswain.bash

load_plugins(){
	for plugin in "$@"; do
		source "plugins/$plugin" "$@"
	done
}

load_plugins "mysql" "postgres" "redis"

# -- plugins/mysql --
start_mysql(){
	echo "pretend we're starting mysql"
	event on swain:before_exit stop_mysql
}
stop_mysql(){
	echo "pretend we're stopping mysql"
}

# -- plugins/postgres --
start_postgres(){
	echo "pretend we're starting postgres"
	event on swain:before_exit stop_postgres
}
stop_postgres(){
	echo "pretend we're stopping postgres"
}

# -- plugins/redis --
start_redis(){
	echo "pretend we're starting redis"
	event on swain:before_exit stop_redis
}
stop_redis(){
	echo "pretend we're stopping redis"
}

```

## Associate invocation with build artifact changes

By default (without flags), `nix-build` creates a `result` symlink in
the current directory which points to the resulting build in the nix
store.

We could use before/after phase listeners to keep track of distinct
paths and which invocation created them:

```bash
# register command-specific post-command actions
source shellswain.bash

__get_nix_build_result_before(){
	# check existing symlink and pass target path to the after phase
	swain.phase.curry_args "after" "nix-build" "$(readlink result)"
}

__compare_nix_build_result_after(){
	echo "coompare ${@@Q}"
	local after_result="$(readlink result)"
	if [[ "$1" != "$after_result" ]]; then
		# Note: won't duplicate entries if the callback is identical
		event on "nix-build:list-results" echo "'${swain[command]}' changed result to '$after_result'"
	fi
}

__track_nix_build_results(){
	swain.phase.listen "before" "$1" __get_nix_build_result_before
	swain.phase.listen "after" "$1" __compare_nix_build_result_after
}

nix-builds(){
	event emit "nix-build:list-results"
}

swain.track "nix-build" __track_nix_build_results

```

In use, this would produce something like:
```console
$ nix-build -A shunit2
/nix/store/b597akwy3acq4z09zz2gr437ry57cyar-shunit2-2.1.8

$ nix-builds
'nix-build -A shunit2' changed result to '/nix/store/b597akwy3acq4z09zz2gr437ry57cyar-shunit2-2.1.8'

$ nix-build -A bats
/nix/store/7j5z4yyz7gm3dx599mr22v8bjxb3dndm-bats-1.8.2

$ nix-build -A shunit2
/nix/store/b597akwy3acq4z09zz2gr437ry57cyar-shunit2-2.1.8

$ nix-builds
'nix-build -A shunit2' changed result to '/nix/store/b597akwy3acq4z09zz2gr437ry57cyar-shunit2-2.1.8'
'nix-build -A bats' changed result to '/nix/store/7j5z4yyz7gm3dx599mr22v8bjxb3dndm-bats-1.8.2'
```

