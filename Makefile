# Makefile for HM plug-in
# Used to make distribution package
#
PHP=php
DISTDIR=./dist
VERSION=

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

sync-page:
	git co gh-pages
	git co master -- LICENSE.txt
	$(PHP) update_version.php
	$(PHP) update_sync_file.php
	git ci -a -m "Update gh-pages to "`cat VERSION`
	git push
	git co master

sync:
	git push --tags
	$(PHP) dev/upload_github.php
	$(MAKE) sync-page

lang/zhtw.lua: lang/zhcn.lua
	big2gb -r < lang/zhcn.lua | sed 's#zhcn#zhtw#' > tmp.lang
	$(PHP) -r 'echo mb_convert_encoding(file_get_contents("tmp.lang"), "utf8", "big5");' > lang/zhtw.lua
	rm -f tmp.lang

archive: lang/zhtw.lua
	git ci -a -m "Release "`cat VERSION`
	git tag `cat VERSION`
	git archive --format zip --prefix HM/ -o dist/HM-`cat VERSION`.zip HEAD

beta: clean-check
	$(PHP) dev/pre_release.php beta
	$(MAKE) archive
	$(MAKE) sync

stable: master-check clean-check
	$(PHP) dev/pre_release.php stable $(VERSION)
	$(MAKE) archive
	$(MAKE) sync
