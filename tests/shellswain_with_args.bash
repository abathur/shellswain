#!/usr/bin/env bash --norc --noprofile -i

# TODO: abstract/dedupe across tests, or maybe just collapse all of this base API stuff into a single integration test

shopt -s expand_aliases

export PS1='PROMPT>'

fern(){
	echo hehe
}

alias alfred=fern

source $SHELLSWAIN

on_init(){
	echo on_init
}

before(){
	echo before $@
}

run(){
	echo run $@
}

after(){
	echo after $@
}

__shellswain_command_init_hook "$1" on_init
__swain_phase_listen "before" "$1" before args
__swain_phase_listen "after" "$1" after args
# DOING: below is tentative to nail down current behavior, but not how we actually want this to work.
weirdargbro=eardwargbro
__swain_curry_phase_args "after" "$1" weirdargbro
__shellswain_track "$1" :
ret=$?

eval "
_test(){
	eval \"\$PROMPT_COMMAND\"
	history -s $@
	eval \"\${PS0@P}\"
	$@
	echo \"\${PS1@P}\"
}
"

# simulate first prompt
eval "$PROMPT_COMMAND"
eval "${PS0@P}"
echo "${PS1@P}"

_test

echo executed:${shellswain[command]}

exit $ret
