LIB = ${LIB_PREFIX}objfw${LIB_SUFFIX}
LIB_MAJOR = 1
LIB_MINOR = 0

SRCS = OFConstString.m	\
       OFList.m		\
       OFListObject.m	\
       OFObject.m	\
       OFString.m

OBJCFLAGS += -fPIC -DPIC -fno-nil-recivers -fconstant-string-class=OFConstString
INCLUDES = OFConstString.h	\
	   OFList.h		\
	   OFListObject.h	\
	   OFObject.h		\
	   OFString.h

include ../buildsys.mk

LD = ${OBJC}
LIBS += -lobjc
