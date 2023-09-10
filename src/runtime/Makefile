include ../../extra.mk

SUBDIRS = lookup-asm
DISTCLEAN = Info.plist

SHARED_LIB = ${OBJFWRT_SHARED_LIB}
STATIC_LIB = ${OBJFWRT_STATIC_LIB}
FRAMEWORK = ${OBJFWRT_FRAMEWORK}
LIB_MAJOR = ${OBJFWRT_LIB_MAJOR}
LIB_MINOR = ${OBJFWRT_LIB_MINOR}
LIB_PATCH = ${OBJFWRT_LIB_PATCH}

SRCS = arc.m			\
       autorelease.m		\
       category.m		\
       class.m			\
       dtable.m			\
       exception.m		\
       hashtable.m		\
       init.m			\
       instance.m		\
       ivar.m			\
       lookup.m			\
       method.m			\
       misc.m			\
       property.m		\
       protocol.m		\
       selector.m		\
       sparsearray.m		\
       static-instances.m	\
       synchronized.m		\
       tagged-pointer.m		\
       ${USE_SRCS_THREADS}	\
       ${USE_SRCS_WINDOWS}
SRCS_THREADS = OFOnce.m		\
	       OFPlainMutex.m	\
	       OFTLSKey.m	\
	       threading.m
SRCS_WINDOWS = versioninfo.rc
INCLUDES = ObjFWRT.h
includesubdir = ObjFWRT

OBJS_EXTRA = lookup-asm/lookup-asm.a
LIB_OBJS_EXTRA = lookup-asm/lookup-asm.lib.a

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../..					\
	    -DOBJC_COMPILING_RUNTIME				\
	    -DOBJFWRT_LIB_MAJOR=${OBJFWRT_LIB_MAJOR}		\
	    -DOBJFWRT_LIB_MINOR=${OBJFWRT_LIB_MINOR}
LD = ${OBJC}
FRAMEWORK_LIBS = ${LIBS}
RCFLAGS = --use-temp-file						      \
	  -DOBJFWRT_LIB_MAJOR=${OBJFWRT_LIB_MAJOR}			      \
	  -DOBJFWRT_LIB_MINOR=${OBJFWRT_LIB_MINOR}			      \
	  -DOBJFWRT_LIB_VERSION=\"${OBJFWRT_LIB_MAJOR}.${OBJFWRT_LIB_MINOR}\" \
	  -DOBJFWRT_SHARED_LIB=\"${OBJFWRT_SHARED_LIB}\"
