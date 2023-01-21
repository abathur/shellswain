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
