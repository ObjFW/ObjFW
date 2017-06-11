PLUGIN_NOINST = TestPlugin${PLUGIN_SUFFIX}
SRCS = TestPlugin.m

include ../../buildsys.mk
include ../../extra.mk

CPPFLAGS += -I../.. -I../../src -I../../src/runtime
LIBS := -L../../src -lobjfw -L../../src/runtime ${RUNTIME_LIBS} ${LIBS}
LD = ${OBJC}
