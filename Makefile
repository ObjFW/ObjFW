include extra.mk

SUBDIRS = src ${TESTS}
DISTCLEAN = aclocal.m4		\
	    autom4te.cache	\
	    buildsys.mk		\
	    config.h		\
	    config.log		\
	    config.status	\
	    extra.mk		\
	    objfw-config

include buildsys.mk

install-extra:
	for i in objfw-config; do \
		${INSTALL_STATUS}; \
		if ${MKDIR_P} ${DESTDIR}${bindir} && ${INSTALL} -m 755 $$i ${DESTDIR}${bindir}/$$i; then \
			${INSTALL_OK}; \
		else \
			${INSTALL_FAILED}; \
		fi \
	done

uninstall-extra:
	for i in objfw-config; do \
		if test -f ${DESTDIR}${bindir}/$$i; then \
			if rm -f ${DESTDIR}${bindir}/$$i; then \
				${DELETE_OK}; \
			else \
				${DELETE_FAILED}; \
			fi \
		fi \
	done

tarball:
	V=$$(fgrep VERSION= objfw-config.in | sed 's/VERSION="\(.*\)"/\1/'); \
	V2=$$(fgrep AC_INIT configure.ac | \
	      sed 's/AC_INIT([^,]*,\([^,]*\),.*/\1/' | sed 's/ //'); \
	if test x"$$V" != x"$$V2"; then \
		echo "objfw-config.h.in and configure.ac version mismatch!"; \
		exit 1; \
	fi; \
	echo "Generating tarball for version $$V..."; \
	rm -f objfw-$$V.tar.gz; \
	rm -fr objfw-$$V; \
	hg archive objfw-$$V; \
	cp configure config.h.in objfw-$$V; \
	cd objfw-$$V && rm -f .hg_archival.txt .hgignore .hgtags && cd ..; \
	tar cf objfw-$$V.tar objfw-$$V; \
	gzip -9 objfw-$$V.tar; \
	rm -fr objfw-$$V
