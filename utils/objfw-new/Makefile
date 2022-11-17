include ../../extra.mk

PROG = objfw-new${PROG_SUFFIX}
SRCS = NewApp.m		\
       NewClass.m	\
       ObjFWNew.m	\
       Property.m

include ../../buildsys.mk

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src					\
	    -I../../src/runtime				\
	    -I../../src/exceptions			\
	    -I../..
LIBS := -L../../src  -L../../src/linklib ${OBJFW_LIBS}			\
	-L../../src/runtime -L../../src/runtime/linklib ${RUNTIME_LIBS}	\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
