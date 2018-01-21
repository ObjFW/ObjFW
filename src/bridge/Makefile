include ../../extra.mk

DISTCLEAN = Info.plist

SHARED_LIB = ${OBJFW_BRIDGE_SHARED_LIB}
STATIC_LIB = ${OBJFW_BRIDGE_STATIC_LIB}
FRAMEWORK = ${OBJFW_BRIDGE_FRAMEWORK}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}

SRCS = OFArray+NSObject.m	\
       OFException+Swift.m	\
       OFDictionary+NSObject.m	\
       OFString+NSObject.m	\
       NSArray+OFObject.m	\
       NSDictionary+OFObject.m	\
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
LIBS += -framework Foundation -L.. -lobjfw
FRAMEWORK_LIBS += -framework Foundation -F.. -framework ObjFW
