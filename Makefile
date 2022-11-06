#! /usr/bin/env make
prefix ?= /usr/local
bindir ?= ${prefix}/bin

.PHONY: install uninstall check

build:
	# caution: below is meant to be run out of tree in nix
	cat bashup.events.curry.bash >> shellswain.bash

install:
	mkdir -p ${DESTDIR}${bindir}
	install shellswain.bash ${DESTDIR}${bindir}

uninstall:
	rm -f ${DESTDIR}${bindir}/shellswain.bash

# excluding SC1091 (finding a sourced file) for now because it requires bashup.events to be on the path
check:
	shellcheck -x -e SC1091 ./shellswain.bash
	bats --timing tests
