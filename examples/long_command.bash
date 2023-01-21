# notify on completion of a long-running command
source shellswain.bash

__ring_bell_after_long_commands(){
	# 1 minute in microseconds
	[[ ${swain[duration]} -gt 60000000 ]] && echo -e "\a"
}

event on swain:after_command __ring_bell_after_long_commands
