include ../../extra.mk

PROG = ofhttp${PROG_SUFFIX}
SRCS = OFHTTP.m		\
       ProgressBar.m

include ../../buildsys.mk

${PROG}: ${LIBOBJFW_DEP_LVL2}

CPPFLAGS += -I../../src -I../../src/runtime -I../../src/exceptions -I../..
LIBS := -L../../src -lobjfw ${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
