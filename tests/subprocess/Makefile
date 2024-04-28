PROG_NOINST = subprocess${PROG_SUFFIX}
SRCS = Subprocess.m

include ../../buildsys.mk
include ../../extra.mk

CPPFLAGS += -I../../src -I../../src/exceptions -I../../src/runtime -I../..
LIBS := -L../../src -lobjfw -L../../src/runtime ${RUNTIME_LIBS} ${LIBS}
LD = ${OBJC}
