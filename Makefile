include extra.mk

SUBDIRS = src ${TESTS}
DISTCLEAN = aclocal.m4		\
	    autom4te.cache	\
	    buildsys.mk		\
	    config.log		\
	    config.status	\
	    extra.mk

include buildsys.mk
