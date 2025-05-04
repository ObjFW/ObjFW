include ../../extra.mk

PROG = ofarc${PROG_SUFFIX}
SRCS = GZIPArchive.m	\
       LHAArchive.m	\
       OFArc.m		\
       TarArchive.m	\
       ZIPArchive.m	\
       ZooArchive.m
DATA = localization/de.json		\
       localization/localizations.json
MAN = ofarc.1

include ../../buildsys.mk

PACKAGE_NAME = ofarc

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src							\
	    -I../../src/runtime						\
	    -I../../src/exceptions					\
	    -I../../src/tls						\
	    -I../..							\
	    -DOBJFWTLS_LOCAL_INCLUDES					\
	    -DLOCALIZATION_DIR=\"${datadir}/ofarc/localization\"	\
	    -DBUILD_DATE=\"$$(date +%d.%m.%y)\"
OBJCFLAGS += ${PIE_CFLAGS}
LIBS := -L../../src			\
	-L../../src/linklib		\
	-L../../src/runtime		\
	-L../../src/runtime/linklib	\
	-L../../src/tls			\
	-L../../src/bridge		\
	${OFHTTP_LIBS}			\
	${OBJFW_LIB}			\
	${RUNTIME_LIBS}			\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${PIE_LDFLAGS} ${LDFLAGS_RPATH}
