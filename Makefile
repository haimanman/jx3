# Makefile for HM plug-in
# Used to make distribution package
#
PHP=php
DISTDIR=./dist

all:
	@echo "------------------------------------------"
	@echo "HM plug-in release manager"
	@echo "------------------------------------------"
	@echo "make beta    : create a beta release"
	@echo "make stable  : create a stable release"
	@echo "------------------------------------------"
	@echo "Homepage     : http://haimanchajian.com"

master-check:
	git status | grep "On branch master" > /dev/null 2>&1

clean-check:
	git status | grep "working directory clean" > /dev/null 2>&1

sync:
	git push --tags
	$(PHP) dev/upload_github.php

archive:
	git ci -a -m "Release "`cat VERSION`
	git tag `cat VERSION`
	git archive --format zip --prefix HM/ -o dist/HM-`cat VERSION`.zip HEAD

beta: clean-check
	$(PHP) dev/pre_release.php beta
	$(MAKE) archive
	$(MAKE) sync

stable: master-check clean-check 
	$(PHP) dev/pre_release.php stable
	$(MAKE) archive
	$(MAKE) sync
