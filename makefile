# Copyright (C) 2019 Jan Slany
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, see
# <https://www.gnu.org/licenses/>.

VERSION := 0.0.1
NAME := singon-ext

DIST_NAME   := ${NAME}-${VERSION}.tar.gz
DIST_TMPDIR := build/pkg/${NAME}

SOURCES := $(shell find src -type f)
FILES_OCTAVE := $(patsubst src/octave/%,${DIST_TMPDIR}/inst/%,$(shell find src/octave -type f))
FILES_META   := $(patsubst src/meta/%,${DIST_TMPDIR}/%,$(shell find src/meta -type f)) ${DIST_TMPDIR}/COPYING

.PHONY: dist clean uninstall

dist: build/${DIST_NAME}

build/${DIST_NAME}: ${FILES_OCTAVE} ${FILES_META}
	@echo "Packaging for distribution..."
	cd build && tar -C pkg -zcf ${DIST_NAME} .

${FILES_OCTAVE}: ${DIST_TMPDIR}/inst/%: src/octave/%
	@mkdir -p $(dir $@)
	cp $< $@

$(filter-out %/DESCRIPTION %/COPYING,${FILES_META}): ${DIST_TMPDIR}/%: src/meta/%
	@mkdir -p $(dir $@)
	cp $< $@

${DIST_TMPDIR}/DESCRIPTION: src/meta/DESCRIPTION
	@mkdir -p $(dir $@)
	cp $< $@
	sed -i "s/VAR_VERSION/${VERSION}/" ${DIST_TMPDIR}/DESCRIPTION

${DIST_TMPDIR}/COPYING: COPYING
	@mkdir -p $(dir $@)
	cp $< $@

clean:
	rm -rf build/

install: build/${DIST_NAME}
	@echo "Installing Octave package locally..."
	cd build && octave-cli --silent --eval 'pkg install "${DIST_NAME}"'

uninstall:
	@echo "Uninstalling local Octave package..."
	octave-cli --silent --eval 'pkg uninstall ${NAME}'

