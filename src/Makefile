LIB = ${LIB_PREFIX}objfw${LIB_SUFFIX}
LIB_MAJOR = 1
LIB_MINOR = 0

SRCS = OFConstString.m		\
       OFConstWideString.m	\
       OFException.m		\
       OFList.m			\
       OFListObject.m		\
       OFObject.m		\
       OFString.m		\
       OFWideString.m

OBJCFLAGS += -fPIC -DPIC -fno-nil-recivers -fconstant-string-class=OFConstString -fobjc-exceptions
INCLUDES = OFConstString.h	\
	   OFConstWideString.h	\
	   OFException.h	\
	   OFList.h		\
	   OFListObject.h	\
	   OFObject.h		\
	   OFString.h		\
	   OFWideString.h

include ../buildsys.mk

LD = ${OBJC}
LIBS += -lobjc
