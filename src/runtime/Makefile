include ../../extra.mk

SUBDIRS = lookup-asm
CLEAN = ${OBJFW_RT_INLINE_H}

SHARED_LIB = ${OBJFW_RT_SHARED_LIB}
STATIC_LIB = ${OBJFW_RT_STATIC_LIB}
FRAMEWORK = ${OBJFW_RT_FRAMEWORK}
AMIGA_LIB = ${OBJFW_RT_AMIGA_LIB}
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
INCLUDES = ObjFW_RT.h ${OBJFW_RT_INLINE_H}
includesubdir = ObjFW_RT

OBJS_EXTRA = ${LOOKUP_ASM_LOOKUP_ASM_A}
LIB_OBJS_EXTRA = ${LOOKUP_ASM_LOOKUP_ASM_LIB_A}
AMIGA_LIB_OBJS_EXTRA = amiga-glue.amigalib.o		\
		       amiga-library.amigalib.o		\
		       ${LOOKUP_ASM_LOOKUP_ASM_A}

include ../../buildsys.mk

${OBJFW_RT_AMIGA_LIB}: ${OBJFW_RT_INLINE_H}

amiga-library.m: amiga-library-functable.inc

amiga-library-functable.inc: ObjFW_RT.sfd
	sfdc -q --target=${SFDC_TARGET} --mode=functable -o $@ $<

${OBJFW_RT_INLINE_H}: ObjFW_RT.sfd
	sfdc -q --target=${SFDC_TARGET} --mode=macros -o $@ $<

CPPFLAGS += -I. -I.. -I../..				\
	    -DOF_COMPILING_OBJFW_RT			\
	    -DOBJFW_RT_LIB_MAJOR=${OBJFW_RT_LIB_MAJOR}	\
	    -DOBJFW_RT_LIB_MINOR=${OBJFW_RT_LIB_MINOR}
AMIGA_LIB_CFLAGS += -DOBJC_COMPILING_AMIGA_LIBRARY
LD = ${OBJC}
FRAMEWORK_LIBS = ${LIBS}
