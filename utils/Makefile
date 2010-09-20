include ../buildsys.mk
include ../extra.mk

DISTCLEAN = objfw-config

${BIN_PREFIX}objfw-config:
	cp objfw-config ${BIN_PREFIX}objfw-config

${BIN_PREFIX}objfw-compile:
	cp objfw-compile ${BIN_PREFIX}objfw-compile

install-extra: ${BIN_PREFIX}objfw-config ${BIN_PREFIX}objfw-compile
	for i in ${BIN_PREFIX}objfw-config ${BIN_PREFIX}objfw-compile; do \
		${INSTALL_STATUS}; \
		if ${MKDIR_P} ${DESTDIR}${bindir} && ${INSTALL} -m 755 $$i ${DESTDIR}${bindir}/$$i; then \
			${INSTALL_OK}; \
		else \
			${INSTALL_FAILED}; \
		fi \
	done

uninstall-extra:
	for i in ${BIN_PREFIX}objfw-config ${BIN_PREFIX}objfw-compile; do \
		if test -f ${DESTDIR}${bindir}/$$i; then \
			if rm -f ${DESTDIR}${bindir}/$$i; then \
				${DELETE_OK}; \
			else \
				${DELETE_FAILED}; \
			fi \
		fi \
	done
