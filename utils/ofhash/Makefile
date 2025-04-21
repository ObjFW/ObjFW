include ../../extra.mk

PROG = ofhash${PROG_SUFFIX}
SRCS = OFHash.m
DATA = localization/de.json		\
       localization/localizations.json
MAN = ofhash.1

include ../../buildsys.mk

PACKAGE_NAME = ofhash

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src							\
	    -I../../src/runtime						\
	    -I../../src/exceptions					\
	    -I../../src/tls						\
	    -I../..							\
	    -DOBJFWTLS_LOCAL_INCLUDES					\
	    -DLOCALIZATION_DIR=\"${datadir}/ofhash/localization\"
OBJCFLAGS += ${PIE_CFLAGS}
LIBS := -L../../src			\
	-L../../src/runtime		\
	-L../../src/runtime/linklib	\
	-L../../src/tls			\
	-L../../src/bridge		\
	${OFHASH_LIBS}			\
	-lobjfw				\
	${RUNTIME_LIBS}			\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${PIE_LDFLAGS} ${LDFLAGS_RPATH}
