PROG = objfw-unzip
SRCS = objfw-unzip.m

include ../buildsys.mk

DISTCLEAN = objfw-config

install-extra: objfw-config objfw-compile
	for i in objfw-config objfw-compile; do \
		${INSTALL_STATUS}; \
		if ${MKDIR_P} ${DESTDIR}${bindir} && ${INSTALL} -m 755 $$i ${DESTDIR}${bindir}/${BIN_PREFIX}$$i; then \
			${INSTALL_OK}; \
		else \
			${INSTALL_FAILED}; \
		fi \
	done

uninstall-extra:
	for i in objfw-config objfw-compile; do \
		if test -f ${DESTDIR}${bindir}/${BIN_PREFIX}$$i; then \
			if rm -f ${DESTDIR}${bindir}/${BIN_PREFIX}$$i; then \
				${DELETE_OK}; \
			else \
				${DELETE_FAILED}; \
			fi \
		fi \
	done

CPPFLAGS += -I../src -I../src/runtime -I..
LIBS := -L../src -lobjfw ${LIBS}
LD = ${OBJC}
LDFLAGS += ${LDFLAGS_RPATH}
