include ../../extra.mk

PROG = ofhttp${PROG_SUFFIX}
SRCS = OFHTTP.m		\
       ProgressBar.m
DATA = localization/de.json5		\
       localization/localizations.json5
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
	    -DLOCALIZATION_DIR='"${datadir}/ofhttp/localization"'	\
	    -DBUILD_DATE=\"$$(date +%d.%m.%y)\"
OBJCFLAGS += ${PIE_CFLAGS}
LIBS := -L../../src			\
	-L../../src/linklib		\
	-L../../src/runtime		\
	-L../../src/runtime/linklib	\
	-L../../src/tls			\
	-L../../src/tls/linklib		\
	${OFHTTP_LIBS}			\
	${OBJFW_LIB}			\
	${RUNTIME_LIBS}			\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${PIE_LDFLAGS} ${LDFLAGS_RPATH}
