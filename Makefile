include extra.mk

SUBDIRS = src utils ${TESTS}
DISTCLEAN = aclocal.m4		\
	    autom4te.cache	\
	    buildsys.mk		\
	    config.h		\
	    config.log		\
	    config.status	\
	    extra.mk

include buildsys.mk

utils ${TESTS}: src

tarball:
	echo "Generating tarball for version ${PACKAGE_VERSION}..."
	rm -fr objfw-${PACKAGE_VERSION} objfw-${PACKAGE_VERSION}.tar \
		objfw-${PACKAGE_VERSION}.tar.gz
	mkdir objfw-${PACKAGE_VERSION}
	git --work-tree=objfw-${PACKAGE_VERSION} checkout .
	rm objfw-${PACKAGE_VERSION}/.gitignore
	cp configure config.h.in objfw-${PACKAGE_VERSION}/
	tar cf objfw-${PACKAGE_VERSION}.tar objfw-${PACKAGE_VERSION}
	rm -fr objfw-${PACKAGE_VERSION}
	gzip -9 objfw-${PACKAGE_VERSION}.tar
	rm -f objfw-${PACKAGE_VERSION}.tar
