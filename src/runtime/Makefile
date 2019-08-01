include ../../extra.mk

SUBDIRS = lookup-asm
SUBDIRS_AFTER = ${LINKLIB}
CLEAN = amiga-library-functable.inc inline.h

SHARED_LIB = ${OBJFWRT_SHARED_LIB}
STATIC_LIB = ${OBJFWRT_STATIC_LIB}
FRAMEWORK = ${OBJFWRT_FRAMEWORK}
AMIGA_LIB = ${OBJFWRT_AMIGA_LIB}
LIB_MAJOR = ${OBJFWRT_LIB_MAJOR}
LIB_MINOR = ${OBJFWRT_LIB_MINOR}

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
	       ../mutex.m	\
	       ../once.m
INCLUDES = ObjFWRT.h
includesubdir = ObjFWRT

OBJS_EXTRA = ${LOOKUP_ASM_LOOKUP_ASM_A}
LIB_OBJS_EXTRA = ${LOOKUP_ASM_LOOKUP_ASM_LIB_A}
AMIGA_LIB_OBJS_START = amiga-library.amigalib.o
AMIGA_LIB_OBJS_EXTRA = amiga-glue.amigalib.o		\
		       ${LOOKUP_ASM_LOOKUP_ASM_A}	\
		       amiga-end.amigalib.o

include ../../buildsys.mk

${OBJFWRT_AMIGA_LIB}: inline.h

${SFDC_INLINE_H}: ${SFD_FILE}
	sfdc -q --target=${SFDC_TARGET} --mode=macros -o $@ $<; \

${CVINCLUDE_INLINE_H}: morphos.fd morphos-clib.h
	cvinclude.pl --quiet --fd=morphos.fd --clib=morphos-clib.h --inlines=$@

CPPFLAGS += -I. -I.. -I../..					\
	    -DOBJFWRT_AMIGA_LIB=\"${OBJFWRT_AMIGA_LIB}\"	\
	    -DOBJFWRT_LIB_MAJOR=${OBJFWRT_LIB_MAJOR}		\
	    -DOBJFWRT_LIB_MINOR=${OBJFWRT_LIB_MINOR}
AMIGA_LIB_CFLAGS += -DOBJC_COMPILING_AMIGA_LIBRARY
LD = ${OBJC}
FRAMEWORK_LIBS = ${LIBS}
