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
	git co master -- LICENSE.txt
	$(PHP) update_version.php
	$(PHP) update_sync_file.php
	git ci -a -m "Update gh-pages to "`cat VERSION`
	git push -f
	scp sync.xml release.dat changelog.html jx3.hm:$(JX3_HM_DIR)/sync
	scp dist/HM-`cat VERSION`.zip jx3.hm:$(JX3_HM_DIR)/down
	ssh jx3.hm rm -rf -d $(JX3_HM_DIR)/sync/HM
	ssh jx3.hm unzip -qq -o -d $(JX3_HM_DIR)/sync $(JX3_HM_DIR)/down/HM-`cat VERSION`.zip
	git co master

lang: HM_0Base/lang/zhtw.jx3dat

sync:
	git push --tags
	#$(MAKE) sync-page

HM_0Base/lang/zhtw.jx3dat: HM_0Base/lang/zhcn.jx3dat
	big2gb -r < HM_0Base/lang/zhcn.jx3dat | sed 's#zhcn#zhtw#' > tmp.lang
	$(PHP) -r 'echo mb_convert_encoding(file_get_contents("tmp.lang"), "utf8", "big5");' > HM_0Base/lang/zhtw.jx3dat
	rm -f tmp.lang

dist-zip:
	git archive --prefix HM/ HEAD | tar -x
	cp -f HM_0Base/HM.lua HM/HM_0Base/HM.lua
	zip -qrm9 dist/HM-`cat VERSION`.zip HM

dist-zip2:
	git archive --prefix HM/ HEAD | tar -x
	cp -f HM_0Base/HM.lua HM/HM_0Base/HM.lua
	sh -c 'fs=`find HM/ -name "*.lua"`; for f in $$fs; do luac -s -o $$f $$f; done'
	zip -qrm9 dist/HM-`cat VERSION`.zip HM

src-bak:
	zip -rq9 dist/HM-`cat VERSION`-src.zip * -x dist/*.zip

archive: HM_0Base/lang/zhtw.jx3dat
	git ci -a -m "Release "`cat VERSION`
	git tag `cat VERSION`
	$(MAKE) dist-zip
	$(MAKE) src-bak

alpha: clean-check
	$(PHP) dev/pre_release.php alpha $(VERSION)
	$(MAKE) dist-zip2
	git reset --hard HEAD

beta: clean-check
	$(PHP) dev/pre_release.php beta $(VERSION)
	$(MAKE) archive
	$(MAKE) sync

stable: master-check clean-check
	$(PHP) dev/pre_release.php stable $(VERSION)
	$(MAKE) archive
	$(MAKE) sync
