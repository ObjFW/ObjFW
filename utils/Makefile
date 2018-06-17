include ../extra.mk

SUBDIRS += ${OFARC}	\
	   ${OFHASH}	\
	   ${OFHTTP}

include ../buildsys.mk

DISTCLEAN = objfw-config

install-extra: objfw-config objfw-compile objfw-new
	for i in objfw-config objfw-compile objfw-new; do \
		${INSTALL_STATUS}; \
		if ${MKDIR_P} ${DESTDIR}${bindir} && ${INSTALL} -m 755 $$i ${DESTDIR}${bindir}/${BIN_PREFIX}$$i; then \
			${INSTALL_OK}; \
		else \
			${INSTALL_FAILED}; \
		fi \
	done

uninstall-extra:
	for i in objfw-config objfw-compile objfw-new; do \
		if test -f ${DESTDIR}${bindir}/${BIN_PREFIX}$$i; then \
			if rm -f ${DESTDIR}${bindir}/${BIN_PREFIX}$$i; then \
				${DELETE_OK}; \
			else \
				${DELETE_FAILED}; \
			fi \
		fi \
	done
