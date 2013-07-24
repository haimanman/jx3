# Makefile for HM plug-in
# Used to make distribution package
#
PHP=php
DISTDIR=./dist
VERSION=
JX3_HM_DIR=./public_html/jx3

all:
	@echo "------------------------------------------"
	@echo "HM plug-in release manager"
	@echo "------------------------------------------"
	@echo "make beta    : create a beta release"
	@echo "make stable  : create a stable release"
	@echo "make alpha   : create a local alpha release"
	@echo "make hotfix  : just update the current package"
	@echo "------------------------------------------"
	@echo "Homepage     : http://haimanchajian.com"

master-check:
	git status | grep "On branch master" > /dev/null 2>&1

clean-check:
	git status | grep "working directory clean" > /dev/null 2>&1

sync-page:
	git co gh-pages
	git co master -- LICENSE.txt MACRO.txt
	$(PHP) update_version.php
	$(PHP) update_sync_file.php
	git ci -a -m "Update gh-pages to "`cat VERSION`
	git push -f
	scp sync.xml release.dat changelog.html jx3.hm:$(JX3_HM_DIR)/sync
	scp dist/HM-`cat VERSION`.zip jx3.hm:$(JX3_HM_DIR)/down
	ssh jx3.hm rm -rf -d $(JX3_HM_DIR)/sync/HM
	ssh jx3.hm unzip -qq -o -d $(JX3_HM_DIR)/sync $(JX3_HM_DIR)/down/HM-`cat VERSION`.zip
	git co master

sync:
	git push --tags
#	$(PHP) dev/upload_github.php
	$(MAKE) sync-page

lang/zhtw.lua: lang/zhcn.lua
	big2gb -r < lang/zhcn.lua | sed 's#zhcn#zhtw#' > tmp.lang
	$(PHP) -r 'echo mb_convert_encoding(file_get_contents("tmp.lang"), "utf8", "big5");' > lang/zhtw.lua
	rm -f tmp.lang

dist-zip:
	git archive --prefix HM/ HEAD | tar -x
	cp -f src/HM.lua HM/src/HM.lua
	cp -f info.ini HM/info.ini
	luac -s -o HM/lab/HM_Cast.lua lab/HM_Cast.lua
	luac -s -o HM/lab/HM_Love.lua lab/HM_Love.lua
	zip -qrm9 dist/HM-`cat VERSION`.zip HM

src-bak:
	zip -rq9 dist/HM-`cat VERSION`-src.zip * -x dist/*.zip

archive: lang/zhtw.lua
	git ci -a -m "Release "`cat VERSION`
	git tag `cat VERSION`
	$(MAKE) dist-zip
	$(MAKE) src-bak

hotfix: clean-check
	$(MAKE) dist-zip
	$(MAKE) src-bak
	scp dist/HM-`cat VERSION`.zip jx3.hm:$(JX3_HM_DIR)/down
	ssh jx3.hm rm -rf -d $(JX3_HM_DIR)/sync/HM
	ssh jx3.hm unzip -qq -o -d $(JX3_HM_DIR)/sync $(JX3_HM_DIR)/down/HM-`cat VERSION`.zip

alpha: clean-check
	$(PHP) dev/pre_release.php alpha
	$(MAKE) dist-zip
	git reset --hard HEAD

beta: clean-check
	$(PHP) dev/pre_release.php beta
	$(MAKE) archive
	$(MAKE) sync

stable: master-check clean-check
	$(PHP) dev/pre_release.php stable $(VERSION)
	$(MAKE) archive
	$(MAKE) sync
