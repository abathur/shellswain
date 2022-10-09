#!/usr/bin/env bash

# TODO: abstract/dedupe across tests, or maybe just collapse all of this base API stuff into a single integration test

shopt -s expand_aliases

fern(){
	echo hehe
}

alias alfred=fern

source $SHELLSWAIN

on_init(){
	echo on_init
}

__shellswain_command_init_hook "$1" on_init
__shellswain_track "$1" :
ret=$?

eval "
_test(){
	$@
}
"

_test

exit $ret
