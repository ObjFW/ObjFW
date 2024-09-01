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
	    -I../..							\
	    -DLOCALIZATION_DIR=\"${datadir}/ofhash/localization\"
LIBS := -L../../src -L../../src/tls ${OFHASH_LIBS} -lobjfw		\
	-L../../src/runtime ${RUNTIME_LIBS}				\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
