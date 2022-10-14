# hack curry functionality atop bashup.events
# TODO: if you make a modular build process to separate the core/plugin parts, consider also extracting this bit?
# TODO: this feels a little imeplemntation-leaky...
declare -gA _ev_curried
__ev.curry() {
	if ! [[ -v "_ev_curried[$1]" ]] ; then # no key == first time setup
		# inject our var; clear it (unset is slower); original string
		bashup_ev[$1]="set -- \"$1\" \${_ev_curried[$1]} \"\${@:2}\"; _ev_curried[$1]=''; ${bashup_ev[$1]}"
	fi

	# add args to our var
	# shellcheck disable=SC2124
	_ev_curried[$1]+="${@:2} "
}
