PLUGIN_NOINST = TestPlugin${PLUGIN_SUFFIX}
SRCS = TestPlugin.m

include ../../buildsys.mk
include ../../extra.mk

CPPFLAGS += ${PLUGIN_CPPFLAGS} -I../.. -I../../src
OBJCFLAGS += ${PLUGIN_CFLAGS}
LIBS := -L../../src -lobjfw ${LIBS}
