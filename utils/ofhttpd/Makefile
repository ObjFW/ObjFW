include ../../extra.mk

PROG = ofhttpd${PROG_SUFFIX}
SRCS = OFHTTPD.m

include ../../buildsys.mk

PACKAGE_NAME = ofhttpd

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src							\
	    -I../../src/runtime						\
	    -I../../src/exceptions					\
	    -I../..
LIBS := -L../../src -lobjfw -L../../src/runtime ${RUNTIME_LIBS} ${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
