LIB = ${LIB_PREFIX}objfw${LIB_SUFFIX}
LIB_MAJOR = 1
LIB_MINOR = 0

SRCS = OFList.m		\
       OFListObject.m	\
       OFObject.m	\
       OFString.m

OBJCFLAGS += -fPIC -DPIC -fno-nil-recivers -fconstant-string-class=OFConstString
INCLUDES = OFList.h		\
	   OFListObject.h	\
	   OFObject.h		\
	   OFString.h

include ../buildsys.mk

LD = ${OBJC}
LIBS += -lobjc
