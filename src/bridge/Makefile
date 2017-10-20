include ../../extra.mk

DISTCLEAN = Info.plist

SHARED_LIB = ${OBJFW_BRIDGE_SHARED_LIB}
STATIC_LIB = ${OBJFW_BRIDGE_STATIC_LIB}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}
FRAMEWORK = ObjFW_Bridge.framework

SRCS = OFArray+NSObject.m		\
       OFException+NSError.m		\
       OFDictionary+NSObject.m		\
       OFString+NSObject.m		\
       NSArray+OFObject.m		\
       NSDictionary+OFObject.m		\
       NSString+OFObject.m

INCLUDES := ${SRCS:.m=.h}	\
	    NSBridging.h	\
	    OFBridging.h	\
	    ObjFW_Bridge.h

SRCS += NSArray_OFArray.m		\
	NSDictionary_OFDictionary.m	\
	OFArray_NSArray.m		\
	OFDictionary_NSDictionary.m	\

includesubdir = ObjFW_Bridge

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../.. -I../exceptions -DOF_BRIDGE_LOCAL_INCLUDES
LD = ${OBJC}
LIBS = -framework Foundation
LIB_LDFLAGS += -L.. -lobjfw
FRAMEWORK_LDFLAGS += -F.. -framework ObjFW

OBJCFLAGS_OFException+NSError.m += -fconstant-cfstrings
