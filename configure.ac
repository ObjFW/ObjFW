AC_INIT(objfw, 0.1, js-objfw@webkeks.org)
AC_CONFIG_SRCDIR(src)

AC_CANONICAL_HOST
AC_CANONICAL_TARGET

AC_PROG_CC
AC_PROG_OBJC
AC_PROG_CPP
AC_PROG_LN_S
AC_PATH_PROG(AR, ar)

CFLAGS="$CFLAGS -Wall"
OBJCFLAGS="$OBJCFLAGS -Wall -fobjc-exceptions"

BUILDSYS_SHARED_LIB

AC_DEFINE(OF_CONFIG_H, 1, [Define so that we know we got our config.h])
AC_C_BIGENDIAN([AC_DEFINE(OF_BIG_ENDIAN, 1, [Whether we are big endian])])

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

test x"$GCC" = x"yes" && CFLAGS="$CFLAGS -Werror -pipe -g"
test x"$GCC" = x"yes" && OBJCFLAGS="$OBJCFLAGS -Werror -pipe -g"
test x"$cross_compiling" != x"yes" && AC_SUBST(TESTS, "tests")

BUILDSYS_TOUCH_DEPS

AC_SUBST(PACKAGE, objfw)
AC_CONFIG_FILES([buildsys.mk extra.mk])
AC_CONFIG_HEADERS(config.h)
AC_OUTPUT
