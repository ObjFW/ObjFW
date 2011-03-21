AC_INIT(ObjFW, 0.4-dev, js@webkeks.org)
AC_CONFIG_SRCDIR(src)

AS_IF([test x"$host" = x"psp"], [
	OBJCFLAGS="-G0 $OBJCFLAGS"
	LIBS="$LIBS -lpspdebug -lpspdisplay -lpspge -lpspctrl -lpspsdk -lc"
	LIBS="$LIBS -lpspnet -lpspnet_inet -lpspnet_apctl -lpspnet_resolver"
	LIBS="$LIBS -lpsputility -lpspuser -lpspkernel"
])

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
OBJCFLAGS="$OBJCFLAGS -fconstant-string-class=OFConstantString"

AX_CHECK_COMPILER_FLAGS(-pipe, [OBJCFLAGS="$OBJCFLAGS -pipe"])
AX_CHECK_COMPILER_FLAGS(-fno-common, [OBJCFLAGS="$OBJCFLAGS -fno-common"])
AX_CHECK_COMPILER_FLAGS(-fno-constant-cfstrings, [
	NO_CONST_CFSTRINGS="-fno-constant-cfstrings"
	OBJCFLAGS="$OBJCFLAGS -fno-constant-cfstrings"
])
AC_SUBST(NO_CONST_CFSTRINGS)

AC_MSG_CHECKING(whether Objective C compiler supports fast enumeration)
AC_TRY_COMPILE([
	@protocol OFFastEnumeration
	- (int)countByEnumeratingWithState: (void*)state
				   objects: (struct objc_object**)objects
				     count: (int)count;
	@end
], [
	struct objc_object *n = (struct objc_object*)0;
	for (struct objc_object *i in n);
], [
	AC_DEFINE(OF_HAVE_FAST_ENUMERATION, 1,
		[Compiler support for Fast Enumeration])
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
])

AC_MSG_CHECKING(whether Objective C compiler supports properties)
AC_TRY_COMPILE([
	@interface Foo
	{
		id bar;
	}

	@property (retain, nonatomic) struct objc_object *bar;
	@end
], [
	Foo *foo = (struct objc_object*)0;
	[foo setBar: (struct objc_object*)0];
	[foo bar];
], [
	AC_DEFINE(OF_HAVE_PROPERTIES, 1, [Compiler support for properties])
	AC_SUBST(PROPERTIESTESTS_M, "PropertiesTests.m")
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
])

AC_MSG_CHECKING(whether Objective C compiler supports blocks)
old_OBJCFLAGS="$OBJCFLAGS"
OBJCFLAGS="$OBJCFLAGS -fblocks"
AC_TRY_COMPILE([], [
	int (^foo)(int bar);
	foo = ^(int bar) { return 0; }
], [
	AC_DEFINE(OF_HAVE_BLOCKS, 1, [Compiler support for blocks])
	AC_SUBST(BLOCKS_FLAGS, "-fblocks")
	AC_SUBST(OFBLOCKTESTS_M, "OFBlockTests.m")
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
	OBJCFLAGS="$old_OBJCFLAGS"
])

AC_CHECK_HEADERS([objfw-rt.h objc/objc.h])

test x"$ac_cv_header_objfw_rt_h" = x"yes" && objc_runtime="ObjFW-RT"

AS_IF([test x"$ac_cv_header_objc_objc_h" = x"yes"], [
	AC_EGREP_CPP(yes, [
		#import <objc/objc.h>
		#ifdef __GNU_LIBOBJC__
		yes
		#endif
	], [
		test x"$objc_runtime" = "x" && objc_runtime="GNU"
	], [
		dnl TODO: This is ugly. Let's think of a better check.
		AC_EGREP_CPP(yes, [
			#import <objc/objc.h>
			#ifdef __objc_INCLUDE_GNU
			yes
			#endif
		], [
			test x"$objc_runtime" = "x" && objc_runtime="old GNU"
		], [
			objc_runtime="Apple"
		])
	])
])

AC_MSG_CHECKING(which Objective C runtime we use)
case $objc_runtime in
	ObjFW-RT)
		AC_DEFINE(OF_OBJFW_RUNTIME, 1,
			[Whether we use the ObjFW runtime])
		AC_SUBST(GNU_RUNTIME, "-fgnu-runtime")
		OBJCFLAGS="$OBJCFLAGS -fgnu-runtime"
		LIBS="-lobjfw-rt $LIBS"
		;;
	Apple)
		AC_DEFINE(OF_APPLE_RUNTIME, 1,
			[Whether we use the Apple ObjC runtime])
		LIBS="-lobjc $LIBS"
		;;
	GNU)
		AC_DEFINE(OF_GNU_RUNTIME, 1,
			[Whether we use the GNU ObjC runtime])
		LIBS="-lobjc $LIBS"
		;;
	"old GNU")
		AC_DEFINE(OF_OLD_GNU_RUNTIME, 1,
			[Whether we use the old GNU ObjC runtime])
		LIBS="-lobjc $LIBS"
		;;
	*)
		AC_MSG_RESULT(none)
		AC_MSG_ERROR(No ObjC runtime found! Please install ObjFW-RT!)
		;;
esac
AC_MSG_RESULT($objc_runtime)

AC_CHECK_FUNC(objc_getProperty,, [
	AC_DEFINE(NEED_OBJC_PROPERTIES_INIT, 1,
		[Whether objc_properties_init needs to be called])
	AC_SUBST(OBJC_PROPERTIES_M, "objc_properties.m")
])

AC_CHECK_FUNC(objc_enumerationMutation, [
	AC_DEFINE(HAVE_OBJC_ENUMERATIONMUTATION, 1,
		[Whether we have objc_enumerationMutation])
])

AC_ARG_ENABLE(shared,
	AS_HELP_STRING([--disable-shared], [don't build shared library]))
AS_IF([test x"$enable_shared" != x"no"], [
	BUILDSYS_SHARED_LIB
	AC_SUBST(OBJFW_SHARED_LIB, "${LIB_PREFIX}objfw${LIB_SUFFIX}")
])
AC_ARG_ENABLE(static, AS_HELP_STRING([--enable-static], [build static library]))
AS_IF([test x"$enable_static" = x"yes" -o x"$enable_shared" = x"no"], [
	AC_REQUIRE([AC_PROG_RANLIB])
	AC_PATH_TOOL(AR, ar)
	AC_SUBST(OBJFW_STATIC_LIB, "libobjfw.a")
])

AC_DEFINE_UNQUOTED(PLUGIN_SUFFIX, "$PLUGIN_SUFFIX", [Suffix for plugins])
AS_IF([test x"$PLUGIN_SUFFIX" != "x"], [
	AC_SUBST(OFPLUGIN_M, "OFPlugin.m")
	AC_SUBST(OFPLUGINTESTS_M, "OFPluginTests.m")
	AC_SUBST(TESTPLUGIN, "plugin")
	AC_DEFINE(OF_PLUGINS, 1, [Whether we have plugin support])
	AC_SUBST(OFPLUGINS_DEF, "-DOF_PLUGINS")
])

case "$host_os" in
	darwin*)
		AC_SUBST(REEXPORT_LIBOBJC, [-Wl,-reexport-lobjc])
		AC_SUBST(LDFLAGS_REEXPORT, [-Wl,-reexport-lobjfw])
		AC_SUBST(MACH_ALIAS_LIST, [-Wl,-alias_list,mach_alias_list])
		;;
esac

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
	#endif
], [
	AC_MSG_RESULT(yes)
], [
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
		size_max="(~(size_t)0)"
	])
	AC_DEFINE_UNQUOTED(SIZE_MAX, $size_max, [Maximum value for size_t])
])

AC_CHECK_FUNC(asprintf, [
	case "$host" in
		*-psp-*)
			dnl asprintf is broken on the PSP, but snprintf works.
			have_asprintf="no"
			AC_SUBST(ASPRINTF_M, "asprintf.m")
			ac_cv_snprintf_useful_ret="yes"
			;;
		*)
			have_asprintf="yes"
			AC_DEFINE(OF_HAVE_ASPRINTF, 1,
				[Whether we have asprintf])
			AC_SUBST(ASPRINTF_DEF, "-DOF_HAVE_ASPRINTF")
		;;
	esac
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
			}
		], [
			ac_cv_snprintf_useful_ret="yes"
		], [
			ac_cv_snprintf_useful_ret="no"
		], [
			ac_cv_snprintf_useful_ret="no"
		])
	])
	AC_MSG_RESULT($ac_cv_snprintf_useful_ret)
])
test x"$have_asprintf" != x"yes" -a x"$ac_cv_snprintf_useful_ret" != x"yes" && \
	AC_MSG_ERROR(No asprintf and no snprintf returning required space!)

AC_CHECK_LIB(m, fmod, LIBS="$LIBS -lm")
AC_CHECK_LIB(dl, dlopen, LIBS="$LIBS -ldl")

AC_ARG_ENABLE(threads,
	AS_HELP_STRING([--disable-threads], [disable thread support]))
AS_IF([test x"$enable_threads" != x"no"], [
	case "$host_os" in
	mingw*)
		AC_MSG_CHECKING(for threads)
		AC_MSG_RESULT(WinAPI)
		;;
	*)
		ACX_PTHREAD([
			CPPLAGS="$CPPFLAGS $PTHREAD_CFLAGS"
			LIBS="$LIBS $PTHREAD_LIBS"
			AC_DEFINE(OF_HAVE_PTHREADS, 1,
				[Whether we have pthreads])
			AC_CHECK_FUNC(pthread_spin_lock, [
				AC_DEFINE(OF_HAVE_PTHREAD_SPINLOCKS, 1,
					[Whether we have pthread spinlocks])
			])
			AC_CHECK_FUNC(sched_yield, [
				AC_DEFINE(OF_HAVE_SCHED_YIELD, 1,
					[Whether we have sched_yield])
			])
		], [
			AC_MSG_ERROR(No supported threads found!)
		])
		;;
	esac

	AC_DEFINE(OF_THREADS, 1, [Whether we have threads])
	AC_SUBST(OFTHREAD_M, "OFThread.m")
	AC_SUBST(OFTHREADTESTS_M, "OFThreadTests.m")
	AC_SUBST(OFHTTPREQUESTTESTS_M, "OFHTTPRequestTests.m")
	AC_SUBST(THREADING_H, "threading.h")

	AC_CHECK_FUNC(objc_sync_enter,, [
		AC_SUBST(OBJC_SYNC_M, "objc_sync.m")
		AC_DEFINE(NEED_OBJC_SYNC_INIT, 1,
			[Whether objc_sync_init needs to be called])
	])

	atomic_ops="none"

	AC_MSG_CHECKING(whether we have an atomic ops assembly implementation)
	AC_EGREP_CPP(yes, [
		#if defined(__GNUC__) && (defined(__i386__) || \
		    defined(__amd64__) || defined(__x86_64__))
		yes
		#endif
	], [
		AC_MSG_RESULT(yes)
		atomic_ops="assembly implementation"
	], [
		AC_MSG_RESULT(no)
	])

	AC_MSG_CHECKING(whether __sync_* works)
	AC_TRY_LINK([#include <stdint.h>], [
		int32_t i, j;
		if (__sync_add_and_fetch(&i, 1))
			j = __sync_sub_and_fetch(&i, 1);
		while (!__sync_bool_compare_and_swap(&i, 0, 1));
	], [
		AC_MSG_RESULT(yes)
		test x"$atomic_ops" = x"none" && atomic_ops="gcc builtins"
		AC_DEFINE(OF_HAVE_GCC_ATOMIC_OPS, 1,
			[Whether gcc atomic operations are available])
	], [
		AC_MSG_RESULT(no)
	])

	AC_CHECK_HEADER(libkern/OSAtomic.h, [
		test x"$atomic_ops" = x"none" && atomic_ops="libkern/OSAtomic.h"
		AC_DEFINE(OF_HAVE_OSATOMIC, 1,
			[Whether we have libkern/OSAtomic.h])
		AC_CHECK_FUNC(OSAtomicAdd64Barrier, [
			AC_DEFINE(OF_HAVE_OSATOMIC_64, 1,
				[Whether we have OSAtomic*64])
		])
	])
], [
	dnl We can only have one thread - therefore everything is atomic
	atomic_ops="not needed"
])

AC_MSG_CHECKING(for atomic operations)
AS_IF([test x"$atomic_ops" != x"none"], [
	AC_DEFINE(OF_ATOMIC_OPS, 1, [Whether we have atomic operations])
	AC_SUBST(ATOMIC_H, "atomic.h")
])
AC_MSG_RESULT($atomic_ops)

AC_CHECK_LIB(socket, socket, LIBS="$LIBS -lsocket")
AC_CHECK_LIB(ws2_32, main, LIBS="$LIBS -lws2_32")

AC_CHECK_FUNC(gmtime_r, [
	AC_DEFINE(HAVE_GMTIME_R, 1, [Whether we have gmtime_r])
])
AC_CHECK_FUNC(localtime_r, [
	AC_DEFINE(HAVE_LOCALTIME_R, 1, [Whether we have localtime_r])
])

AC_CHECK_HEADER(poll.h, [
	AC_DEFINE(OF_HAVE_POLL, 1, [Whether poll is supported])
])
AC_CHECK_HEADERS(sys/select.h, [
	AC_DEFINE(OF_HAVE_SYS_SELECT_H, 1, [Whether we have sys/select.h])
])

AC_MSG_CHECKING(for getaddrinfo)
AC_TRY_COMPILE([
	#include <stddef.h>
	#ifndef _WIN32
	# include <sys/types.h>
	# include <sys/socket.h>
	# include <netdb.h>
	#else
	# define _WIN32_WINNT 0x0501
	# include <ws2tcpip.h>
	#endif
], [
	struct addrinfo ai;
	getaddrinfo(NULL, NULL, NULL, NULL);
], [
	AC_MSG_RESULT(yes)
	AC_DEFINE(HAVE_GETADDRINFO, 1, [Whether we have getaddrinfo])

	AS_IF([test x"$enable_threads" != x"no"], [
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

		AS_IF([test x"$have_threadsafe_getaddrinfo" = x"unknown"], [
			AC_EGREP_CPP(yes, [
				#include <netdb.h>
				#ifdef h_errno
				yes
				#end
			], [
				have_threadsafe_getaddrinfo="yes"
			], [
				have_threadsafe_getaddrinfo="no"
			])
		])

		AS_IF([test x"$have_threadsafe_getaddrinfo" = x"yes"], [
			AC_DEFINE(HAVE_THREADSAFE_GETADDRINFO, 1,
				[Whether getaddrinfo is thread-safe])
		])

		AC_MSG_RESULT($have_threadsafe_getaddrinfo)
	])
], [
	AC_MSG_RESULT(no)
])

AC_CHECK_FUNC(madvise, [
	AC_DEFINE(HAVE_MADVISE, 1, [Whether we have madvise])
])

AS_IF([test x"$objc_runtime" = x"Apple"], [
	AC_CHECK_HEADER(Foundation/NSObject.h, [
		AC_SUBST(FOUNDATION_COMPAT_M, "foundation-compat.m")
	])
])

AS_IF([test x"$GOBJC" = x"yes"], [
	OBJCFLAGS="$OBJCFLAGS -Wwrite-strings -Wcast-align -Wpointer-arith"
	OBJCFLAGS="$OBJCFLAGS -Werror"

	AC_MSG_CHECKING(whether gcc has bug objc/27438)
	AC_TRY_COMPILE([
		@interface OFConstantString
		{
			struct objc_class *isa;
			const char *string;
			unsigned long size;
		}
		@end

		void *_OFConstantStringClassReference;
	], [
		OFConstantString *test = @"";
		test++; /* Get rid of unused variable warning */
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT([yes, adding -Wno-unused-variable])
		OBJCFLAGS="$OBJCFLAGS -Wno-unused-variable"
		AC_SUBST(NO_WARN_UNUSED, "-Wno-unused-variable")
	])

	AC_MSG_CHECKING(whether we need -Wno-strict-aliasing due to gcc bugs)
	AC_TRY_COMPILE([
		@interface OFObject
		{
			Class isa;
		}
		@end

		static struct {
			struct objc_class *isa;
		} object;
	], [
		OFObject *test = (OFObject*)&object;
		test++; /* Get rid of unused variable warning */
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$OBJCFLAGS -Wno-strict-aliasing"
	])
])

AS_IF([test x"$cross_compiling" = x"yes"], [
	AC_SUBST(BIN_PREFIX, "$host-")

	case "$host" in
		*-*-mingw*)
			AC_PATH_PROG(WINE, wine)

			AS_IF([test x"$WINE" != "x"], [
				AC_SUBST(TESTS, "tests")
				AC_SUBST(TEST_LAUNCHER, "$WINE")
			])
			;;
	esac
], [
	AC_SUBST(TESTS, "tests")
])

BUILDSYS_INIT
BUILDSYS_TOUCH_DEPS

dnl We don't call AC_PROG_CPP, but only AC_PROG_OBJCPP and set CPP to OBJCPP
dnl and add OBJCPPFLAGS to CPPFLAGS, thus we need to AC_SUBST these ourself
AC_SUBST(CPP)
AC_SUBST(CPPFLAGS)

AC_SUBST(PACKAGE, ObjFW)
AC_CONFIG_FILES([buildsys.mk extra.mk utils/objfw-config])
AC_CONFIG_HEADERS([config.h src/objfw-defs.h])
AC_OUTPUT
