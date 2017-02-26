include ../../extra.mk

PROG = ofzip${PROG_SUFFIX}
SRCS = GZIPArchive.m	\
       OFZIP.m		\
       TarArchive.m	\
       ZIPArchive.m
DATA = lang/de.json		\
       lang/languages.json

include ../../buildsys.mk

PACKAGE_NAME = ofzip

${PROG}: ${LIBOBJFW_DEP_LVL2}

CPPFLAGS += -I../../src					\
	    -I../../src/runtime				\
	    -I../../src/exceptions			\
	    -I../..					\
	    -DLANGUAGE_DIR=\"${datadir}/ofzip/lang\"
LIBS := -L../../src -lobjfw ${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
