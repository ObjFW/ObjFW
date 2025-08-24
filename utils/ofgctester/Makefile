include ../../extra.mk

PROG = ofgctester${PROG_SUFFIX}
SRCS = OFGCTester.m
MAN = ofgctester.1

include ../../buildsys.mk

${PROG}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2}

CPPFLAGS += -I../../src							\
	    -I../../src/runtime						\
	    -I../../src/exceptions					\
	    -I../../src/hid						\
	    -I../..							\
	    -DOBJFWHID_LOCAL_INCLUDES					\
	    -DBUILD_DATE=\"$$(date +%d.%m.%y)\"
OBJCFLAGS += ${PIE_CFLAGS}
LIBS := -L../../src			\
	-L../../src/runtime		\
	-L../../src/runtime/linklib	\
	-L../../src/hid			\
	-L../../src/bridge		\
	-lobjfwhid			\
	${HID_LIBS}			\
	-lobjfw				\
	${RUNTIME_LIBS}			\
	${LIBS}
LD = ${OBJC}
LDFLAGS += ${PIE_LDFLAGS} ${LDFLAGS_RPATH}
