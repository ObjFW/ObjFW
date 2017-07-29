include ../../extra.mk

SUBDIRS = lookup-asm

SHARED_LIB = ${OBJFW_RT_SHARED_LIB}
STATIC_LIB = ${OBJFW_RT_STATIC_LIB}
LIB_MAJOR = ${OBJFW_RT_LIB_MAJOR}
LIB_MINOR = ${OBJFW_RT_LIB_MINOR}

SRCS = arc.m			\
       category.m		\
       class.m			\
       dtable.m			\
       exception.m		\
       hashtable.m		\
       init.m			\
       lookup.m			\
       misc.m			\
       property.m		\
       protocol.m		\
       selector.m		\
       sparsearray.m		\
       static-instances.m	\
       synchronized.m		\
       ${USE_SRCS_THREADS}
SRCS_THREADS = threading.m	\
	       ../threading.m
INCLUDES = ObjFW-RT.h
includesubdir = ObjFW-RT

OBJS_EXTRA = ${LOOKUP_ASM_LOOKUP_ASM_A}
LIB_OBJS_EXTRA = ${LOOKUP_ASM_LOOKUP_ASM_LIB_A}

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../..				\
	    -DOF_COMPILING_OBJFW_RT			\
	    -DOBJFW_RT_LIB_MAJOR=${OBJFW_RT_LIB_MAJOR}	\
	    -DOBJFW_RT_LIB_MINOR=${OBJFW_RT_LIB_MINOR}
LD = ${OBJC}
