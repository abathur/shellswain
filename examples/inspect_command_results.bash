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
