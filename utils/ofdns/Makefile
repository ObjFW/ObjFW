include ../../extra.mk

PROG = ofdns${PROG_SUFFIX}
SRCS = OFDNS.m
DATA = localization/de.json		\
       localization/localizations.json
MAN = ofdns.1

include ../../buildsys.mk

PACKAGE_NAME = ofdns

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src							\
	    -I../../src/runtime						\
	    -I../../src/exceptions					\
	    -I../..							\
	    -DLOCALIZATION_DIR=\"${datadir}/ofdns/localization\"	\
	    -DBUILD_DATE=\"$$(date +%d.%m.%y)\"
OBJCFLAGS += ${PIE_CFLAGS}
LIBS := -L../../src -L../../src/linklib ${OBJFW_LIB}			\
	-L../../src/runtime -L../../src/runtime/linklib	${RUNTIME_LIBS}	\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${PIE_LDFLAGS} ${LDFLAGS_RPATH}
