#! /usr/bin/env make
prefix ?= /usr/local
bindir ?= ${prefix}/bin

.PHONY: install uninstall check
install:
	mkdir -p ${DESTDIR}${bindir}
	install shellswain.bash ${DESTDIR}${bindir}

uninstall:
	rm -f ${DESTDIR}${bindir}/shellswain.bash

# excluding SC1091 (finding a sourced file) for now because it requires bashup.events to be on the path
check:
	shellcheck -x -e SC1091 ./shellswain.bash
