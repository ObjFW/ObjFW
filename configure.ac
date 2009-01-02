AC_INIT(objfw, 0.1, js-objfw@webkeks.org)
AC_CONFIG_SRCDIR(src)

AC_CANONICAL_HOST
AC_CANONICAL_TARGET

AC_PROG_CC
AC_PROG_OBJC
AC_PROG_CPP
AC_PROG_LN_S
AC_PROG_EGREP

CFLAGS="$CFLAGS -Wall"
OBJCFLAGS="$OBJCFLAGS -Wall -fobjc-exceptions"
LIBS="$LIBS -lobjc"

AC_DEFINE(OF_CONFIG_H, 1, [Define so that we know we got our config.h])

BUILDSYS_LIB
AC_C_BIGENDIAN([AC_DEFINE(OF_BIG_ENDIAN, 1, [Whether we are big endian])])

AC_MSG_CHECKING(for SIZE_MAX)
AC_EGREP_CPP(yes, [
	#include <stdint.h>
	#include <limits.h>

	#ifdef SIZE_MAX
	yes
	#endif], AC_MSG_RESULT(yes), [
	AC_MSG_RESULT(no)
	AC_MSG_CHECKING(for SIZE_T_MAX)
	AC_EGREP_CPP(yes, [
		#include <stdint.h>
		#include <limits.h>

		#ifdef SIZE_T_MAX
		yes
		#endif], [
		AC_MSG_RESULT(yes)
		size_max="SIZE_T_MAX"], [
		AC_MSG_RESULT(no)
		size_max="((size_t)-1)"])
	AC_DEFINE_UNQUOTED(SIZE_MAX, $size_max, [Maximum value for size_t])])

AC_CHECK_FUNC(asprintf, [
	have_asprintf="yes"
	AC_DEFINE(HAVE_ASPRINTF, 1, "Whether we have asprintf")], [
	have_asprintf="no"
	AC_SUBST(ASPRINTF, "asprintf.c")])

AC_MSG_CHECKING(whether snprintf returns something useful)
AC_CACHE_VAL(ac_cv_snprintf_useful_ret, [
	AC_TRY_RUN([
		#include <stdio.h>

		int
		main()
		{
			return (snprintf(NULL, 0, "asd") == 3 ? 0 : 1);
		}],
		ac_cv_snprintf_useful_ret="yes",
		ac_cv_snprintf_useful_ret="no",
		ac_cv_snprintf_useful_ret="no")])
AC_MSG_RESULT($ac_cv_snprintf_useful_ret)

test x"$have_asprintf" != x"yes" -a x"$ac_cv_snprintf_useful_ret" != x"yes" && \
	AC_MSG_ERROR(No asprintf and no snprintf returning required space!)

ACX_PTHREAD

AC_CHECK_LIB(ws2_32, main, LIBS="$LIBS -lws2_32")

AC_MSG_CHECKING(whether we have IPv6 support)
AC_CACHE_VAL(ac_cv_have_ipv6, [
	AC_TRY_RUN([
		#include <stdlib.h>
		#include <string.h>

		#include <sys/types.h>
		#include <sys/socket.h>
		#include <netinet/in.h>

		int
		main()
		{
			int fd;
			struct sockaddr_in6 addr;

			fd = socket(AF_INET6, SOCK_STREAM, 0);

			/*
			 * Do something with it to prevent an error due to
			 * -Werror
			 */
			memset(&addr, 0, sizeof(addr));

			exit(fd >= 0 ? 0 : 1);
		}],
		ac_cv_have_ipv6="yes",
		ac_cv_have_ipv6="no",
		ac_cv_have_ipv6="no")])
AC_MSG_RESULT($ac_cv_have_ipv6)
test x"$ac_cv_have_ipv6" = x"yes" && \
	AC_DEFINE(HAVE_IPV6, 1, "Whether we have IPv6 support")

AC_CHECK_HEADERS(sys/mman.h)

test x"$GCC" = x"yes" && CFLAGS="$CFLAGS -Werror -pipe -g"
test x"$GCC" = x"yes" && OBJCFLAGS="$OBJCFLAGS -Werror -pipe -g"

if test x"$cross_compiling" = x"yes"; then
	case "$target" in
		*-*-mingw*)
			AC_PATH_PROG(WINE, wine)

			if test x"$WINE" != "x"; then
				AC_SUBST(TESTS, "tests")
				AC_SUBST(TEST_LAUNCHER, "$WINE")
			fi
			;;
	esac
else
	AC_SUBST(TESTS, "tests")
fi

BUILDSYS_TOUCH_DEPS

AC_SUBST(PACKAGE, objfw)
AC_CONFIG_FILES([buildsys.mk extra.mk])
AC_CONFIG_HEADERS(config.h)
AC_OUTPUT
