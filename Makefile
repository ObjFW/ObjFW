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

.PHONY: check docs release

utils tests: src

check: tests
	${MAKE} -C tests -s run

docs:
	rm -fr docs
	doxygen >/dev/null

release: docs
	echo "Generating tarball for version ${PACKAGE_VERSION}..."
	rm -fr objfw-${PACKAGE_VERSION} objfw-${PACKAGE_VERSION}.tar \
		objfw-${PACKAGE_VERSION}.tar.gz
	fossil tarball --name objfw-${PACKAGE_VERSION} current - \
		--exclude '.fossil*,.git*' | ofarc -ttgz -xq -
	cp configure config.h.in objfw-${PACKAGE_VERSION}/
	ofarc -cq objfw-${PACKAGE_VERSION}.tar objfw-${PACKAGE_VERSION}
	rm -fr objfw-${PACKAGE_VERSION}
	gzip -9 objfw-${PACKAGE_VERSION}.tar
	rm -f objfw-${PACKAGE_VERSION}.tar
	gpg -b objfw-${PACKAGE_VERSION}.tar.gz || true
	rm -fr objfw-docs-${PACKAGE_VERSION} objfw-docs-${PACKAGE_VERSION}.tar \
		objfw-docs-${PACKAGE_VERSION}.tar.gz
	mv docs objfw-docs-${PACKAGE_VERSION}
	echo "Generating docs tarball for version ${PACKAGE_VERSION}..."
	ofarc -cq objfw-docs-${PACKAGE_VERSION}.tar \
		objfw-docs-${PACKAGE_VERSION}
	rm -fr objfw-docs-${PACKAGE_VERSION}
	gzip -9 objfw-docs-${PACKAGE_VERSION}.tar
	rm -f objfw-docs-${PACKAGE_VERSION}.tar
	gpg -b objfw-docs-${PACKAGE_VERSION}.tar.gz || true
