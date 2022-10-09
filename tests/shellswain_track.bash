#!/usr/bin/env bash

# TODO: abstract or dedupe across tests

shopt -s expand_aliases

fern(){
	echo hehe
}

alias alfred=fern

source $SHELLSWAIN

__shellswain_track "$1" _make_sure
ret=$?

eval "_make_sure(){
	echo 'captured call to $1 with args ${@:2}'
}
_test(){
	$@
}
"

_test

exit $ret