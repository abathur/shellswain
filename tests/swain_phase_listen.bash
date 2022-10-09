#!/usr/bin/env bash

# TODO: abstract/dedupe across tests, or maybe just collapse all of this base API stuff into a single integration test

shopt -s expand_aliases

fern(){
	echo hehe
}

alias alfred=fern

source $SHELLSWAIN

before(){
	echo before $@
}

run(){
	echo run $@
}

after(){
	echo after $@
}

__swain_phase_listen "before" "$1" before args
__swain_phase_listen "run" "$1" run args
__swain_phase_listen "after" "$1" after args
__shellswain_track "$1" :
ret=$?

eval "
_test(){
	$@
}
"

_test

exit $ret
