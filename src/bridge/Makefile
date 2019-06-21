include ../../extra.mk

DISTCLEAN = Info.plist

SHARED_LIB = ${OBJFWBRIDGE_SHARED_LIB}
STATIC_LIB = ${OBJFWBRIDGE_STATIC_LIB}
FRAMEWORK = ${OBJFWBRIDGE_FRAMEWORK}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}

SRCS = OFArray+NSObject.m	\
       OFEnumerator+NSObject.m	\
       OFException+Swift.m	\
       OFDictionary+NSObject.m	\
       OFNumber+NSObject.m	\
       OFSet+NSObject.m		\
       OFString+NSObject.m	\
       NSArray+OFObject.m	\
       NSDictionary+OFObject.m	\
       NSEnumerator+OFObject.m	\
       NSNumber+OFObject.m	\
       NSSet+OFObject.m		\
       NSString+OFObject.m

INCLUDES := ${SRCS:.m=.h}	\
	    NSBridging.h	\
	    OFBridging.h	\
	    ObjFWBridge.h

SRCS += NSOFArray.m		\
	NSOFDictionary.m	\
	NSOFEnumerator.m	\
	NSOFSet.m		\
	OFNSArray.m		\
	OFNSDictionary.m	\
	OFNSEnumerator.m	\
	OFNSSet.m

includesubdir = ObjFWBridge

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../.. -I../exceptions -DOF_BRIDGE_LOCAL_INCLUDES
LD = ${OBJC}
FRAMEWORK_LIBS := -framework Foundation -F.. -framework ObjFW ${LIBS}
LIBS := -framework Foundation -L.. -lobjfw ${LIBS}
