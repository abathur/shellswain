#!/usr/bin/env bash

fern(){
	echo hehe
}

alias alfred=fern

source shellswain.bash

swain.track "$1" _make_sure
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
