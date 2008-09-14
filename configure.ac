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
		OBJCFLAGS="$OBJSFLAGS -Wall -Werror -pipe"
		;;
esac

OBJCFLAGS="$OBJCFLAGS -fconstant-string-class=OFConstString -fobjc-exceptions"

BUILDSYS_SHARED_LIB

AC_SUBST(PACKAGE, objfw)
AC_CONFIG_FILES(buildsys.mk)
AC_OUTPUT
