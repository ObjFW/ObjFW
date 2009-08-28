AC_INIT(objfw, 0.1, js@webkeks.org)
AC_CONFIG_SRCDIR(src)

AC_CANONICAL_HOST

AC_PROG_CC
AC_PROG_CPP
AC_PROG_LN_S
AC_PROG_INSTALL
AC_PROG_EGREP

CFLAGS="$CFLAGS -Wall"
AX_CHECK_COMPILER_FLAGS(-pipe, [CFLAGS="$CFLAGS -pipe"])
AX_CHECK_COMPILER_FLAGS(-fno-common, [CFLAGS="$CFLAGS -fno-common"])

AC_DEFINE(OF_CONFIGURED, 1, [Define so that we know we got our config.h])

BUILDSYS_LIB
AC_DEFINE_UNQUOTED(PLUGIN_SUFFIX, "$PLUGIN_SUFFIX", [Suffix for plugins])
if test x"$PLUGIN_SUFFIX" != "x"; then
	AC_SUBST(OFPLUGIN_M, "OFPlugin.m")
	AC_SUBST(OFPLUGIN, "OFPlugin")
	AC_SUBST(OFPLUGIN_DEF, "-DOF_PLUGINS")
fi

AC_C_BIGENDIAN([
	AC_DEFINE(OF_BIG_ENDIAN, 1, [Whether we are big endian])
	AC_SUBST(ENDIANESS_DEF, "-DOF_BIG_ENDIAN")
	])

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

AC_CHECK_LIB(dl, dlopen, LIBS="$LIBS -ldl")

AC_CHECK_FUNC(asprintf, [
	have_asprintf="yes"
	AC_DEFINE(OF_HAVE_ASPRINTF, 1, [Whether we have asprintf])
	AC_SUBST(ASPRINTF_DEF, "-DOF_HAVE_ASPRINTF")
	], [
	have_asprintf="no"
	AC_SUBST(ASPRINTF_C, "asprintf.c")])

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

case "$host" in
	*-*-mingw*)
		AC_MSG_CHECKING(for threads)
		AC_MSG_RESULT(win32)
		;;
	*)
		ACX_PTHREAD([
			CPPLAGS="$CPPFLAGS $PTHREAD_CFLAGS"
			LIBS="$LIBS $PTHREAD_LIBS"
			], [
			AC_MSG_ERROR(No pthreads or other supported threads!)])
		;;
esac

AC_CHECK_LIB(socket, socket, LIBS="$LIBS -lsocket")
AC_CHECK_LIB(ws2_32, main, LIBS="$LIBS -lws2_32")

AC_MSG_CHECKING(for getaddrinfo)
AC_TRY_COMPILE([
	#include <stddef.h>
	#ifndef _WIN32
	#include <sys/types.h>
	#include <sys/socket.h>
	#include <netdb.h>
	#else
	#define _WIN32_WINNT 0x0501
	#include <ws2tcpip.h>
	#endif], [
	struct addrinfo ai;
	getaddrinfo(NULL, NULL, NULL, NULL);
	], [have_getaddrinfo="yes"], [have_getaddrinfo="no"])
AC_MSG_RESULT($have_getaddrinfo)
test x"$have_getaddrinfo" = x"yes" && \
	AC_DEFINE(HAVE_GETADDRINFO, 1, [Whether we have getaddrinfo])

AC_MSG_CHECKING(whether we have IPv6 support)
AS_IF([test x"$have_getaddrinfo" = x"yes"], [
	AC_CACHE_VAL(ac_cv_have_ipv6, [
		AC_TRY_RUN([
			#ifndef _WIN32
			#include <sys/types.h>
			#include <sys/socket.h>
			#include <netinet/in.h>
			#else
			#include <winsock2.h>
			#include <ws2tcpip.h>
			#endif

			#ifndef INVALID_SOCKET
			#define INVALID_SOCKET -1
			#endif

			int
			main()
			{
				int fd;
				struct sockaddr_in6 addr;

				fd = socket(AF_INET6, SOCK_STREAM, 0);

				exit(fd != INVALID_SOCKET ? 0 : 1);
			}],
			ac_cv_have_ipv6="yes",
			ac_cv_have_ipv6="no",
			ac_cv_have_ipv6="no")])], [ac_cv_have_ipv6="no"])
AC_MSG_RESULT($ac_cv_have_ipv6)
test x"$ac_cv_have_ipv6" = x"yes" && \
	AC_DEFINE(HAVE_IPV6, 1, "Whether we have IPv6 support")

AC_CHECK_FUNC(madvise, [AC_DEFINE(HAVE_MADVISE, 1, [Whether we have madvise])])

AC_LANG([Objective C])
AC_PROG_OBJC

OBJCFLAGS="$OBJCFLAGS -Wall -fobjc-exceptions"
OBJCFLAGS="$OBJCFLAGS -fconstant-string-class=OFConstString"
LIBS="$LIBS -lobjc"

AX_CHECK_COMPILER_FLAGS(-pipe, [OBJCFLAGS="$OBJCFLAGS -pipe"])
AX_CHECK_COMPILER_FLAGS(-fno-common, [OBJCFLAGS="$OBJCFLAGS -fno-common"])
AX_CHECK_COMPILER_FLAGS(-fno-constant-cfstrings, [
	NO_CONST_CFSTRINGS="-fno-constant-cfstrings"
	OBJCFLAGS="$OBJCFLAGS -fno-constant-cfstrings"])
AC_SUBST(NO_CONST_CFSTRINGS)

AC_CHECK_HEADER(objc/runtime.h,
	[AC_DEFINE(HAVE_OBJC_RUNTIME_H, 1, [Whether we have objc/runtime.h])])

AC_CHECK_FUNC(objc_sync_enter,, [
	AC_SUBST(OBJC_SYNC, "objc_sync")
	AC_SUBST(OBJC_SYNC_M, "objc_sync.m")
	AC_DEFINE(NEED_OBJC_SYNC_INIT, 1,
		[Whether objc_sync_init needs to be called])])

test x"$GCC" = x"yes" && CFLAGS="$CFLAGS -Werror"
if test x"$GOBJC" = x"yes"; then
	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Werror"

	AC_MSG_CHECKING(whether gcc has bug objc/27438)
	AC_TRY_COMPILE([
		#import <objc/objc.h>

		@interface OFConstString
		{
			Class isa;
			const char *string;
			unsigned long size;
		}
		@end

		void *_OFConstStringClassReference;
		], [
		OFConstString *test = @"";
		test++; /* Get rid of unused variable warning */
		], [AC_MSG_RESULT(no)], [
		AC_MSG_RESULT([yes, disabling -Werror])
		OBJCFLAGS="$old_OBJCFLAGS"])
fi

if test x"$cross_compiling" = x"yes"; then
	case "$host" in
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
AC_CONFIG_FILES([buildsys.mk extra.mk objfw-config])
AC_CONFIG_HEADERS(config.h)
AC_OUTPUT
