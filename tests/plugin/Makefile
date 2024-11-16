include ../../extra.mk

DISTCLEAN = Info.plist

PLUGIN_NOINST = ${TESTPLUGIN_PLUGIN}
BUNDLE_NOINST = ${TESTPLUGIN_BUNDLE}
SRCS = TestPlugin.m

include ../../buildsys.mk

CPPFLAGS += -I../.. -I../../src -I../../src/runtime
LIBS := ${TESTPLUGIN_LIBS} ${LIBS}
LD = ${OBJC}
