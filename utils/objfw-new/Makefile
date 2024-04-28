include ../../extra.mk

PROG = objfw-new${PROG_SUFFIX}
SRCS = NewApp.m		\
       NewClass.m	\
       NewTest.m	\
       ObjFWNew.m	\
       Property.m

include ../../buildsys.mk

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src					\
	    -I../../src/runtime				\
	    -I../../src/exceptions			\
	    -I../..
LIBS := -L../../src -lobjfw -L../../src/runtime ${RUNTIME_LIBS} ${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
