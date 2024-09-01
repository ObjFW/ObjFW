include ../../extra.mk

PROG = ofhttp${PROG_SUFFIX}
SRCS = OFHTTP.m		\
       ProgressBar.m
DATA = localization/de.json		\
       localization/localizations.json
MAN = ofhttp.1

include ../../buildsys.mk

PACKAGE_NAME = ofhttp

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src							\
	    -I../../src/runtime						\
	    -I../../src/exceptions					\
	    -I../../src/tls						\
	    -I../..							\
	    -DLOCALIZATION_DIR='"${datadir}/ofhttp/localization"'
LIBS := -L../../src -L../../src/tls ${OFHTTP_LIBS} -lobjfw		\
	-L../../src/runtime ${RUNTIME_LIBS}				\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
