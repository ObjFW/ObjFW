AC_INIT(ObjFW, 0.8-dev, js@webkeks.org)
BUILDSYS_INIT

AS_IF([test configure.ac -nt configure], [
	AC_MSG_ERROR([configure.ac is newer than configure! Run ./autogen.sh!])
])

AC_CONFIG_SRCDIR(src)

AC_CANONICAL_HOST

case "$host" in
	*-msdosdjgpp*)
		enable_shared="no"
		enable_threads="no"
		enable_sockets="no"
		;;
	*-psp-*)
		AS_IF([test x"$DEVKITPSP" = x""], [
			AC_MSG_ERROR(
				[DEVKITPSP is not set! Please set DEVKITPSP.])
		])

		OBJCFLAGS="$OBJCFLAGS -G0"
		CPPFLAGS="$CPPFLAGS -I$DEVKITPSP/psp/sdk/include"
		LDFLAGS="$LDFLAGS -G0"
		LIBS="$LIBS -L$DEVKITPSP/psp/sdk/lib -lpspdebug -lpspdisplay"
		LIBS="$LIBS -lpspge -lpspctrl -lpspsdk -lc -lpspnet"
		LIBS="$LIBS -lpspnet_inet -lpspnet_apctl -lpspnet_resolver"
		LIBS="$LIBS -lpsputility -lpspuser -lpspkernel"
		enable_shared="no"
		enable_threads="no"	# TODO
		enable_sockets="no"	# TODO

		AC_SUBST(MAP_LDFLAGS, ['-Wl,-Map,$@.map'])
		;;
esac

AC_LANG([Objective C])
AC_PROG_OBJC([clang gcc])
AC_PROG_OBJCPP
AC_PROG_LN_S
AC_PROG_INSTALL
AC_PROG_EGREP

AC_ARG_WITH(wii,
	AS_HELP_STRING([--with-wii], [build for Wii]))
AS_IF([test x"$with_wii" = x"yes"], [
	AS_IF([test x"$DEVKITPRO" = x""], [
		AC_MSG_ERROR([DEVKITPRO is not set! Please set DEVKITPRO.])
	])

	OBJCFLAGS="$OBJCFLAGS -mrvl -mcpu=750 -meabi -mhard-float"
	CPPFLAGS="$CPPFLAGS -DGEKKO -I$DEVKITPRO/libogc/include"
	LDFLAGS="$LDFLAGS -mrvl -mcpu=750 -meabi -mhard-float"
	LIBS="$LIBS -L$DEVKITPRO/libogc/lib/wii -lfat -logc"
	TESTS_LIBS="$TESTS_LIBS -lwiiuse -lbte"
	enable_shared="no"
	enable_threads="no"	# TODO

	AC_SUBST(MAP_LDFLAGS, ['-Wl,-Map,$@.map'])
])

AC_ARG_WITH(nds,
	AS_HELP_STRING([--with-nds], [build for Nintendo DS]))
AS_IF([test x"$with_nds" = x"yes"], [
	AS_IF([test x"$DEVKITPRO" = x""], [
		AC_MSG_ERROR([DEVKITPRO is not set! Please set DEVKITPRO.])
	])

	OBJCFLAGS="$OBJCFLAGS -march=armv5te -mtune=arm946e-s"
	OBJCFLAGS="$OBJCFLAGS -mthumb -mthumb-interwork"
	CPPFLAGS="$CPPFLAGS -DARM9 -I$DEVKITPRO/libnds/include"
	LDFLAGS="$LDFLAGS -specs=ds_arm9.specs"
	LIBS="$LIBS -L$DEVKITPRO/libnds/lib -lfilesystem -lfat -lnds9"
	enable_shared="no"
	enable_threads="no"	# TODO
	enable_sockets="no"	# TODO

	AC_DEFINE(OF_NINTENDO_DS, 1,
		[Whether we are compiling for the Nintendo DS])
	AC_SUBST(MAP_LDFLAGS, ['-Wl,-Map,$@.map'])
])

CPP="$OBJCPP"
CPPFLAGS="$CPPFLAGS $OBJCPPFLAGS"
OBJCFLAGS="$OBJCFLAGS -Wall -fexceptions -fobjc-exceptions -funwind-tables"
OBJCFLAGS="$OBJCFLAGS -fconstant-string-class=OFConstantString"

AX_CHECK_COMPILER_FLAGS(-std=gnu11, [
	OBJCFLAGS="$OBJCFLAGS -std=gnu11"
], [
	AX_CHECK_COMPILER_FLAGS(-std=gnu1x, [
		OBJCFLAGS="$OBJCFLAGS -std=gnu1x"
	], [
		AX_CHECK_COMPILER_FLAGS(-std=gnu99,
			[OBJCFLAGS="$OBJCFLAGS -std=gnu99"])
	])
])

AX_CHECK_COMPILER_FLAGS(-pipe, [OBJCFLAGS="$OBJCFLAGS -pipe"])
AX_CHECK_COMPILER_FLAGS(-fno-common, [OBJCFLAGS="$OBJCFLAGS -fno-common"])
AX_CHECK_COMPILER_FLAGS(-fno-constant-cfstrings, [
	OBJCFLAGS="$OBJCFLAGS -fno-constant-cfstrings"
	AC_SUBST(NO_CONST_CFSTRINGS, "-fno-constant-cfstrings")
])
AX_CHECK_COMPILER_FLAGS(-Wshorten-64-to-32 -Werror,
	[OBJCFLAGS="$OBJCFLAGS -Wshorten-64-to-32"])
AX_CHECK_COMPILER_FLAGS(-Wsemicolon-before-method-body -Werror,
	[OBJCFLAGS="$OBJCFLAGS -Wsemicolon-before-method-body"])
AX_CHECK_COMPILER_FLAGS(-Wobjc-property-synthesis -Werror,
	[OBJCFLAGS="$OBJCFLAGS -Wobjc-property-synthesis"])

AC_MSG_CHECKING(whether Objective C compiler supports properties)
AC_TRY_COMPILE([
	@interface Foo
	{
		id bar;
	}

	@property (retain, nonatomic) id bar;
	@end
], [
	Foo *foo = (id)0;
	[foo setBar: (id)0];
	[foo bar];
], [
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
	foo = ^ (int bar) { return 0; }
], [
	AC_SUBST(BLOCKS_FLAGS, "-fblocks")
	AC_SUBST(OFBLOCKTESTS_M, "OFBlockTests.m")
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
	OBJCFLAGS="$old_OBJCFLAGS"
])

AC_CHECK_TOOL(AR, ar)
AC_PROG_RANLIB
AC_ARG_ENABLE(shared,
	AS_HELP_STRING([--disable-shared], [do not build shared library]))
AS_IF([test x"$enable_shared" != x"no"], [
	BUILDSYS_SHARED_LIB
	AC_SUBST(OBJFW_SHARED_LIB, "${LIB_PREFIX}objfw${LIB_SUFFIX}")
	AC_SUBST(EXCEPTIONS_LIB_A, "exceptions.lib.a")
	AC_SUBST(EXCEPTIONS_EXCEPTIONS_LIB_A, "exceptions/exceptions.lib.a")
	AC_SUBST(FORWARDING_LIB_A, "forwarding.lib.a")
	AC_SUBST(FORWARDING_FORWARDING_LIB_A, "forwarding/forwarding.lib.a")
	AC_SUBST(LOOKUP_ASM_LIB_A, "lookup-asm.lib.a")
	AC_SUBST(LOOKUP_ASM_LOOKUP_ASM_LIB_A, "lookup-asm/lookup-asm.lib.a")
], [
	AC_SUBST(LIBOBJFW_DEP, "../src/libobjfw.a")
	AC_SUBST(LIBOBJFW_DEP_LVL2, "../../src/libobjfw.a")
])
AC_ARG_ENABLE(static, AS_HELP_STRING([--enable-static], [build static library]))
AS_IF([test x"$enable_static" = x"yes" -o x"$enable_shared" = x"no"], [
	AC_SUBST(OBJFW_STATIC_LIB, "libobjfw.a")
	AC_SUBST(EXCEPTIONS_A, "exceptions.a")
	AC_SUBST(EXCEPTIONS_EXCEPTIONS_A, "exceptions/exceptions.a")
	AC_SUBST(FORWARDING_A, "forwarding.a")
	AC_SUBST(FORWARDING_FORWARDING_A, "forwarding/forwarding.a")
	AC_SUBST(LOOKUP_ASM_A, "lookup-asm.a")
	AC_SUBST(LOOKUP_ASM_LOOKUP_ASM_A, "lookup-asm/lookup-asm.a")
])

AC_DEFINE_UNQUOTED(PLUGIN_SUFFIX, "$PLUGIN_SUFFIX", [Suffix for plugins])
AS_IF([test x"$PLUGIN_SUFFIX" != x""], [
	AC_SUBST(USE_SRCS_PLUGINS, '${SRCS_PLUGINS}')
	AC_SUBST(TESTPLUGIN, "plugin")
	AC_DEFINE(OF_HAVE_PLUGINS, 1, [Whether we have plugin support])
])

case "$host_os" in
	solaris*)
		CPPFLAGS="-D__EXTENSIONS__ -D_POSIX_PTHREAD_SEMANTICS $CPPFLAGS"
		;;
esac

objc_runtime="ObjFW runtime"
AC_CHECK_HEADER(objc/objc.h)
AC_MSG_CHECKING(which Objective C runtime to use)
AC_ARG_ENABLE(runtime,
	AS_HELP_STRING([--enable-runtime], [use the included runtime]))
AC_ARG_ENABLE(seluid24,
	AS_HELP_STRING([--enable-seluid24],
		[use 24 bit instead of 16 bit for selectors UIDs]))
AS_IF([test x"$enable_runtime" != x"yes"], [
	AS_IF([test x"$ac_cv_header_objc_objc_h" = x"yes"], [
		AC_EGREP_CPP(yes, [
			#import <objc/objc.h>

			#ifdef OBJC_BOOL_DEFINED
			yes
			#endif
		], [
			objc_runtime="Apple runtime"
		], [
			dnl We don't want the GNU runtime
			:
		])
	])
])
AC_MSG_RESULT($objc_runtime)

case "$objc_runtime" in
	"ObjFW runtime")
		AC_DEFINE(OF_OBJFW_RUNTIME, 1,
			[Whether we use the ObjFW runtime])

		AC_MSG_CHECKING([whether -fobjc-runtime=objfw is supported])

		old_OBJCFLAGS="$OBJCFLAGS"
		OBJCFLAGS="$OBJCFLAGS -fobjc-runtime=objfw"
		AC_TRY_LINK([
			@interface Test
			+ (void)test;
			@end

			@implementation Test
			+ (void)test
			{
			}
			@end

			void*
			objc_msg_lookup(void *obj, void *sel)
			{
				return (void*)0;
			}

			void
			__objc_exec_class(void *module)
			{
			}
		], [
			[Test test];
		], [
			RUNTIME_FLAGS="-fobjc-runtime=objfw"
			AC_MSG_RESULT(yes)
		], [
			RUNTIME_FLAGS="-fgnu-runtime"
			OBJCFLAGS="$old_OBJCFLAGS -fgnu-runtime"
			AC_MSG_RESULT(no)
			old_compiler="yes"
		])

		AC_SUBST(RUNTIME, "runtime")
		AC_SUBST(RUNTIME_FLAGS)

		if test x"$enable_shared" != x"no"; then
			AC_SUBST(RUNTIME_LIB_A, "runtime.lib.a")
			AC_SUBST(RUNTIME_RUNTIME_LIB_A, "runtime/runtime.lib.a")
		fi
		if test x"$enable_static" = x"yes" \
		    -o x"$enable_shared" = x"no"; then
			AC_SUBST(RUNTIME_A, "runtime.a")
			AC_SUBST(RUNTIME_RUNTIME_A, "runtime/runtime.a")
		fi

		AS_IF([test x"$enable_seluid24" = x"yes"], [
			AC_DEFINE(OF_SELUID24, 1,
				[Whether to use 24 bit selector UIDs])
		])

		AC_MSG_CHECKING(for exception type)
		AC_TRY_COMPILE([
			extern void foo();
		], [
			@try {
				foo();
			} @finally {
				foo();
			}
		], [
			AS_IF([$EGREP __gnu_objc_personality_v0 \
					conftest.$ac_objext >/dev/null], [
				exception_type="DWARF"
			])
			AS_IF([$EGREP __gnu_objc_personality_sj0 \
					conftest.$ac_objext >/dev/null], [
				exception_type="SjLj"
			])
			AS_IF([$EGREP __gnu_objc_personality_seh0 \
					conftest.$ac_objext >/dev/null], [
				exception_type="SEH"
			])

			case "$exception_type" in
			DWARF)
				AC_DEFINE(HAVE_DWARF_EXCEPTIONS, 1,
					[Whether DWARF exceptions are used])
				;;
			SjLj)
				AC_DEFINE(HAVE_SJLJ_EXCEPTIONS, 1,
					[Whether SjLj exceptions are used])
				;;
			SEH)
				AC_DEFINE(HAVE_SEH_EXCEPTIONS, 1,
					[Whether SEH exceptions are used])
				;;
			*)
				AC_MSG_RESULT(unknown)
				AC_MSG_ERROR([Exception type not detected!])
				;;
			esac

			AC_MSG_RESULT($exception_type)
		], [
			AC_MSG_RESULT(exceptions unavailable!)
			AC_MSG_ERROR([Exceptions not accepted by compiler!])
		])
		;;
	"Apple runtime")
		AC_DEFINE(OF_APPLE_RUNTIME, 1,
			[Whether we use the Apple ObjC runtime])

		AC_CHECK_LIB(objc, objc_msgSend, [
			LIBS="-lobjc $LIBS"
		], [
			AC_MSG_ERROR([libobjc not found!])
		])
		;;
esac

AC_CHECK_FUNC(objc_constructInstance, [], [
	AC_SUBST(INSTANCE_M, "instance.m")
])

AC_CHECK_FUNC(objc_autoreleasePoolPush, [], [
	AC_SUBST(AUTORELEASE_M, "autorelease.m")
])

AC_CHECK_FUNC(objc_enumerationMutation, [
	AC_DEFINE(HAVE_OBJC_ENUMERATIONMUTATION, 1,
		[Whether we have objc_enumerationMutation()])
])

case "$host_os" in
	darwin*)
		AC_SUBST(LDFLAGS_REEXPORT, ["-Wl,-reexport-lobjfw"])
		AS_IF([test x"$objc_runtime" = x"Apple runtime"], [
			AC_SUBST(REEXPORT_LIBOBJC, ["-Wl,-reexport-lobjc"])
		])
		;;
esac

AC_C_BIGENDIAN([
	AC_DEFINE(OF_BIG_ENDIAN, 1, [Whether we are big endian])
])
AS_IF([test x"$ac_cv_c_bigendian" = x"universal"], [
	AC_DEFINE(OF_UNIVERSAL, 1, [Whether we are building a universal binary])
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
		size_max="SIZE_T_MAX"
	], [
		AC_MSG_RESULT(no)
		size_max="(~(size_t)0)"
	])
	AC_DEFINE_UNQUOTED(SIZE_MAX, $size_max, [Maximum value for size_t])
])
AC_MSG_CHECKING(for SSIZE_MAX)
AC_EGREP_CPP(yes, [
	#include <stdint.h>
	#include <limits.h>

	#ifdef SSIZE_MAX
	yes
	#endif
], [
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
	AC_DEFINE(SSIZE_MAX, [((ssize_t)(SIZE_MAX / 2))],
		[Maximum value for ssize_t])
])

AC_CHECK_TYPE(max_align_t,
	[AC_DEFINE(OF_HAVE_MAX_ALIGN_T, 1, [Whether we have max_align_t])])

AC_CHECK_HEADER(stdnoreturn.h,
	[AC_DEFINE(OF_HAVE_STDNORETURN_H, 1, [Whether we have stdnoreturn.h])])

AC_CHECK_SIZEOF(float)
AC_CHECK_SIZEOF(double)
AS_IF([test x"$ac_cv_sizeof_float" != x"4" -o x"$ac_cv_sizeof_double" != x"8"],
	[AC_MSG_ERROR(
		[Floating point implementation does not conform to IEEE 754!])])

AC_MSG_CHECKING(for floating point endianess)
fp_endianess="unknown"
AS_IF([test x"$ac_cv_c_bigendian" != x"universal"], [
	AC_TRY_COMPILE([
		double endianess = 2.993700760838795055656993580068609688772747263874402942272934826871811872228512759832626847251963763755836687759498519784550143745834860002945223766052808125982053455555265216112722718870586961456110693379343178124592311441022662940307099598578775368547768968914916965731708568179631324904813506101190853720749196062963892799499230635163056742330563321122389331703618066046034494287335316842529021563862331183541255013987734473643350285400060357711238514186776429325214739886098119655678483017894951556639821088508565036657794343031121375178126860889964700274558728491825977274341798997758923017217660272136611938897932105874133412726223468780517578125e-259;
	], [
	], [
		AS_IF([$EGREP BigEnd conftest.$ac_objext >/dev/null], [
			AC_DEFINE(OF_FLOAT_BIG_ENDIAN, 1,
				[Whether floats are big endian])
			fp_endianess="big endian"
		], [
			AS_IF([$EGREP dnEgiB conftest.$ac_objext >/dev/null], [
				fp_endianess="little endian"
			])
		])
	])
], [
	fp_endianess="universal"
])
AC_MSG_RESULT($fp_endianess)
AS_IF([test x"$fp_endianess" = x"unknown"], [
	AC_MSG_ERROR(
		[Floating point implementation does not conform to IEEE 754!])])

case "$host" in
	arm*)
		AC_MSG_CHECKING(if VFP2 or above is available)
		AC_TRY_COMPILE([], [
			__asm__("fstmfdd sp!, {d0-d7}");
		], [
			AC_DEFINE(HAVE_VFP2, 1, [Whether we have VFP2 or above])
			AC_MSG_RESULT(yes)
		], [
			AC_MSG_RESULT(no)
		])
		;;
esac

AC_CHECK_FUNCS(strerror_r)

AC_CHECK_LIB(m, fmod, LIBS="$LIBS -lm")

AC_CHECK_FUNC(asprintf, [
	case "$host" in
		*-psp-*)
			dnl asprintf is broken on the PSP, but snprintf works.
			have_asprintf="no"
			ac_cv_snprintf_useful_ret="yes"
			;;
		*)
			have_asprintf="yes"
			AC_DEFINE(HAVE_ASPRINTF, 1,
				[Whether we have asprintf()])
		;;
	esac
], [
	have_asprintf="no"

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

AC_CHECK_FUNCS([arc4random random], break)

AC_CHECK_LIB(dl, dlopen, LIBS="$LIBS -ldl")
AC_CHECK_HEADERS(dlfcn.h)
case "$host_os" in
	netbsd*)
		dnl dladdr exists on NetBSD, but it is completely broken.
		dnl When using it with code that uses __thread, it freezes the
		dnl process so that it has to be killed using SIGKILL.
		dnl When disabling __thread, it doesn't freeze, but all symbols
		dnl are wrong.
		;;
	*)
		AC_CHECK_FUNCS(dladdr)
		;;
esac

AC_ARG_ENABLE(threads,
	AS_HELP_STRING([--disable-threads], [disable thread support]))
AS_IF([test x"$enable_threads" != x"no"], [
	AC_MSG_CHECKING(for threads)

	case "$host_os" in
	mingw*)
		AC_MSG_RESULT(WinAPI)
		;;
	*)
		AC_MSG_RESULT(POSIX)

		AX_CHECK_COMPILER_FLAGS(-pthread, [
			CPPFLAGS="$CPPFLAGS -pthread"
		], [
			CPPFLAGS="$CPPFLAGS -D_REENTRANT -D_THREAD_SAFE"
		])

		LIBS="$LIBS -lpthread"
		AC_TRY_LINK([
			#include <pthread.h>
		], [
			pthread_create(NULL, NULL, NULL, NULL);
		], [], [
			AC_MSG_ERROR(No supported threads found!)
		])

		AC_DEFINE(OF_HAVE_PTHREADS, 1, [Whether we have pthreads])

		AC_TRY_COMPILE([
			#include <pthread.h>
		], [
			pthread_mutexattr_t attr;
			pthread_mutexattr_settype(&attr,
			    PTHREAD_MUTEX_RECURSIVE);
		], [
			AC_DEFINE(OF_HAVE_RECURSIVE_PTHREAD_MUTEXES, 1,
				[If pthread mutexes can be recursive])
		])

		AC_CHECK_FUNC(pthread_spin_lock, [
			have_spinlocks="yes"
			AC_DEFINE(OF_HAVE_PTHREAD_SPINLOCKS, 1,
				[Whether we have pthread spinlocks])
		])

		AC_CHECK_FUNC(sched_yield, [
			AC_DEFINE(OF_HAVE_SCHED_YIELD, 1,
				[Whether we have sched_yield()])
		])

		AC_CHECK_HEADERS(pthread_np.h, [], [], [#include <pthread.h>])
		AC_CHECK_FUNCS(pthread_set_name_np pthread_setname_np, break)
		;;
	esac

	AC_DEFINE(OF_HAVE_THREADS, 1, [Whether we have threads])
	AC_SUBST(USE_SRCS_THREADS, '${SRCS_THREADS}')

	AC_ARG_ENABLE(compiler-tls,
		AS_HELP_STRING([--disable-compiler-tls],
			[disable compiler thread local storage]))
	AS_IF([test x"$enable_compiler_tls" != x"no"], [
		AC_CHECK_HEADERS(threads.h, [
			AC_DEFINE(OF_HAVE_THREADS_H, 1,
				[Whether we have threads.h])
		])

		AC_MSG_CHECKING(whether _Thread_local works)
		AC_TRY_LINK([
			static _Thread_local int x = 0;
		], [
			x++;
		], [
			AS_IF([test x"$enable_shared" != x"no"], [
				old_OBJCFLAGS="$OBJCFLAGS"
				OBJCFLAGS="$OBJCFLAGS -fPIC"
				AC_TRY_COMPILE([
					static _Thread_local int x = 0;
				], [
					x++;
				], [
					AC_MSG_RESULT(yes)
					AC_DEFINE(OF_HAVE__THREAD_LOCAL, 1,
						[Whether _Thread_local works])
				], [
					AC_MSG_RESULT(no)
				])
				OBJCFLAGS="$old_OBJCFLAGS"
			], [
				AC_MSG_RESULT(yes)
				AC_DEFINE(OF_HAVE__THREAD_LOCAL, 1,
					[Whether _Thread_local works])
			])
		], [
			AC_MSG_RESULT(no)
		])

		AC_MSG_CHECKING(whether __thread works)
		AC_TRY_LINK([
			/* It seems __thread is buggy with GCC 4.1 */
			#if __GNUC__ == 4 && __GNUC_MINOR__ < 2
			# error buggy
			#endif

			__thread int x = 0;
		], [
			x++;
		], [
			AS_IF([test x"$enable_shared" != x"no"], [
				old_OBJCFLAGS="$OBJCFLAGS"
				OBJCFLAGS="$OBJCFLAGS -fPIC"
				AC_TRY_COMPILE([
					__thread int x = 0;
				], [
					x++;
				], [
					AC_MSG_RESULT(yes)
					AC_DEFINE(OF_HAVE___THREAD, 1,
						[Whether __thread works])
				], [
					AC_MSG_RESULT(no)
				])
				OBJCFLAGS="$old_OBJCFLAGS"
			], [
				AC_MSG_RESULT(yes)
				AC_DEFINE(OF_HAVE___THREAD, 1,
					[Whether __thread works])
			])
		], [
			AC_MSG_RESULT(no)
		])
	])

	atomic_ops="none"

	AC_MSG_CHECKING(whether __sync_* works)
	AC_TRY_LINK([#include <stdint.h>], [
		int32_t i, j;
		if (__sync_add_and_fetch(&i, 1))
			j = __sync_sub_and_fetch(&i, 1);
		while (!__sync_bool_compare_and_swap(&i, 0, 1));
	], [
		AC_MSG_RESULT(yes)
		atomic_ops="GCC builtins"
		AC_DEFINE(OF_HAVE_GCC_ATOMIC_OPS, 1,
			[Whether GCC atomic operations are available])
	], [
		AC_MSG_RESULT(no)
	])

	AC_MSG_CHECKING(whether we have an atomic ops assembly implementation)
	AC_EGREP_CPP(yes, [
		#if defined(__GNUC__) && (defined(__i386__) || \
			defined(__x86_64__) || defined(__amd64__)) || \
			defined(__ppc__)
		yes
		#endif
	], [
		AC_MSG_RESULT(yes)
		test x"$atomic_ops" = x"none" && \
			atomic_ops="assembly implementation"
	], [
		AC_MSG_RESULT(no)
	])

	AC_CHECK_HEADER(libkern/OSAtomic.h, [
		test x"$atomic_ops" = x"none" && atomic_ops="libkern/OSAtomic.h"
		AC_DEFINE(OF_HAVE_OSATOMIC, 1,
			[Whether we have libkern/OSAtomic.h])
	])
], [
	dnl We can only have one thread - therefore everything is atomic
	atomic_ops="not needed"
])

AC_MSG_CHECKING(for atomic operations)
AS_IF([test x"$atomic_ops" != x"none"], [
	AC_DEFINE(OF_HAVE_ATOMIC_OPS, 1, [Whether we have atomic operations])
	AC_SUBST(ATOMIC_H, "atomic.h")
])
AC_MSG_RESULT($atomic_ops)

AC_ARG_ENABLE(files,
	AS_HELP_STRING([--disable-files], [disable file support]))
AS_IF([test x"$enable_files" != x"no"], [
	AC_DEFINE(OF_HAVE_FILES, 1, [Whether we have files])
	AC_SUBST(USE_SRCS_FILES, '${SRCS_FILES}')
	AC_SUBST(OFHASH, "ofhash")
	AC_SUBST(OFZIP, "ofzip")

	AC_CHECK_TYPE(off64_t, [
		AC_DEFINE(OF_HAVE_OFF64_T, 1, [Whether we have off64_t])
	])

	AC_CHECK_HEADERS([pwd.h grp.h])
	AC_CHECK_FUNC(chmod, [
		AC_DEFINE(OF_HAVE_CHMOD, 1, [Whether we have chmod()])
	])
	AC_CHECK_FUNC(chown, [
		AC_DEFINE(OF_HAVE_CHOWN, 1, [Whether we have chown()])
	])
	AC_CHECK_FUNC(link, [
		AC_DEFINE(OF_HAVE_LINK, 1, [Whether we have link()])
	])
	AC_CHECK_FUNC(symlink, [
		AC_DEFINE(OF_HAVE_SYMLINK, 1, [Whether we have symlink()])
	])
	AC_CHECK_FUNCS([lstat readdir_r])
])

AC_CHECK_FUNCS([sysconf gmtime_r localtime_r nanosleep fcntl])

AC_CHECK_FUNC(pipe, [
	AC_DEFINE(OF_HAVE_PIPE, 1, [Whether we have pipe()])
])

AC_ARG_ENABLE(sockets,
	AS_HELP_STRING([--disable-sockets], [disable socket support]))
AS_IF([test x"$enable_sockets" != x"no"], [
	AC_DEFINE(OF_HAVE_SOCKETS, 1, [Whether we have sockets])
	AC_SUBST(USE_SRCS_SOCKETS, '${SRCS_SOCKETS}')

	AS_IF([test x"$enable_files" != x"no"], [
		AC_SUBST(OFHTTP, "ofhttp")
	])

	AC_CHECK_LIB(socket, socket, LIBS="$LIBS -lsocket")
	AC_CHECK_LIB(network, socket, LIBS="$LIBS -lnetwork")
	AC_CHECK_LIB(ws2_32, main, LIBS="$LIBS -lws2_32")

	AC_CHECK_HEADER(sys/socket.h, [
		AC_DEFINE(OF_HAVE_SYS_SOCKET_H, 1,
			[Whether we have sys/socket.h])
	])
	AC_CHECK_HEADERS(netinet/in.h, [
		AC_DEFINE(OF_HAVE_NETINET_IN_H, 1,
			[Whether we have netinet/in.h])
	])
	AC_CHECK_HEADERS(netinet/tcp.h, [
		AC_DEFINE(OF_HAVE_NETINET_TCP_H, 1,
			[Whether we have netinet/tcp.h])
	])
	AC_CHECK_HEADERS([arpa/inet.h netdb.h])

	AC_CHECK_FUNCS([paccept accept4])

	AC_CHECK_FUNC(kqueue, [
		AC_DEFINE(HAVE_KQUEUE, 1, [Whether we have kqueue])
		AC_SUBST(OFKERNELEVENTOBSERVER_KQUEUE_M,
			"OFKernelEventObserver_kqueue.m")

		AC_CHECK_FUNCS(kqueue1)
	])
	AC_CHECK_FUNC(epoll_create, [
		AC_DEFINE(HAVE_EPOLL, 1, [Whether we have epoll])
		AC_SUBST(OFKERNELEVENTOBSERVER_EPOLL_M,
			"OFKernelEventObserver_epoll.m")

		AC_CHECK_FUNCS(epoll_create1)
	])
	AC_CHECK_HEADER(poll.h, [
		AC_DEFINE(HAVE_POLL_H, 1, [Whether we have poll.h])
		AC_SUBST(OFKERNELEVENTOBSERVER_POLL_M,
			"OFKernelEventObserver_poll.m")
	])
	AC_CHECK_HEADER(sys/select.h, [
		AC_DEFINE(HAVE_SYS_SELECT_H, 1, [Whether we have sys/select.h])
		AC_SUBST(OFKERNELEVENTOBSERVER_SELECT_M,
			"OFKernelEventObserver_select.m")
	])

	case "$host_os" in
		mingw*)
			AC_SUBST(OFKERNELEVENTOBSERVER_SELECT_M,
				"OFKernelEventObserver_select.m")
			;;
	esac

	AS_IF([test x"$with_wii" = x"yes"], [
	       AC_SUBST(OFKERNELEVENTOBSERVER_POLL_M,
			"OFKernelEventObserver_poll.m")
	])

	AC_MSG_CHECKING(for getaddrinfo)
	AC_TRY_COMPILE([
		#include <stddef.h>
		#ifndef _WIN32
		# include <sys/types.h>
		# include <sys/socket.h>
		# include <netdb.h>
		#else
		typedef unsigned char BOOL;
		# include <ws2tcpip.h>
		#endif
	], [
		struct addrinfo ai;
		getaddrinfo(NULL, NULL, NULL, NULL);
	], [
		AC_MSG_RESULT(yes)
		AC_DEFINE(HAVE_GETADDRINFO, 1, [Whether we have getaddrinfo()])

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

			AS_IF([test x"$have_threadsafe_getaddrinfo" = \
					x"unknown"], [
				AC_EGREP_CPP(yes, [
					#ifndef _WIN32
					# include <sys/types.h>
					# include <sys/socket.h>
					# include <netdb.h>
					#else
					# define _WIN32_WINNT 0x0501
					# include <windows.h>
					# include <ws2tcpip.h>
					#endif

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
])

AS_IF([test x"$enable_sockets" != x"no" -a x"$enable_threads" != x"no"], [
	AC_SUBST(OFHTTPCLIENTTESTS_M, "OFHTTPClientTests.m")
])

AC_DEFUN([CHECK_BUILTIN_BSWAP], [
	AC_MSG_CHECKING(for __builtin_bswap$1)
	AC_TRY_LINK([
		#include <stdint.h>
		#include <stdio.h>
		#include <inttypes.h>
		#include <errno.h>
	], [
		uint$1_t i = errno;
		printf("%" PRIu$1, __builtin_bswap$1(i));
	], [
		AC_MSG_RESULT(yes)
		AC_DEFINE(OF_HAVE_BUILTIN_BSWAP$1, 1,
			[Whether we have __builtin_bswap$1])
	], [
		AC_MSG_RESULT(no)
	])
])
CHECK_BUILTIN_BSWAP(16)
CHECK_BUILTIN_BSWAP(32)
CHECK_BUILTIN_BSWAP(64)

case "$host" in
	arm*-apple-darwin*)
		have_processes="no"
		;;
	*-*-mingw*)
		have_processes="yes"
		;;
	*-*-msdosdjgpp*)
		have_processes="no"
		;;
	*)
		AC_CHECK_FUNCS([fork dup2 execvp kill _exit], [
			AS_IF([test x"$ac_cv_func_fork" = x"yes" \
			    -a x"$ac_cv_func_pipe" = x"yes" \
			    -a x"$ac_cv_func_dup2" = x"yes" \
			    -a x"$ac_cv_func_execvp" = x"yes" \
			    -a x"$ac_cv_func_kill" = x"yes" \
			    -a x"$ac_cv_func__exit" = x"yes"], [
				have_processes="yes"
			])
		], [
			break
		])

		AC_CHECK_FUNCS(posix_spawnp)

		AS_IF([test x"$ac_cv_func_posix_spawnp" = x"yes" \
		    -a x"$ac_cv_func_kill" = x"yes"], [
			have_processes="yes"

			AC_CHECK_HEADERS(spawn.h)
		])
		;;
esac
AS_IF([test x"$have_processes" = x"yes"], [
	AC_SUBST(OFPROCESS_M, "OFProcess.m")
	AC_DEFINE(OF_HAVE_PROCESSES, 1, [Whether we have processes])
])

AC_CHECK_HEADERS(sys/ioctl.h)

AS_IF([test x"$objc_runtime" = x"Apple runtime"], [
	AC_CHECK_HEADER(Foundation/NSObject.h, [
		AC_SUBST(FOUNDATION_COMPAT_M, "foundation-compat.m")
		AC_SUBST(BRIDGE, "bridge")

		AS_IF([test x"$enable_shared" != x"no"], [
			AC_SUBST(OBJFW_BRIDGE_SHARED_LIB,
				"${LIB_PREFIX}objfw-bridge${LIB_SUFFIX}")
		])
		AS_IF([test x"$enable_static" = x"yes" \
		    -o x"$enable_shared" = x"no"], [
			AC_SUBST(OBJFW_BRIDGE_STATIC_LIB, "libobjfw-bridge.a")
		])
	])
])

case "$host" in
	arm*-apple-darwin*)
		AC_DEFINE(OF_IOS, 1, [Whether we compile for iOS])
		;;
esac

AS_IF([test x"$GOBJC" = x"yes"], [
	OBJCFLAGS="$OBJCFLAGS -Wwrite-strings -Wpointer-arith -Werror"

	AC_MSG_CHECKING(whether we have GCC bug objc/27438)
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
		(void)test; /* Get rid of unused variable warning */
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT([yes, adding -Wno-unused-variable])
		OBJCFLAGS="$OBJCFLAGS -Wno-unused-variable"
		AC_SUBST(NO_WARN_UNUSED, "-Wno-unused-variable")
	])

	AC_MSG_CHECKING(whether we need -Wno-strict-aliasing due to GCC bugs)
	AC_TRY_COMPILE([
		@interface Foo
		{
			struct objc_class *isa;
		}
		@end

		static struct {
			struct objc_class *isa;
		} object;
	], [
		Foo *test = (Foo*)&object;
		(void)test; /* Get rid of unused variable warning */
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$OBJCFLAGS -Wno-strict-aliasing"
	])

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Wcast-align"
	AC_MSG_CHECKING(whether -Wcast-align is buggy)
	AC_TRY_COMPILE([
		#ifdef __has_attribute
		# if __has_attribute(objc_root_class)
		__attribute__((__objc_root_class__))
		# endif
		#endif
		@interface Foo
		{
			struct objc_class *_isa;
		}
		@end

		@implementation Foo
		- (void)foo
		{
			struct objc_class *c = _isa;
			(void)c;
		}
		@end
	], [
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$old_OBJCFLAGS"
	])

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Wdocumentation"
	AC_MSG_CHECKING(whether -Wdocumentation works correctly)
	AC_TRY_COMPILE([
		/*!
		 * @class Test conftest.m conftest.m
		 */
		@interface Test
		@end
	], [
	], [
		AC_MSG_RESULT(yes)
	], [
		AC_MSG_RESULT(no)
		OBJCFLAGS="$old_OBJCFLAGS"
	])

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -pedantic"
	AC_MSG_CHECKING(whether -pedantic is buggy)
	AC_TRY_COMPILE([
		#import <stdlib.h>

		#ifdef __has_attribute
		# if __has_attribute(objc_root_class)
		__attribute__((__objc_root_class__))
		# endif
		#endif
		@interface Foo
		{
			void *foo;
		}
		@end

		@interface Bar: Foo
		@end
	], [], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$old_OBJCFLAGS"
	])
])

AS_IF([test x"$cross_compiling" = x"yes"], [
	AC_SUBST(BIN_PREFIX, "${host_alias}-")

	case "$host" in
		*-*-mingw*)
			AC_CHECK_PROG(WINE, wine, wine)

			AS_IF([test x"$WINE" != x""], [
				AC_SUBST(RUN_TESTS, "run")
				AC_SUBST(TEST_LAUNCHER, "$WINE")
			])
			;;
	esac

	AS_IF([test x"$with_wii" = x"yes"], [
		dnl Keep this lowercase, as WIILOAD is a variable used by
		dnl wiiload and thus likely already set by the user to something
		dnl that is not the path of the wiiload binary.
		AC_CHECK_PROG(wiiload, wiiload, wiiload)

		AS_IF([test x"$wiiload" != x""], [
			AC_SUBST(RUN_TESTS, "run")
			AC_SUBST(TEST_LAUNCHER, "$wiiload")
		])
	])
], [
	AC_SUBST(RUN_TESTS, "run")
])

dnl We don't call AC_PROG_CPP, but only AC_PROG_OBJCPP and set CPP to OBJCPP
dnl and add OBJCPPFLAGS to CPPFLAGS, thus we need to AC_SUBST these ourself.
AC_SUBST(CPP)
AC_SUBST(CPPFLAGS)
dnl We use the ObjC compiler as our assembler
AC_SUBST(AS, $OBJC)
AC_SUBST(ASFLAGS)
AC_SUBST(AS_DEPENDS, '${OBJC_DEPENDS}')

AC_SUBST(TESTS_LIBS)

AC_CONFIG_FILES([
	buildsys.mk
	extra.mk
	utils/objfw-config
	support/Info.plist
	support/Bridge-Info.plist
])
AC_CONFIG_HEADERS([config.h src/objfw-defs.h])
AC_OUTPUT

AS_IF([test x"$old_compiler" = x"yes"], [
	echo
	printf "  ** Note: Your compiler does not seem to "
	echo "accept -fobjc-runtime=objfw."
	printf "  ** To get optimal performance, you should install "
	echo "Clang >= 3.2"
	printf "  ** (or the latest Clang release to be able to use all "
	echo "features)."
	echo
])

AS_IF([test x"$enable_threads" != x"no" -a x"$atomic_ops" = x"none" \
    -a x"$have_spinlocks" != x"yes"], [
	echo
	printf "  ** Warning: You have enabled threads, but neither atomic "
	echo "operations nor"
	printf "  ** spinlocks are available. Expect *very* poor performance, "
	echo "as a mutex will"
	printf "  ** be locked for every retain and release! If you don't "
	echo "need threads, try"
	echo "  ** --disable-threads to work around this problem."
	echo
])
