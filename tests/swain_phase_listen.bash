#!/usr/bin/env bash

# TODO: abstract/dedupe across tests, or maybe just collapse all of this base API stuff into a single integration test

fern(){
	echo hehe
}

alias alfred=fern

source shellswain.bash

before(){
	echo before $@
}

run(){
	echo run $@
}

after(){
	echo after $@
}

swain.phase.listen "before" "$1" before args
swain.phase.listen "run" "$1" run args
swain.phase.listen "after" "$1" after args
swain.track "$1" :
ret=$?

eval "
_test(){
	$@
}
"

_test

exit $ret
