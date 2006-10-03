VERSION = 0.2.2

dist:
	mkdir mubench-$(VERSION)
	tar c --files-from=MANIFEST --exclude=".svn" -f tmp.tar ; cd mubench-$(VERSION) ; tar xf ../tmp.tar ; rm -f ../tmp.tar
	tar czf ../mubench-$(VERSION).tar.gz mubench-$(VERSION)
	rm -rf mubench-$(VERSION)
