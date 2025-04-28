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
	    -DOBJFWTLS_LOCAL_INCLUDES					\
	    -DLOCALIZATION_DIR='"${datadir}/ofhttp/localization"'
OBJCFLAGS += ${PIE_CFLAGS}				\
	     -DBUILD_DATE=\"$$(date +%d.%m.%y)\"
LIBS := -L../../src		\
	-L../../src/runtime	\
	-L../../src/tls		\
	-L../../src/bridge	\
	${OFHTTP_LIBS}		\
	-lobjfw			\
	${RUNTIME_LIBS}		\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${PIE_LDFLAGS} ${LDFLAGS_RPATH}
