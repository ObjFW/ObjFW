include ../../extra.mk

PROG = ofatalkcfg${PROG_SUFFIX}
SRCS = OFATalkCfg.m

include ../../buildsys.mk

PACKAGE_NAME = ofatalkcfg

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src							\
	    -I../../src/runtime						\
	    -I../../src/exceptions					\
	    -I../..
LIBS := -L../../src -lobjfw						\
	-L../../src/runtime -L../../src/runtime/linklib ${RUNTIME_LIBS}	\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
