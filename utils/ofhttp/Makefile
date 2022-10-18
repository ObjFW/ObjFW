include ../../extra.mk

PROG = ofhttp${PROG_SUFFIX}
SRCS = OFHTTP.m		\
       ProgressBar.m
DATA = localization/de.json		\
       localization/localizations.json

include ../../buildsys.mk

PACKAGE_NAME = ofhttp

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src							\
	    -I../../src/runtime						\
	    -I../../src/exceptions					\
	    -I../../src/tls						\
	    -I../..							\
	    -DLOCALIZATION_DIR='"${datadir}/ofhttp/localization"'	\
	    -DLIB_PREFIX='"${LIB_PREFIX}"'				\
	    -DLIB_SUFFIX='"${LIB_SUFFIX}"'
LIBS := -L../../src -L../../src/linklib -L../../src/tls			\
	${OFHTTP_LIBS} ${OBJFW_LIBS}					\
	-L../../src/runtime -L../../src/runtime/linklib ${RUNTIME_LIBS}	\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
