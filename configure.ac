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
AC_C_BIGENDIAN([AC_DEFINE(OF_BIG_ENDIAN, 1, [Whether we are big endian])])

AC_CHECK_HEADER(objc/runtime.h,
	[AC_DEFINE(HAVE_OBJC_RUNTIME_H, 1, [Whether we have objc/runtime.h])])

AC_CHECK_LIB(objc, sel_get_name, [
	have_sel_get_name="yes"
	AC_DEFINE(HAVE_SEL_GET_NAME, 1, [Whether we have sel_get_name])])
AC_CHECK_LIB(objc, sel_getName, [
	have_sel_getName="yes"
	AC_DEFINE(HAVE_SEL_GETNAME, 1, [Whether we have sel_getName])])
test x"$have_sel_get_name" != x"yes" -a x"$have_sel_getName" != x"yes" && \
	AC_ERROR(You need either sel_get_name or sel_getName in libobjc!)

test $cross_compiling != x"yes" && AC_SUBST(TESTS, "tests")

AC_SUBST(PACKAGE, objfw)
AC_CONFIG_FILES([buildsys.mk extra.mk])
AC_CONFIG_HEADERS(config.h)
AC_OUTPUT
