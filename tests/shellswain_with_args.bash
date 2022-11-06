#!/usr/bin/env bash --norc --noprofile -i

# TODO: abstract/dedupe across tests, or maybe just collapse all of this base API stuff into a single integration test

export PS1='PROMPT>'

fern(){
	echo hehe
}

alias alfred=fern

source shellswain.bash

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

swain.hook.init_command "$1" on_init
swain.phase.listen "before" "$1" before args
swain.phase.listen "after" "$1" after args
# DOING: below is tentative to nail down current behavior, but not how we actually want this to work.
weirdargbro=eardwargbro
swain.phase.curry_args "after" "$1" weirdargbro
swain.track "$1" :
ret=$?

eval "
_test(){
	history -s $@
	eval \"\${PS0@P}\"
	$@
	eval \"\${PROMPT_COMMAND[1]}\"
	echo \"\${PS1@P}\"
}
"

# simulate first prompt
# eval "${PS0@P}"
eval "${PROMPT_COMMAND[1]}"
echo "${PS1@P}"

# set -x
_test
# set +x

echo executed:${swain[command]}

exit $ret
