include ../../extra.mk

DISTCLEAN = Info.plist

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
	   NSBridging.h		\
	   OFBridging.h		\
	   ObjFW-Bridge.h

includesubdir = ObjFW-Bridge

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../.. -I../exceptions -DOF_BRIDGE_LOCAL_INCLUDES
LD = ${OBJC}
LIBS = -L.. -lobjfw -framework Foundation
