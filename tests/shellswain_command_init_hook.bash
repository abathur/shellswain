#!/usr/bin/env bash

# TODO: abstract/dedupe across tests, or maybe just collapse all of this base API stuff into a single integration test

fern(){
	echo hehe
}

alias alfred=fern

source shellswain.bash

on_init(){
	echo on_init
}

swain.hook.init_command "$1" on_init
swain.track "$1" :
ret=$?

eval "
_test(){
	$@
}
"

_test

exit $ret
