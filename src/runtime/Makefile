include ../../extra.mk

SUBDIRS = lookup-asm
SUBDIRS_AFTER = ${LINKLIB}
CLEAN = amiga-library-functable.inc inline.h
DISTCLEAN = Info.plist

SHARED_LIB = ${OBJFWRT_SHARED_LIB}
STATIC_LIB = ${OBJFWRT_STATIC_LIB}
FRAMEWORK = ${OBJFWRT_FRAMEWORK}
AMIGA_LIB = ${OBJFWRT_AMIGA_LIB}
LIB_MAJOR = ${OBJFWRT_LIB_MAJOR}
LIB_MINOR = ${OBJFWRT_LIB_MINOR}

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
       ${USE_SRCS_THREADS}
SRCS_THREADS = mutex.m		\
	       once.m		\
	       threading.m	\
	       tlskey.m
INCLUDES = ObjFWRT.h
includesubdir = ObjFWRT

OBJS_EXTRA = lookup-asm/lookup-asm.a
LIB_OBJS_EXTRA = lookup-asm/lookup-asm.lib.a
AMIGA_LIB_OBJS_START = amiga-library.amigalib.o
AMIGA_LIB_OBJS_EXTRA = amiga-glue.amigalib.o		\
		       lookup-asm/lookup-asm.amigalib.a	\
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
