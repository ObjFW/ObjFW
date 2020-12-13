include ../../extra.mk

PROG = ofsock${PROG_SUFFIX}
SRCS = OFSock.m

include ../../buildsys.mk

PACKAGE_NAME = ofsock

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src					\
	    -I../../src/runtime				\
	    -I../../src/exceptions			\
	    -I../..
LIBS := -L../../src -L../../src/linklib ${OBJFW_LIBS}			\
	-L../../src/runtime -L../../src/runtime/linklib ${RUNTIME_LIBS}	\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
