include ../../extra.mk

PROG = ofhttp${PROG_SUFFIX}
SRCS = OFHTTP.m		\
       ProgressBar.m
DATA = lang/de.json		\
       lang/languages.json

include ../../buildsys.mk

PACKAGE_NAME = ofhttp

${PROG}: ${LIBOBJFW_DEP_LVL2}

CPPFLAGS += -I../../src			\
	    -I../../src/runtime		\
	    -I../../src/exceptions	\
	    -I../..			\
	    -DDATADIR=\"${datadir}\"
LIBS := -L../../src -lobjfw ${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
