include ../../extra.mk

PROG = ofhttp${PROG_SUFFIX}
SRCS = OFHTTP.m		\
       ProgressBar.m
DATA = lang/de.json		\
       lang/languages.json

include ../../buildsys.mk

PACKAGE_NAME = ofhttp

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src					\
	    -I../../src/runtime				\
	    -I../../src/exceptions			\
	    -I../..					\
	    -DLANGUAGE_DIR=\"${datadir}/ofhttp/lang\"
LIBS := -L../../src -lobjfw						\
	-L../../src/runtime -L../../src/runtime/linklib ${RUNTIME_LIBS}	\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
