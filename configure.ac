AC_INIT(objfw, 0.1, js-objfw@webkeks.org)
AC_CONFIG_SRCDIR(src)

AC_CANONICAL_HOST
AC_CANONICAL_TARGET

AC_PROG_OBJC
AC_PROG_CPP
AC_PROG_LN_S
AC_PATH_PROG(AR, ar)

case "$CC" in
	gcc | *-gcc | gcc-* | *-gcc-*)
		OBJCFLAGS="$OBJSFLAGS -Wall -Werror -pipe -g"
		;;
esac

OBJCFLAGS="$OBJCFLAGS -fobjc-exceptions"

BUILDSYS_SHARED_LIB

AC_CHECK_HEADER(objc/runtime.h,
	[AC_DEFINE(HAVE_OBJC_RUNTIME_H, 1, [Whether we have objc/runtime.h])])
AC_CHECK_LIB(objc, sel_get_name,
	[AC_DEFINE(HAVE_SEL_GET_NAME, 1, [Whether we have sel_get_name])])
AC_CHECK_LIB(objc, sel_getName,
	[AC_DEFINE(HAVE_SEL_GETNAME, 1, [Whether we have sel_getName])])

test x"$have_sel_name" = x"no" -a x"$have_selname" = x"no" && \
	AC_ERROR(You need either sel_get_name or sel_getName in libobjc!)

AC_SUBST(PACKAGE, objfw)
AC_CONFIG_FILES(buildsys.mk)
AC_CONFIG_HEADERS(config.h)
AC_OUTPUT
