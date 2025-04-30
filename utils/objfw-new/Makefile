include ../../extra.mk

PROG = objfw-new${PROG_SUFFIX}
SRCS = NewApp.m		\
       NewClass.m	\
       NewTest.m	\
       ObjFWNew.m	\
       Property.m
MAN = objfw-new.1

include ../../buildsys.mk

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src					\
	    -I../../src/runtime				\
	    -I../../src/exceptions			\
	    -I../..
OBJCFLAGS += ${PIE_CFLAGS}				\
	     -DBUILD_DATE=\"$$(date +%d.%m.%y)\"
LIBS := -L../../src ${OBJFW_LIB}					\
	-L../../src/runtime -L../../src/runtime/linklib	${RUNTIME_LIBS}	\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${PIE_LDFLAGS} ${LDFLAGS_RPATH}
