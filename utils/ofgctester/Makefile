include ../../extra.mk

PROG = ofgctester${PROG_SUFFIX}
SRCS = OFGCTester.m
DATA = localization/de.json		\
       localization/localizations.json
MAN = ofgctester.1

include ../../buildsys.mk

PACKAGE_NAME = ofgctester

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src							\
	    -I../../src/runtime						\
	    -I../../src/exceptions					\
	    -I../../src/hid						\
	    -I../..							\
	    -DOBJFWHID_LOCAL_INCLUDES					\
	    -DLOCALIZATION_DIR=\"${datadir}/ofgctester/localization\"	\
	    -DBUILD_DATE=\"$$(date +%d.%m.%y)\"
OBJCFLAGS += ${PIE_CFLAGS}
LIBS := -L../../src			\
	-L../../src/linklib		\
	-L../../src/runtime		\
	-L../../src/runtime/linklib	\
	-L../../src/hid			\
	-L../../src/hid/linklib		\
	-L../../src/bridge		\
	${OFGCTESTER_LIBS}		\
	${OBJFW_LIB}			\
	${RUNTIME_LIBS}			\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${PIE_LDFLAGS} ${LDFLAGS_RPATH}
