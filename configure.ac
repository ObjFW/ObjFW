AC_INIT(ObjFW, 0.1, js@webkeks.org)
AC_CONFIG_SRCDIR(src)

AC_CANONICAL_HOST

AC_LANG([Objective C])
AC_PROG_OBJC
AC_PROG_OBJCPP
AC_PROG_LN_S
AC_PROG_INSTALL
AC_PROG_EGREP

CPP="$OBJCPP"
CPPFLAGS="$CPPFLAGS $OBJCPPFLAGS"
OBJCFLAGS="$OBJCFLAGS -Wall -fexceptions -fobjc-exceptions"
OBJCFLAGS="$OBJCFLAGS -fconstant-string-class=OFConstString"
LIBS="$LIBS -lobjc"

AX_CHECK_COMPILER_FLAGS(-pipe, [OBJCFLAGS="$OBJCFLAGS -pipe"])
AX_CHECK_COMPILER_FLAGS(-fno-common, [OBJCFLAGS="$OBJCFLAGS -fno-common"])
AX_CHECK_COMPILER_FLAGS(-fno-constant-cfstrings, [
	NO_CONST_CFSTRINGS="-fno-constant-cfstrings"
	OBJCFLAGS="$OBJCFLAGS -fno-constant-cfstrings"])
AC_SUBST(NO_CONST_CFSTRINGS)

AC_MSG_CHECKING(whether Objective C compiler supports fast enumeration)
AC_TRY_COMPILE([
	#import <objc/objc.h>
	], [
	id n = nil;
	for (id i in n);
	], [
	AC_DEFINE(OF_HAVE_FAST_ENUMERATION, 1,
		[Compiler support for Fast Enumeration])
	AC_MSG_RESULT(yes)
	], [
	AC_MSG_RESULT(no)])

AC_MSG_CHECKING(whether Objective C compiler supports properties)
AC_TRY_COMPILE([
	#import <objc/objc.h>

	@interface Foo
	{
		id bar;
	}

	@property (retain, nonatomic) id bar;
	@end
	], [
	Foo *foo = nil;
	[foo setBar: nil];
	[foo bar];
	], [
	AC_DEFINE(OF_HAVE_PROPERTIES, 1, [Compiler support for properties])
	AC_SUBST(PROPERTIES_M, "properties.m")
	AC_MSG_RESULT(yes)
	], [
	AC_MSG_RESULT(no)])

AC_MSG_CHECKING(which Objective C runtime we use)
dnl TODO: This is ugly. Let's think of a better check.
AC_EGREP_CPP(gnu, [
	#import <objc/objc.h>
	#ifdef __objc_INCLUDE_GNU
	gnu
	#endif
	], [
	AC_DEFINE(OF_GNU_RUNTIME, 1, [Whether we use the GNU ObjC runtime])
	AC_SUBST(RUNTIME_DEF, "-DOF_GNU_RUNTIME")
	objc_runtime="GNU"
	], [
	AC_DEFINE(OF_APPLE_RUNTIME, 1, [Whether we use the Apple ObjC runtime])
	AC_SUBST(RUNTIME_DEF, "-DOF_APPLE_RUNTIME")
	objc_runtime="Apple"])
AC_MSG_RESULT($objc_runtime)

AC_CHECK_FUNC(objc_getProperty,, [
	AC_SUBST(OBJC_PROPERTIES_M, "objc_properties.m")])

AC_CHECK_FUNC(objc_enumerationMutation, [
	AC_DEFINE(HAVE_OBJC_ENUMERATIONMUTATION, 1,
		[Whether we have objc_enumerationMutation])])

BUILDSYS_LIB
AC_DEFINE_UNQUOTED(PLUGIN_SUFFIX, "$PLUGIN_SUFFIX", [Suffix for plugins])
if test x"$PLUGIN_SUFFIX" != "x"; then
	AC_SUBST(OFPLUGIN_M, "OFPlugin.m")
	AC_SUBST(TESTPLUGIN, "plugin")
	AC_DEFINE(OF_PLUGINS, 1, [Whether we have plugin support])
	AC_SUBST(OFPLUGINS_DEF, "-DOF_PLUGINS")
fi

AC_C_BIGENDIAN([
	AC_DEFINE(OF_BIG_ENDIAN, 1, [Whether we are big endian])
	AC_SUBST(ENDIANESS_DEF, "-DOF_BIG_ENDIAN")])

AC_MSG_CHECKING(for SIZE_MAX)
AC_EGREP_CPP(yes, [
	#include <stdint.h>
	#include <limits.h>

	#ifdef SIZE_MAX
	yes
	#endif
	], AC_MSG_RESULT(yes), [
	AC_MSG_RESULT(no)
	AC_MSG_CHECKING(for SIZE_T_MAX)
	AC_EGREP_CPP(yes, [
		#include <stdint.h>
		#include <limits.h>

		#ifdef SIZE_T_MAX
		yes
		#endif
		], [
		AC_MSG_RESULT(yes)
		size_max="SIZE_T_MAX"], [
		AC_MSG_RESULT(no)
		size_max="((size_t)-1)"])
	AC_DEFINE_UNQUOTED(SIZE_MAX, $size_max, [Maximum value for size_t])])

AC_CHECK_FUNC(asprintf, [
	have_asprintf="yes"
	AC_DEFINE(OF_HAVE_ASPRINTF, 1, [Whether we have asprintf])
	AC_SUBST(ASPRINTF_DEF, "-DOF_HAVE_ASPRINTF")
	], [
	have_asprintf="no"
	AC_SUBST(ASPRINTF_M, "asprintf.m")

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
		AC_MSG_RESULT($ac_cv_snprintf_useful_ret)])
test x"$have_asprintf" != x"yes" -a x"$ac_cv_snprintf_useful_ret" != x"yes" && \
	AC_MSG_ERROR(No asprintf and no snprintf returning required space!)

AC_CHECK_LIB(dl, dlopen, LIBS="$LIBS -ldl")

AC_ARG_ENABLE(threads,
	AS_HELP_STRING([--disable-threads], [disable thread support]))
if test x"$enable_threads" != x"no"; then
	case "$host_os" in
		mingw*)
			AC_MSG_CHECKING(for threads)
			AC_MSG_RESULT(win32)
			;;
		*)
			ACX_PTHREAD([
				CPPLAGS="$CPPFLAGS $PTHREAD_CFLAGS"
				LIBS="$LIBS $PTHREAD_LIBS"
				AC_DEFINE(OF_HAVE_PTHREADS, 1,
					[Whether we have pthreads])
				], [
				AC_MSG_ERROR(No supported threads found!)])
			;;
	esac

	AC_DEFINE(OF_THREADS, 1, [Whether we have threads])
	AC_SUBST(OFTHREAD_M, "OFThread.m")
	AC_SUBST(THREADING_H, "threading.h")

	AC_CHECK_FUNC(objc_sync_enter,, [
		AC_SUBST(OBJC_SYNC_M, "objc_sync.m")
		AC_DEFINE(NEED_OBJC_SYNC_INIT, 1,
			[Whether objc_sync_init needs to be called])])

	AC_TRY_LINK([#include <stdint.h>], [
		int32_t i, j;
		if (__sync_add_and_fetch(&i, 1))
			j = __sync_sub_and_fetch(&i, 1);
		while (!__sync_bool_compare_and_swap(&i, 0, 1));
		], [
		have_gcc_atomic_ops="yes"
		AC_DEFINE(OF_HAVE_GCC_ATOMIC_OPS, 1,
			[Whether gcc atomic operations are available])
		], [
		old_OBJCFLAGS="$OBJCFLAGS"
		OBJCFLAGS="$OBJCFLAGS -march=i486"
		AC_TRY_LINK([#include <stdint.h>], [
			int32_t i, j;
			if (__sync_add_and_fetch(&i, 1))
				j = __sync_sub_and_fetch(&i, 1);
			while (!__sync_bool_compare_and_swap(&i, 0, 1));
			], [
			have_gcc_atomic_ops="yes"
			AC_DEFINE(OF_HAVE_GCC_ATOMIC_OPS, 1,
				[Whether gcc atomic operations are available])
			], [
			have_gcc_atomic_ops="no"
			OBJCFLAGS="$old_OBJCFLAGS"])])

	if test x"$have_gcc_atomic_ops" != x"yes"; then
		AC_CHECK_HEADER(libkern/OSAtomic.h, [
			have_libkern_osatomic_h="yes"
			AC_DEFINE(OF_HAVE_LIBKERN_OSATOMIC_H, 1,
				[Whether we have libkern/OSAtomic.h])])
	fi

	AC_MSG_CHECKING(for atomic operations)
	if test x"$have_gcc_atomic_ops" = x"yes"; then
		AC_MSG_RESULT(gcc builtins)
	elif test x"$have_libkern_osatomic_h" = x"yes"; then
		AC_MSG_RESULT(libkern/OSAtomic.h)
	else
		AC_MSG_RESULT(none)
		AC_MSG_ERROR(No atomic operations found! Try --disable-threads.)
	fi
fi

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
	#endif
	], [
	struct addrinfo ai;
	getaddrinfo(NULL, NULL, NULL, NULL);
	], [
	AC_MSG_RESULT(yes)
	AC_DEFINE(HAVE_GETADDRINFO, 1, [Whether we have getaddrinfo])

	if test x"$enable_threads" != x"no"; then
		AC_MSG_CHECKING(whether getaddrinfo is thread-safe)

		case "$host_os" in
			darwin[[12345]].*)
				have_threadsafe_getaddrinfo="no"
				;;
			darwin*)
				have_threadsafe_getaddrinfo="yes"
				;;
			freebsd[[1234]].* | freebsd5.[[1234]]*)
				have_threadsafe_getaddrinfo="no"
				;;
			freebsd*)
				have_threadsafe_getaddrinfo="yes"
				;;
			netbsd[[123]].*)
				have_threadsafe_getaddrinfo="no"
				;;
			netbsd*)
				have_threadsafe_getaddrinfo="yes"
				;;
			solaris*)
				have_threadsafe_getaddrinfo="yes"
				;;
			*)
				have_threadsafe_getaddrinfo="unknown"
				;;
		esac

		if test x"$have_threadsafe_getaddrinfo" = x"unknown"; then
			AC_EGREP_CPP(yes, [
				#include <netdb.h>
				#ifdef h_errno
				yes
				#end
				],
				[have_threadsafe_getaddrinfo="yes"],
				[have_threadsafe_getaddrinfo="no"])
		fi

		test x"$have_threadsafe_getaddrinfo" = x"yes" && \
			AC_DEFINE(HAVE_THREADSAFE_GETADDRINFO, 1,
				[Whether getaddrinfo is thread-safe])

		AC_MSG_RESULT($have_threadsafe_getaddrinfo)
	fi
	], [
	AC_MSG_RESULT(no)])

AC_CHECK_FUNC(madvise, [AC_DEFINE(HAVE_MADVISE, 1, [Whether we have madvise])])

if test x"$GOBJC" = x"yes"; then
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
		AC_MSG_RESULT([yes, adding -Wno-unused-variable])
		OBJCFLAGS="$OBJCFLAGS -Wno-unused-variable"
		AC_SUBST(NO_WARN_UNUSED, "-Wno-unused-variable")])

	AC_MSG_CHECKING(whether we need -Wno-strict-aliasing due to gcc bugs)
	AC_TRY_COMPILE([
		#import <objc/objc.h>

		@interface OFObject
		{
			Class isa;
		}
		@end

		static struct {
			Class isa;
		} object;
		], [
		OFObject *test = (OFObject*)&object;
		test++; /* Get rid of unused variable warning */
		], [AC_MSG_RESULT(no)], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$OBJCFLAGS -Wno-strict-aliasing"])
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

dnl We don't call AC_PROG_CPP, but only AC_PROG_OBJCPP and set CPP to OBJCPP
dnl and add OBJCPPFLAGS to CPPFLAGS, thus we need to AC_SUBST these ourself
AC_SUBST(CPP)
AC_SUBST(CPPFLAGS)

AC_SUBST(PACKAGE, ObjFW)
AC_CONFIG_FILES([buildsys.mk extra.mk objfw-config])
AC_CONFIG_HEADERS([config.h src/objfw-defs.h])
AC_OUTPUT
