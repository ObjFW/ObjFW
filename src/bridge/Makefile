include ../../extra.mk

SHARED_LIB = ${OBJFW_BRIDGE_SHARED_LIB}
STATIC_LIB = ${OBJFW_BRIDGE_STATIC_LIB}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}

SRCS = OFArray+NSObject.m		\
       OFArray_NSArray.m		\
       OFDictionary+NSObject.m		\
       OFDictionary_NSDictionary.m	\
       OFString+NSObject.m		\
       NSArray+OFObject.m		\
       NSArray_OFArray.m		\
       NSDictionary+OFObject.m		\
       NSDictionary_OFDictionary.m	\
       NSString+OFObject.m

INCLUDES = ${SRCS:.m=.h}	\
	   OFBridging.h		\
	   NSBridging.h		\
	   bridge.h

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../.. -I../exceptions
LD = ${OBJC}
LDFLAGS += -Wl,-flat_namespace,-undefined,suppress
