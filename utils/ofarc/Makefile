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

include ../../buildsys.mk

PACKAGE_NAME = ofarc

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src							\
	    -I../../src/runtime						\
	    -I../../src/exceptions					\
	    -I../..							\
	    -DLOCALIZATION_DIR=\"${datadir}/ofarc/localization\"
LIBS := -L../../src -lobjfw -L../../src/runtime ${RUNTIME_LIBS} ${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
