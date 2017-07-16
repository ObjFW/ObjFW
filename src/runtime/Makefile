include ../../extra.mk

SUBDIRS = lookup-asm

SHARED_LIB = ${OBJFW_RT_SHARED_LIB}
STATIC_LIB = ${OBJFW_RT_STATIC_LIB}
MORPHOS_LIB = ${OBJFW_RT_MORPHOS_LIB}
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
MORPHOS_LIB_OBJS_EXTRA = morphos-library.o ${LOOKUP_ASM_LOOKUP_ASM_A}

include ../../buildsys.mk

${MORPHOS_LIB}: ppcinline.h
ppcinline.h: ObjFW-RT.fd ObjFW-RT.h
	cvinclude.pl			\
		--root ObjFW-RT		\
		--fd ObjFW-RT.fd	\
		--clib ObjFW-RT.h	\
		--inline $@

CPPFLAGS += -I. -I.. -I../..				\
	    -DOBJFW_RT_LIB_MAJOR=${OBJFW_RT_LIB_MAJOR}	\
	    -DOBJFW_RT_LIB_MINOR=${OBJFW_RT_LIB_MINOR}
LD = ${OBJC}
