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
test x"$GCC" = x"yes" && CFLAGS="$CFLAGS -Werror -pipe -g"

OBJCFLAGS="$OBJCFLAGS -Wall"
test x"$GCC" = x"yes" && OBJCFLAGS="$OBJCFLAGS -Werror -pipe -g"
OBJCFLAGS="$OBJCFLAGS -fobjc-exceptions"

BUILDSYS_SHARED_LIB

AC_DEFINE(OF_CONFIG_H, 1, [Define so that we know we got our config.h])
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

AC_CHECK_FUNC(asprintf, AC_DEFINE(HAVE_ASPRINTF, 1, "Whether we have asprintf"))

AC_MSG_CHECKING(whether we have IPv6 support)
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

		/* Do something with it to prevent an error due to -Werror */
		memset(&addr, 0, sizeof(addr));

		exit(fd >= 0 ? 0 : 1);
	}],
	have_ipv6="yes", have_ipv6="no", have_ipv6="no")
AC_MSG_RESULT($have_ipv6)
test x"$have_ipv6" = x"yes" && \
	AC_DEFINE(HAVE_IPV6, 1, "Whether we have IPv6 support")

test x"$cross_compiling" != x"yes" && AC_SUBST(TESTS, "tests")

BUILDSYS_TOUCH_DEPS

AC_SUBST(PACKAGE, objfw)
AC_CONFIG_FILES([buildsys.mk extra.mk])
AC_CONFIG_HEADERS(config.h)
AC_OUTPUT
