include ../buildsys.mk

DISTCLEAN = objfw-config

install-extra:
	for i in objfw-config objfw-compile; do \
		${INSTALL_STATUS}; \
		if ${MKDIR_P} ${DESTDIR}${bindir} && ${INSTALL} -m 755 $$i ${DESTDIR}${bindir}/$$i; then \
			${INSTALL_OK}; \
		else \
			${INSTALL_FAILED}; \
		fi \
	done

uninstall-extra:
	for i in objfw-config objfw-compile; do \
		if test -f ${DESTDIR}${bindir}/$$i; then \
			if rm -f ${DESTDIR}${bindir}/$$i; then \
				${DELETE_OK}; \
			else \
				${DELETE_FAILED}; \
			fi \
		fi \
	done
