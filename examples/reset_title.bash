# reset title after each command
source shellswain.bash

_set_terminal_title(){
	printf '\e]1;%s\a' "$*" # set "icon name"
	printf '\e]2;%s\a' "" # unset "window title"
}

event on swain:after_command _set_terminal_title "leave my title alone :("
