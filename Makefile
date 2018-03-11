include extra.mk

SUBDIRS = src utils tests
DISTCLEAN = Info.plist		\
	    aclocal.m4		\
	    autom4te.cache	\
	    buildsys.mk		\
	    config.h		\
	    config.log		\
	    config.status	\
	    extra.mk

include buildsys.mk

utils tests: src

tarball:
	echo "Generating tarball for version ${PACKAGE_VERSION}..."
	rm -fr objfw-${PACKAGE_VERSION} objfw-${PACKAGE_VERSION}.tar \
		objfw-${PACKAGE_VERSION}.tar.gz
	mkdir objfw-${PACKAGE_VERSION}
	git --work-tree=objfw-${PACKAGE_VERSION} checkout .
	rm objfw-${PACKAGE_VERSION}/.gitignore \
		objfw-${PACKAGE_VERSION}/.travis.yml
	cp configure config.h.in objfw-${PACKAGE_VERSION}/
	ofzip -cq objfw-${PACKAGE_VERSION}.tar $$(find objfw-${PACKAGE_VERSION})
	rm -fr objfw-${PACKAGE_VERSION}
	gzip -9 objfw-${PACKAGE_VERSION}.tar
	rm -f objfw-${PACKAGE_VERSION}.tar
	gpg -b objfw-${PACKAGE_VERSION}.tar.gz || true
	echo "Generating documentation..."
	rm -fr docs
	doxygen >/dev/null
	rm -fr objfw-docs-${PACKAGE_VERSION} objfw-docs-${PACKAGE_VERSION}.tar \
		objfw-docs-${PACKAGE_VERSION}.tar.gz
	mv docs objfw-docs-${PACKAGE_VERSION}
	echo "Generating docs tarball for version ${PACKAGE_VERSION}..."
	ofzip -cq objfw-docs-${PACKAGE_VERSION}.tar \
		$$(find objfw-docs-${PACKAGE_VERSION})
	rm -fr objfw-docs-${PACKAGE_VERSION}
	gzip -9 objfw-docs-${PACKAGE_VERSION}.tar
	rm -f objfw-docs-${PACKAGE_VERSION}.tar
	gpg -b objfw-docs-${PACKAGE_VERSION}.tar.gz || true
