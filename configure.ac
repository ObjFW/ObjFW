AC_INIT(ObjFW, 0.91-dev, js@heap.zone)
AC_CONFIG_SRCDIR(src)
AC_CONFIG_AUX_DIR(build-aux)
AC_CONFIG_MACRO_DIR(build-aux/m4)

AC_DEFINE(OBJFW_VERSION_MAJOR, 0, [The major version of ObjFW])
AC_DEFINE(OBJFW_VERSION_MINOR, 91, [The minor version of ObjFW])
dnl This may only be set to 0.91 once 0.91 is released
AC_SUBST(BUNDLE_VERSION, 0.90.9900)
AC_SUBST(BUNDLE_SHORT_VERSION, 0.90)

for i in configure.ac build-aux/m4/*; do
	AS_IF([test $i -nt configure], [
		AC_MSG_ERROR([$i is newer than configure! Run ./autogen.sh!])
	])
done

BUILDSYS_INIT

AC_CANONICAL_HOST

AC_ARG_WITH(ixemul,
	AS_HELP_STRING([--with-ixemul], [build with ixemul]))

dnl Used to disable checking for -pedantic on some platforms where it's broken
check_pedantic="yes"

case "$host" in
	arm-*-riscos*)
		AS_IF([test x"$OBJCFLAGS" = x""], [
			OBJCFLAGS="-O2 -g"
		])
		flags="-mfloat-abi=softfp -mfpu=vfp -mlibscl"
		ASFLAGS="$ASFLAGS -mfloat-abi=softfp -mfpu=vfp"
		OBJCFLAGS="$OBJCFLAGS $flags"
		OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flags"
		LDFLAGS="$LDFLAGS $flags"

		enable_shared="no"
		enable_threads="no"
		enable_sockets="no"
		enable_files="no"
		ac_cv_snprintf_useful_ret="yes"
		;;
	m68k-*-amigaos*)
		AS_IF([test x"$OBJCFLAGS" = x""], [
			OBJCFLAGS="-O0"
		])
		OBJCFLAGS="$OBJCFLAGS -noixemul"
		OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS -noixemul"
		CPPFLAGS="$CPPFLAGS -D__NO_NET_API"
		LDFLAGS="$LDFLAGS -noixemul"

		enable_shared="no"
		enable_threads="no"
		enable_files="yes"	# Required for reading ENV:
		supports_amiga_lib="yes"
		ac_cv_snprintf_useful_ret="yes"

		AS_IF([test x"$enable_amiga_lib" != x"no"], [
			AC_SUBST(OBJFWRT_AMIGA_LIB, objfwrt68k.library)
			AC_SUBST(SFDC_TARGET, m68k-amigaos)
			AC_SUBST(SFD_FILE, amigaos3.sfd)
			AC_SUBST(SFDC_INLINE_H, inline.h)
			dnl For 68000, GCC emits calls to helper functions that
			dnl do not work properly in a library.
			AC_SUBST(AMIGA_LIB_CFLAGS,
				"-mcpu=68020 -fbaserel -ffreestanding")
			AC_SUBST(AMIGA_LIB_LDFLAGS,
				"-mcpu=68020 -fbaserel -resident -nostartfiles")
		])

		AC_SUBST(LIBBASES_M, libbases.m)
		;;
	powerpc-*-amigaos*)
		CPPFLAGS="$CPPFLAGS -D__USE_INLINE__"

		enable_shared="no"
		enable_threads="no"
		enable_files="yes"	# Required for reading ENV:

		AC_SUBST(LIBBASES_M, libbases.m)
		;;
	*-morphos*)
		AS_IF([test x"$with_ixemul" != x"yes"], [
			AS_IF([test x"$OBJCFLAGS" = x""], [
				OBJCFLAGS="-O2 -g"
			])
			OBJCFLAGS="$OBJCFLAGS -noixemul"
			OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS -noixemul"
			LDFLAGS="$LDFLAGS -noixemul"
			enable_files="yes"	# Required for reading ENV:
			supports_amiga_lib="yes"
			check_pedantic="no"	# Breaks generated inlines

			AS_IF([test x"$enable_amiga_lib" != x"no"], [
				AC_SUBST(OBJFWRT_AMIGA_LIB, objfwrt.library)
				AC_SUBST(CVINCLUDE_INLINE_H, inline.h)
				t="-mresident32 -ffreestanding"
				AC_SUBST(AMIGA_LIB_CFLAGS, $t)
				t="-mresident32 -nostartfiles -nodefaultlibs"
				t="$t -lc"
				AC_SUBST(AMIGA_LIB_LDFLAGS, $t)
			])

			AC_SUBST(LIBBASES_M, libbases.m)
		])

		enable_shared="no"
		enable_threads="no"
		;;
	*-msdosdjgpp*)
		enable_shared="no"
		enable_threads="no"
		enable_sockets="no"
		;;
	*-*-mingw*)
		LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition"
		LIBS="$LIBS -lversion"

		AC_SUBST(USE_SRCS_WINDOWS, '${SRCS_WINDOWS}')
		;;
	*-psp-*)
		AS_IF([test x"$DEVKITPSP" = x""], [
			AC_MSG_ERROR(
				[DEVKITPSP is not set! Please set DEVKITPSP.])
		])

		AS_IF([test x"$OBJCFLAGS" = x""], [
			OBJCFLAGS="-O2"
		])
		OBJCFLAGS="$OBJCFLAGS -G0"
		OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS -G0"
		CPPFLAGS="$CPPFLAGS -I$DEVKITPSP/psp/sdk/include"
		LDFLAGS="$LDFLAGS -G0"
		LIBS="$LIBS -L$DEVKITPSP/psp/sdk/lib -lpspdebug -lpspdisplay"
		LIBS="$LIBS -lpspge -lpspctrl -lpspsdk -lc -lpspnet"
		LIBS="$LIBS -lpspnet_inet -lpspnet_apctl -lpspnet_resolver"
		LIBS="$LIBS -lpsputility -lpspuser -lpspkernel -lgcc -lpsplibc"
		enable_shared="no"
		enable_threads="no"	# TODO
		enable_sockets="no"	# TODO
		check_pedantic="no"

		AC_SUBST(MAP_LDFLAGS, ['-Wl,-Map,$@.map'])
		;;
esac

AS_IF([test x"$host_os" = x"msdosdjgpp" -a x"$build_os" = x"msdosdjgpp"], [
	dnl Hack to make configure find these on DOS.
	: ${AR:=ar.exe}
	: ${GREP:=grep.exe}
	: ${RANLIB:=ranlib.exe}
])

AC_LANG([Objective C])
AC_PROG_OBJC([clang egcc gcc])
AC_PROG_OBJCPP
AC_PROG_LN_S
AC_PROG_INSTALL
AC_PROG_EGREP

BUILDSYS_CHECK_IOS

AC_ARG_WITH(wii,
	AS_HELP_STRING([--with-wii], [build for Wii]))
AS_IF([test x"$with_wii" = x"yes"], [
	AS_IF([test x"$DEVKITPRO" = x""], [
		AC_MSG_ERROR([DEVKITPRO is not set! Please set DEVKITPRO.])
	])

	flags="-mrvl -mcpu=750 -meabi -mhard-float"
	OBJCFLAGS="$OBJCFLAGS $flags"
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flags"
	CPPFLAGS="$CPPFLAGS -DGEKKO -I$DEVKITPRO/libogc/include"
	LDFLAGS="$LDFLAGS -mrvl -mcpu=750 -meabi -mhard-float"
	LIBS="$LIBS -L$DEVKITPRO/libogc/lib/wii -lfat -logc"
	TESTS_LIBS="$TESTS_LIBS -lwiiuse -lbte"
	enable_shared="no"
	enable_threads="no"	# TODO

	AC_DEFINE(OF_WII, 1, [Whether we are compiling for Wii])
	OBJFW_CPPFLAGS="$OBJFW_CPPFLAGS -DGEKKO -I\$DEVKITPRO/libogc/include"
	AC_SUBST(MAP_LDFLAGS, ['-Wl,-Map,$@.map'])
])

AC_ARG_WITH(nds,
	AS_HELP_STRING([--with-nds], [build for Nintendo DS]))
AS_IF([test x"$with_nds" = x"yes"], [
	AS_IF([test x"$DEVKITPRO" = x""], [
		AC_MSG_ERROR([DEVKITPRO is not set! Please set DEVKITPRO.])
	])

	flags="-march=armv5te -mtune=arm946e-s -mthumb -mthumb-interwork"
	OBJCFLAGS="$OBJCFLAGS $flags"
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flags"
	CPPFLAGS="$CPPFLAGS -DARM9 -I$DEVKITPRO/libnds/include"
	ASFLAGS="$ASFLAGS -march=armv5te"
	LDFLAGS="$LDFLAGS -specs=ds_arm9.specs"
	LIBS="$LIBS -L$DEVKITPRO/libnds/lib -lfilesystem -lfat -lnds9"
	enable_shared="no"
	enable_threads="no"	# TODO
	enable_sockets="no"	# TODO
	check_pedantic="no"

	AC_DEFINE(OF_NINTENDO_DS, 1, [Whether we are compiling for Nintendo DS])
	OBJFW_CPPFLAGS="$OBJFW_CPPFLAGS -DARM9 -I\$DEVKITPRO/libnds/include"
	AC_SUBST(MAP_LDFLAGS, ['-Wl,-Map,$@.map'])
])

AC_ARG_WITH(3ds,
	AS_HELP_STRING([--with-3ds], [build for Nintendo 3DS]))
AS_IF([test x"$with_3ds" = x"yes"], [
	AS_IF([test x"$DEVKITPRO" = x""], [
		AC_MSG_ERROR([DEVKITPRO is not set! Please set DEVKITPRO.])
	])

	flags="-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft"
	flags="$flags -mword-relocations"
	OBJCFLAGS="$OBJCFLAGS $flags"
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flags"
	CPPFLAGS="$CPPFLAGS -DARM11 -I$DEVKITPRO/libctru/include"
	ASFLAGS="$ASFLAGS -march=armv6k"
	LDFLAGS="$LDFLAGS -specs=3dsx.specs -march=armv6k -mtune=mpcore"
	LDFLAGS="$LDFLAGS -mfloat-abi=hard -mtp=soft -mword-relocations"
	LIBS="$LIBS -L$DEVKITPRO/libctru/lib -lctru"
	enable_shared="no"
	enable_threads="no"	# TODO
	check_pedantic="no"

	AC_DEFINE(OF_NINTENDO_3DS, 1,
		[Whether we are compiling for Nintendo 3DS])
	OBJFW_CPPFLAGS="$OBJFW_CPPFLAGS -DARM11 -I\$DEVKITPRO/libctru/include"
	AC_SUBST(MAP_LDFLAGS, ['-Wl,-Map,$@.map'])
])

CPP="$OBJCPP"
CPPFLAGS="$CPPFLAGS $OBJCPPFLAGS -DOF_COMPILING_OBJFW"
flags="-fexceptions -fobjc-exceptions -funwind-tables"
flags="$flags -fconstant-string-class=OFConstantString"
OBJCFLAGS="$OBJCFLAGS -Wall $flags"
OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flags"
dnl amiga-gcc requires -fexceptions in LDFLAGS in order to link in the glue code
dnl for registering the frames.
LDFLAGS="$LDFLAGS -fexceptions"

case "$OBJC" in
	*clang*)
		case "$host" in
			dnl Clang generates MIPS assembly not accepted by GNU
			dnl as, however, Clang's integrated assembler doesn't
			dnl accept everything used in ObjFW's assembly files.
			dnl Therefore, use the integrated assembler for ObjC
			dnl files, but not for assembly files.
			mips*-*-*)
				flag="-integrated-as"
				OBJCFLAGS="$OBJCFLAGS $flag"
				OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flag"
				;;
			dnl Clang's assembler on Windows is not complete yet
			dnl and cannot compile all .S files.
			*-*-mingw*)
				ASFLAGS="$ASFLAGS -no-integrated-as"
				;;
			dnl Clang generates assembly output on SPARC64 that
			dnl OpenBSD's assembler does not accept.
			sparc64-*-*openbsd*)
				flag="-integrated-as"
				OBJCFLAGS="$OBJCFLAGS $flag"
				OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flag"
				;;
		esac
		;;
esac

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

case "$build_os" in
	morphos*)
		# MorphOS 3.10 has a buggy ixemul that does not work with -pipe.
		;;
	*)
		AX_CHECK_COMPILER_FLAGS(-pipe, [OBJCFLAGS="$OBJCFLAGS -pipe"])
		;;
esac
AX_CHECK_COMPILER_FLAGS(-fno-common, [OBJCFLAGS="$OBJCFLAGS -fno-common"])
AX_CHECK_COMPILER_FLAGS(-Xclang -fno-constant-cfstrings, [
	flag="-Xclang -fno-constant-cfstrings"
	OBJCFLAGS="$OBJCFLAGS $flag"
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flag"
])
AX_CHECK_COMPILER_FLAGS([-Wsign-compare -Werror],
	[OBJCFLAGS="$OBJCFLAGS -Wsign-compare"])
AS_IF([test x"$with_nds" != x"yes"], [
	AX_CHECK_COMPILER_FLAGS([-Wshadow -Werror],
		[OBJCFLAGS="$OBJCFLAGS -Wshadow"])
])
AX_CHECK_COMPILER_FLAGS([-Wshorten-64-to-32 -Werror],
	[OBJCFLAGS="$OBJCFLAGS -Wshorten-64-to-32"])
AX_CHECK_COMPILER_FLAGS([-Wundeclared-selector -Werror],
	[OBJCFLAGS="$OBJCFLAGS -Wundeclared-selector"])
AX_CHECK_COMPILER_FLAGS([-Wsemicolon-before-method-body -Werror],
	[OBJCFLAGS="$OBJCFLAGS -Wsemicolon-before-method-body"])
AX_CHECK_COMPILER_FLAGS([-Wobjc-missing-property-synthesis -Werror],
	[OBJCFLAGS="$OBJCFLAGS -Wobjc-missing-property-synthesis"])
AX_CHECK_COMPILER_FLAGS([-Wmissing-method-return-type -Werror],
	[OBJCFLAGS="$OBJCFLAGS -Wmissing-method-return-type"])

case "$host" in
	m68k-*-amigaos*)
		dnl The inline headers generate code that triggers
		dnl -Wpointer-sign.
		OBJCFLAGS="$OBJCFLAGS -Wno-pointer-sign"
		;;
esac

AC_MSG_CHECKING(whether Objective C compiler supports properties)
AC_TRY_COMPILE([
	#ifdef __has_attribute
	# if __has_attribute(objc_root_class)
	__attribute__((__objc_root_class__))
	# endif
	#endif
	@interface Foo
	{
		id bar;
	}

	@property (nonatomic, retain) id bar;
	@end
], [
	Foo *foo = (id)0;
	[foo setBar: (id)0];
	foo = [foo bar];
], [
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
	AC_MSG_ERROR(Compiler does not support properties!)
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
	AC_SUBST(INVOCATION_LIB_A, "invocation.lib.a")
	AC_SUBST(INVOCATION_INVOCATION_LIB_A, "invocation/invocation.lib.a")
	AC_SUBST(LOOKUP_ASM_LIB_A, "lookup-asm.lib.a")
	AC_SUBST(LOOKUP_ASM_LOOKUP_ASM_LIB_A, "lookup-asm/lookup-asm.lib.a")

	BUILDSYS_FRAMEWORK([
		AC_SUBST(OBJFW_FRAMEWORK, "ObjFW.framework")
		build_framework="yes"
	])
], [
	AC_DEFINE(OF_NO_SHARED, 1, [Whether no shared library was built])
	AC_SUBST(LIBOBJFW_DEP, "../src/libobjfw.a")
	AC_SUBST(LIBOBJFW_DEP_LVL2, "../../src/libobjfw.a")
])

AS_IF([test x"$build_framework" = x"yes"], [
	TESTS_LIBS="-framework ObjFW \${RUNTIME_FRAMEWORK_LIBS} $TESTS_LIBS"
	TESTS_LIBS="-F../src -F../src/runtime $TESTS_LIBS"
], [
	TESTS_LIBS="\${RUNTIME_LIBS} $TESTS_LIBS"
	TESTS_LIBS="-L../src/runtime -L../src/runtime/linklib $TESTS_LIBS"
	TESTS_LIBS="-L../src -lobjfw $TESTS_LIBS"
])

AC_ARG_ENABLE(amiga-lib,
	AS_HELP_STRING([--disable-amiga-lib], [do not build Amiga library]))
AS_IF([test x"$supports_amiga_lib" != x"yes"], [enable_amiga_lib="no"])

AS_IF([test x"$enable_shared" = x"no" -a x"$enable_amiga_lib" = x"no"], [
	enable_static="yes"
])

AC_ARG_ENABLE(static, AS_HELP_STRING([--enable-static], [build static library]))
AS_IF([test x"$enable_static" = x"yes" -o x"$enable_amiga_lib" != x"no"], [
	AC_SUBST(OBJFW_STATIC_LIB, "libobjfw.a")
	AC_SUBST(EXCEPTIONS_A, "exceptions.a")
	AC_SUBST(EXCEPTIONS_EXCEPTIONS_A, "exceptions/exceptions.a")
	AC_SUBST(FORWARDING_A, "forwarding.a")
	AC_SUBST(FORWARDING_FORWARDING_A, "forwarding/forwarding.a")
	AC_SUBST(INVOCATION_A, "invocation.a")
	AC_SUBST(INVOCATION_INVOCATION_A, "invocation/invocation.a")
	AC_SUBST(LOOKUP_ASM_A, "lookup-asm.a")
	AC_SUBST(LOOKUP_ASM_LOOKUP_ASM_A, "lookup-asm/lookup-asm.a")
])

AC_DEFINE_UNQUOTED(PLUGIN_SUFFIX, "$PLUGIN_SUFFIX", [Suffix for plugins])
AS_IF([test x"$enable_files" != x"no" -a x"$PLUGIN_SUFFIX" != x""], [
	AC_SUBST(USE_SRCS_PLUGINS, '${SRCS_PLUGINS}')
	AC_SUBST(TESTPLUGIN, "plugin")
	AC_DEFINE(OF_HAVE_PLUGINS, 1, [Whether we have plugin support])

	AS_IF([test x"$build_framework" = x"yes"], [
		TESTPLUGIN_LIBS="-F../../src -F../../src/runtime"
		TESTPLUGIN_LIBS="$TESTPLUGIN_LIBS -framework ObjFW"
		TESTPLUGIN_LIBS="$TESTPLUGIN_LIBS \${RUNTIME_FRAMEWORK_LIBS}"
	], [
		TESTPLUGIN_LIBS="-L../../src -L../../src/runtime"
		TESTPLUGIN_LIBS="$TESTPLUGIN_LIBS -lobjfw \${RUNTIME_LIBS}"
	])
	AC_SUBST(TESTPLUGIN_LIBS)
])

AC_MSG_CHECKING(whether we need -D_GNU_SOURCE)
AC_EGREP_CPP(egrep_cpp_yes, [
	#include <stdlib.h>

	#if defined(__GLIBC__) || defined(__MINGW32__) || \
	    defined(__NEWLIB__) || defined(__MORPHOS__)
	egrep_cpp_yes
	#endif
], [
	CPPFLAGS="-D_GNU_SOURCE $CPPFLAGS"
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
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
		[use 24 bit instead of 16 bit for selector UIDs]))
AS_IF([test x"$enable_runtime" != x"yes"], [
	AS_IF([test x"$ac_cv_header_objc_objc_h" = x"yes"], [
		AC_EGREP_CPP(egrep_cpp_yes, [
			#import <objc/objc.h>

			#ifdef OBJC_BOOL_DEFINED
			egrep_cpp_yes
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
		OBJCFLAGS="$OBJCFLAGS -Xclang -fobjc-runtime=objfw"
		AC_TRY_LINK([
			#ifdef __has_attribute
			# if __has_attribute(objc_root_class)
			__attribute__((__objc_root_class__))
			# endif
			#endif
			@interface Test
			+ (void)test;
			@end

			@implementation Test
			+ (void)test
			{
			}
			@end

			void *
			objc_msg_lookup(void *obj, void *sel)
			{
				return (void *)0;
			}

			void
			__objc_exec_class(void *module)
			{
			}
		], [
			[Test test];
		], [
			flag="-Xclang -fobjc-runtime=objfw"
			OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flag"
			AC_MSG_RESULT(yes)
		], [
			flag="-fgnu-runtime"
			OBJCFLAGS="$old_OBJCFLAGS $flag"
			OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flag"
			AC_MSG_RESULT(no)
			old_compiler="yes"
		])

		AC_SUBST(RUNTIME, "runtime")

		AS_IF([test x"$enable_shared" != x"no"], [
			AC_SUBST(OBJFWRT_SHARED_LIB,
				"${LIB_PREFIX}objfwrt${LIB_SUFFIX}")
		])

		AS_IF([test x"$enable_static" = x"yes"], [
			AC_SUBST(OBJFWRT_STATIC_LIB, "libobjfwrt.a")
		])

		AS_IF([test x"$build_framework" = x"yes"], [
			AC_SUBST(OBJFWRT_FRAMEWORK, "ObjFWRT.framework")
			AC_SUBST(RUNTIME_FRAMEWORK_LIBS, "-framework ObjFWRT")
		])

		AS_IF([test x"$enable_amiga_lib" != x"no"], [
			AC_SUBST(RUNTIME_LIBS, "-lobjfwrt.library")
			AC_SUBST(LINKLIB, linklib)
			tmp="../src/runtime/linklib/libobjfwrt.library.a"
			AC_SUBST(LIBOBJFWRT_DEP, "$tmp")
			AC_SUBST(LIBOBJFWRT_DEP_LVL2, "../$tmp")
		], [
			AC_SUBST(RUNTIME_LIBS, "-lobjfwrt")
		])

		AS_IF([test x"$enable_shared" = x"no" \
				-a x"$enable_amiga_lib" = x"no"], [
			tmp="../src/runtime/libobjfwrt.a"
			AC_SUBST(LIBOBJFWRT_DEP, "$tmp")
			AC_SUBST(LIBOBJFWRT_DEP_LVL2, "../$tmp")
		])

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

			raise_exception="_Unwind_RaiseException"

			case "$exception_type" in
			DWARF)
				AC_DEFINE(HAVE_DWARF_EXCEPTIONS, 1,
					[Whether DWARF exceptions are used])
				;;
			SjLj)
				AC_DEFINE(HAVE_SJLJ_EXCEPTIONS, 1,
					[Whether SjLj exceptions are used])
				raise_exception="_Unwind_SjLj_RaiseException"
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

		AC_CHECK_FUNC($raise_exception, [], [
			AC_CHECK_LIB(c++, $raise_exception, [
				LIBS="-lc++ -lc++abi -lpthread $LIBS"
			], [
				AC_MSG_ERROR([_Unwind_RaiseException missing!])
			], [-lc++abi -lpthread])
		])

		AC_CHECK_FUNCS(_Unwind_GetDataRelBase _Unwind_GetTextRelBase)
		;;
	"Apple runtime")
		AC_DEFINE(OF_APPLE_RUNTIME, 1,
			[Whether we use the Apple ObjC runtime])

		AC_CHECK_LIB(objc, objc_msgSend, [
			AC_SUBST(RUNTIME_LIBS, "-lobjc")
			AC_SUBST(RUNTIME_FRAMEWORK_LIBS, "-lobjc")
		], [
			AC_MSG_ERROR([libobjc not found!])
		])
		;;
esac

AC_CHECK_FUNCS(_Unwind_Backtrace)

AC_CHECK_FUNC(objc_constructInstance, [], [
	AC_SUBST(INSTANCE_M, "instance.m")
])

AC_CHECK_FUNC(objc_autoreleasePoolPush, [], [
	AC_SUBST(AUTORELEASE_M, "autorelease.m")
])

case "$host_os" in
	darwin*)
		AC_SUBST(LDFLAGS_REEXPORT, ["-Wl,-reexport-lobjfw"])
		AS_IF([test x"$objc_runtime" = x"Apple runtime"], [
			AC_SUBST(REEXPORT_RUNTIME, ["-Wl,-reexport-lobjc"])
			AC_SUBST(REEXPORT_RUNTIME_FRAMEWORK,
				["-Wl,-reexport-lobjc"])
			LDFLAGS="$LDFLAGS -Wl,-U,_NSFoundationVersionNumber"
		])

		AS_IF([test x"$objc_runtime" = x"ObjFW runtime"], [
			AS_IF([test x"$exception_type" = x"DWARF"], [
				LDFLAGS="$LDFLAGS -Wl,-U,___gxx_personality_v0"
			])
			AS_IF([test x"$exception_type" = x"SjLj"], [
				LDFLAGS="$LDFLAGS -Wl,-U,___gxx_personality_sj0"
			])
			AC_SUBST(REEXPORT_RUNTIME, ["-Wl,-reexport-lobjfwrt"])
			AC_SUBST(REEXPORT_RUNTIME_FRAMEWORK,
				["-Wl,-reexport_framework,ObjFWRT"])
		])

		AC_CHECK_HEADERS(sysdir.h)
		AC_CHECK_FUNCS(sysdir_start_search_path_enumeration)

		AS_IF([test x"$host_is_ios" = x"yes"], [
			AC_SUBST(TESTS_STATIC_LIB, tests.a)
			TESTS_LIBS="$TESTS_LIBS -framework CoreFoundation"
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
AC_EGREP_CPP(egrep_cpp_yes, [
	#include <stdint.h>
	#include <limits.h>

	#ifdef SIZE_MAX
	egrep_cpp_yes
	#endif
], [
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
	AC_MSG_CHECKING(for SIZE_T_MAX)
	AC_EGREP_CPP(egrep_cpp_yes, [
		#include <stdint.h>
		#include <limits.h>

		#ifdef SIZE_T_MAX
		egrep_cpp_yes
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
AC_EGREP_CPP(egrep_cpp_yes, [
	#include <stdint.h>
	#include <limits.h>

	#ifdef SSIZE_MAX
	egrep_cpp_yes
	#endif
], [
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
	AC_DEFINE(SSIZE_MAX, [((ssize_t)(SIZE_MAX / 2))],
		[Maximum value for ssize_t])
])
AC_MSG_CHECKING(for UINTPTR_MAX)
AC_EGREP_CPP(egrep_cpp_yes, [
	#include <stdint.h>
	#include <limits.h>

	#ifdef UINTPTR_MAX
	egrep_cpp_yes
	#endif
], [
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
	AC_DEFINE(UINTPTR_MAX, [(~(uintptr_t)0)], [Maximum value for uintptr_t])
])

AC_CHECK_HEADER(inttypes.h,
	[AC_DEFINE(OF_HAVE_INTTYPES_H, 1, [Whether we have inttypes.h])])

AC_CHECK_HEADER(sys/types.h,
	[AC_DEFINE(OF_HAVE_SYS_TYPES_H, 1, [Whether we have sys/types.h])])

AC_CHECK_TYPE(max_align_t,
	[AC_DEFINE(OF_HAVE_MAX_ALIGN_T, 1, [Whether we have max_align_t])])

AC_CHECK_HEADER(stdnoreturn.h,
	[AC_DEFINE(OF_HAVE_STDNORETURN_H, 1, [Whether we have stdnoreturn.h])])

AC_CHECK_TYPE(wchar_t)
AC_CHECK_HEADER(wchar.h)

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

AC_MSG_CHECKING(for INFINITY)
AC_TRY_COMPILE([
	#include <stdio.h>
	#include <math.h>
], [
	printf("%f", INFINITY);
], [
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)

	AC_MSG_CHECKING(for __builtin_inf)
	AC_TRY_COMPILE([
		#include <stdio.h>
	], [
		printf("%f", __builtin_inf());
	], [
		AC_MSG_RESULT(yes)
		AC_DEFINE(INFINITY, [(__builtin_inf())],
			[Workaround for missing INFINITY])
	], [
		AC_MSG_RESULT(no)

		AC_MSG_ERROR([Neither INFINITY or __builtin_inf was found!])
	])
])

case "$host_cpu" in
	arm* | earm*)
		AC_MSG_CHECKING(for VFP2 or above)
		AC_TRY_COMPILE([], [
			#if !defined(__arm64__) && !defined(__aarch64__) && \
			    !defined(__ARM64_ARCH_8__)
			__asm__ __volatile__ (
			    "fstmfdd sp!, {d0-d7}"
			);
			#endif
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
AC_CHECK_LIB(complex, creal, TESTS_LIBS="$TESTS_LIBS -lcomplex")

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

AC_ARG_ENABLE(unicode-tables,
	AS_HELP_STRING([--disable-unicode-tables], [Disable Unicode tables]))
AS_IF([test x"$enable_unicode_tables" != x"no"], [
	AC_DEFINE(OF_HAVE_UNICODE_TABLES, 1,
		[Whether to build with Unicode tables])
	AC_SUBST(UNICODE_M, "unicode.m")
])

ENCODINGS_SRCS=""
AC_DEFUN([ENCODING_FLAG], [
	AC_ARG_ENABLE($1,
		AS_HELP_STRING([--disable-$1],
			[Disables support for $3]))
	AS_IF([test x"$enable_$2" != x"no"], [
		AC_DEFINE($4, 1,
			[Whether we have support for $3])
		ENCODINGS_SRCS="$ENCODINGS_SRCS $2.m"
	])
])
ENCODING_FLAG(codepage-437, codepage_437, [Codepage 437], HAVE_CODEPAGE_437)
ENCODING_FLAG(codepage-850, codepage_850, [Codepage 850], HAVE_CODEPAGE_850)
ENCODING_FLAG(codepage-858, codepage_858, [Codepage 858], HAVE_CODEPAGE_858)
ENCODING_FLAG(iso-8859-2, iso_8859-2, [ISO 8859-2], HAVE_ISO_8859_2)
ENCODING_FLAG(iso-8859-3, iso_8859-3, [ISO 8859-3], HAVE_ISO_8859_3)
ENCODING_FLAG(iso-8859-15, iso_8859-15, [ISO 8859-15], HAVE_ISO_8859_15)
ENCODING_FLAG(koi8-r, koi8-r, [KOI8-R], HAVE_KOI8_R)
ENCODING_FLAG(koi8-u, koi8-u, [KOI8-U], HAVE_KOI8_U)
ENCODING_FLAG(mac-roman, mac_roman, [Mac Roman encoding], HAVE_MAC_ROMAN)
ENCODING_FLAG(windows-1251, windows-1251, [Windows-1251], HAVE_WINDOWS_1251)
ENCODING_FLAG(windows-1252, windows-1252, [Windows-1252], HAVE_WINDOWS_1252)

AC_SUBST(ENCODINGS_SRCS)
AS_IF([test x"$ENCODINGS_SRCS" != x""], [
	AC_SUBST(ENCODINGS, "encodings")

	AS_IF([test x"$enable_shared" != x"no"], [
		AC_SUBST(ENCODINGS_LIB_A, "encodings.lib.a")
		AC_SUBST(ENCODINGS_ENCODINGS_LIB_A, "encodings/encodings.lib.a")
	])
	AS_IF([test x"$enable_static" = x"yes" -o x"$enable_shared" = x"no"], [
		AC_SUBST(ENCODINGS_A, "encodings.a")
		AC_SUBST(ENCODINGS_ENCODINGS_A, "encodings/encodings.a")
	])
])

AC_CHECK_FUNC(arc4random, [
	AC_DEFINE(OF_HAVE_ARC4RANDOM, 1, [Whether we have arc4random()])
], [
	AC_CHECK_FUNC(random, [
		AC_DEFINE(OF_HAVE_RANDOM, 1, [Whether we have random()])
	])
])

AS_IF([test x"$host_os" != x"morphos"], [
	AC_CHECK_LIB(dl, dlopen, LIBS="$LIBS -ldl")
])
AC_CHECK_HEADERS_ONCE(dlfcn.h)
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

AC_CHECK_HEADERS(sys/mman.h)
AC_CHECK_FUNCS(mmap mlock)

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

		dnl Use -Wp, as we only use it for the preprocessor.
		AX_CHECK_COMPILER_FLAGS([-Wp,-pthread], [
			CPPFLAGS="$CPPFLAGS -Wp,-pthread"
		], [
			CPPFLAGS="$CPPFLAGS -D_REENTRANT -D_THREAD_SAFE"
		])

		AC_CHECK_LIB(pthread, pthread_create, LIBS="$LIBS -lpthread")

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

		AC_CHECK_FUNCS(pthread_attr_getschedpolicy)
		AC_CHECK_FUNCS(pthread_attr_setinheritsched)

		AC_CHECK_HEADERS(pthread_np.h, [], [], [#include <pthread.h>])
		AC_CHECK_FUNCS(pthread_set_name_np pthread_setname_np, break)
		;;
	esac

	AC_DEFINE(OF_HAVE_THREADS, 1, [Whether we have threads])
	AC_SUBST(USE_SRCS_THREADS, '${SRCS_THREADS}')

	AC_ARG_ENABLE(compiler-tls,
		AS_HELP_STRING([--disable-compiler-tls],
			[disable compiler thread local storage]))

	case "$host" in
		aarch64*-*-android*)
			# Compiler TLS is broken on AArch64 Android with Clang
			enable_compiler_tls="no"
			;;
	esac

	AS_IF([test x"$enable_compiler_tls" != x"no"], [
		AC_CHECK_HEADER(threads.h, [
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
							[Whether __thread works]
						)
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
	])

	atomic_ops="none"

	AC_MSG_CHECKING(whether we have an atomic ops assembly implementation)
	AC_EGREP_CPP(egrep_cpp_yes, [
		#if defined(__GNUC__) && (defined(__i386__) || \
			defined(__x86_64__) || defined(__amd64__)) || \
			((defined(__ppc__) || defined(__PPC__) || \
			defined(__powerpc__)) && !defined(__APPLE_CC__))
		egrep_cpp_yes
		#endif
	], [
		AC_MSG_RESULT(yes)
		atomic_ops="assembly implementation"
	], [
		AC_MSG_RESULT(no)
	])

	AC_MSG_CHECKING(whether __atomic_* works)
	AC_TRY_LINK([
		#include <stdbool.h>
		#include <stdint.h>
	], [
		int32_t i, j;
		if (__atomic_add_fetch(&i, 1, __ATOMIC_RELAXED))
			j = __atomic_sub_fetch(&i, 1, __ATOMIC_RELAXED);
		while (!__atomic_compare_exchange_n(&i, &j, 1, false,
		    __ATOMIC_RELAXED, __ATOMIC_RELAXED));
		__atomic_thread_fence(__ATOMIC_SEQ_CST);
	], [
		AC_MSG_RESULT(yes)
		test x"$atomic_ops" = x"none" && \
			atomic_ops="__atomic_* builtins"
		AC_DEFINE(OF_HAVE_ATOMIC_BUILTINS, 1,
			[Whether __atomic_* builtins are available])
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
		test x"$atomic_ops" = x"none" && \
			atomic_ops="__sync_* builtins"
		AC_DEFINE(OF_HAVE_SYNC_BUILTINS, 1,
			[Whether __sync_* builtins are available])
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
	AC_SUBST(USE_INCLUDES_ATOMIC, '${INCLUDES_ATOMIC}')
])
AC_MSG_RESULT($atomic_ops)

AC_ARG_ENABLE(files,
	AS_HELP_STRING([--disable-files], [disable file support]))
AS_IF([test x"$enable_files" != x"no"], [
	AC_DEFINE(OF_HAVE_FILES, 1, [Whether we have files])
	AC_SUBST(USE_SRCS_FILES, '${SRCS_FILES}')
	AC_SUBST(OFARC, "ofarc")
	AC_SUBST(OFHASH, "ofhash")

	case "$host_os" in
		msdosdjgpp*)
			dnl DJGPP has the type, but it's not really usable.
			;;
		*)
			AC_CHECK_TYPE(off64_t, [
				AC_DEFINE(OF_HAVE_OFF64_T, 1,
					[Whether we have off64_t])
			])
			;;
	esac

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
	AC_CHECK_FUNCS([lstat])
	AC_CHECK_MEMBERS([struct stat.st_birthtime], [], [], [
		#include <sys/stat.h>
	])

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Werror"
	AC_MSG_CHECKING(for readdir_r)
	AC_TRY_COMPILE([
		#include <dirent.h>
	], [
		DIR *dir = 0;
		struct dirent entry, *result;

		readdir_r(dir, &entry, &result);
	], [
		AC_MSG_RESULT(yes)
		AC_DEFINE(HAVE_READDIR_R, 1, [Whether we have readdir_r()])
	], [
		AC_MSG_RESULT(no)
	])
	OBJCFLAGS="$old_OBJCFLAGS"
])

AC_CHECK_HEADERS(fcntl.h dirent.h)
AC_CHECK_FUNCS([sysconf gmtime_r localtime_r nanosleep fcntl])

AC_CHECK_HEADERS(xlocale.h)
AC_CHECK_FUNCS([strtod_l strtof_l asprintf_l])

AC_CHECK_HEADERS(sys/utsname.h)
AC_CHECK_FUNCS(uname)

case "$host_os" in
	amigaos*)
		;;
	*)
		AC_CHECK_FUNC(pipe, [
			AC_DEFINE(OF_HAVE_PIPE, 1, [Whether we have pipe()])
		])
		;;
esac

AC_ARG_ENABLE(sockets,
	AS_HELP_STRING([--disable-sockets], [disable socket support]))
AS_IF([test x"$enable_sockets" != x"no"], [
	AC_DEFINE(OF_HAVE_SOCKETS, 1, [Whether we have sockets])
	AC_SUBST(USE_SRCS_SOCKETS, '${SRCS_SOCKETS}')

	case "$host_os" in
		amigaos*)
			;;
		haiku*)
			LIBS="$LIBS -lnetwork"
			;;
		mingw*)
			LIBS="$LIBS -lws2_32 -liphlpapi"
			;;
		*)
			AC_CHECK_LIB(socket, socket, LIBS="$LIBS -lsocket")
			;;
	esac

	AC_CHECK_HEADER(sys/socket.h, [
		AC_DEFINE(OF_HAVE_SYS_SOCKET_H, 1,
			[Whether we have sys/socket.h])
	])
	AC_CHECK_HEADER(netinet/in.h, [
		AC_DEFINE(OF_HAVE_NETINET_IN_H, 1,
			[Whether we have netinet/in.h])
	])
	AC_CHECK_HEADER(netinet/tcp.h, [
		AC_DEFINE(OF_HAVE_NETINET_TCP_H, 1,
			[Whether we have netinet/tcp.h])
	])
	AC_CHECK_HEADERS([arpa/inet.h netdb.h])

	AC_CHECK_MEMBER([struct sockaddr_in6.sin6_addr], [
		AC_EGREP_CPP(egrep_cpp_yes, [
			#ifdef _WIN32
			typedef int BOOL;
			#endif

			#ifdef OF_HAVE_SYS_SOCKET_H
			# include <sys/socket.h>
			#endif

			#ifdef _WIN32
			# ifdef __MINGW32__
			#  include <_mingw.h>
			#  ifdef __MINGW64_VERSION_MAJOR
			#   include <winsock2.h>
			#  endif
			# endif
			# include <windows.h>
			# include <ws2tcpip.h>
			#endif

			#ifdef AF_INET6
			egrep_cpp_yes
			#endif
		], [
			AC_DEFINE(OF_HAVE_IPV6, 1, [Whether we have IPv6])
		])
	], [
	], [
		#ifdef _WIN32
		typedef int BOOL;
		#endif

		#ifdef OF_HAVE_NETINET_IN_H
		# include <netinet/in.h>
		#endif

		#ifdef _WIN32
		# ifdef __MINGW32__
		#  include <_mingw.h>
		#  ifdef __MINGW64_VERSION_MAJOR
		#   include <winsock2.h>
		#  endif
		# endif
		# include <windows.h>
		# include <ws2tcpip.h>
		#endif
	])

	AC_CHECK_FUNCS(paccept accept4, break)

	AC_CHECK_FUNCS(kqueue1 kqueue, [
		AC_DEFINE(HAVE_KQUEUE, 1, [Whether we have kqueue])
		AC_SUBST(OFKQUEUEKERNELEVENTOBSERVER_M,
			"OFKqueueKernelEventObserver.m")
		break
	])
	AC_CHECK_FUNCS(epoll_create1 epoll_create, [
		AC_DEFINE(HAVE_EPOLL, 1, [Whether we have epoll])
		AC_SUBST(OFEPOLLKERNELEVENTOBSERVER_M,
			"OFEpollKernelEventObserver.m")
		break
	])

	AS_IF([test x"$with_wii" = x"yes"], [
		AC_DEFINE(HAVE_POLL, 1, [Whether we have poll()])
		AC_SUBST(OFPOLLKERNELEVENTOBSERVER_M,
			"OFPollKernelEventObserver.m")
	], [
		AC_CHECK_HEADERS(poll.h)
		AC_CHECK_FUNC(poll, [
			AC_DEFINE(HAVE_POLL, 1, [Whether we have poll()])
			AC_SUBST(OFPOLLKERNELEVENTOBSERVER_M,
				"OFPollKernelEventObserver.m")
		])
	])

	case "$host_os" in
		amigaos* | mingw* | morphos*)
			AC_DEFINE(HAVE_SELECT, 1,
				[Whether we have select() or similar])
			AC_SUBST(OFSELECTKERNELEVENTOBSERVER_M,
				"OFSelectKernelEventObserver.m")
			;;
		*)
			AC_CHECK_HEADERS(sys/select.h)
			AC_CHECK_FUNC(select, [
				AC_DEFINE(HAVE_SELECT, 1,
					[Whether we have select() or similar])
				AC_SUBST(OFSELECTKERNELEVENTOBSERVER_M,
					"OFSelectKernelEventObserver.m")
			])
			;;
	esac

	AS_IF([test x"$enable_threads" != x"no"], [
		AC_SUBST(OFHTTPCLIENTTESTS_M, "OFHTTPClientTests.m")
	])

	AC_SUBST(OFDNS, "ofdns")
	AS_IF([test x"$enable_files" != x"no"], [
		AC_SUBST(OFHTTP, "ofhttp")
	])
])

AC_DEFUN([CHECK_BUILTIN_BSWAP], [
	AC_MSG_CHECKING(for __builtin_bswap$1)
	AC_TRY_LINK([
		#include <stdint.h>
		#include <stdio.h>
		#include <errno.h>
	], [
		uint$1_t i = errno;
		printf("%d", (int)__builtin_bswap$1(i));
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
		AC_HEADER_SYS_WAIT
		AC_CHECK_FUNCS(kill)

		AC_CHECK_FUNCS(posix_spawnp, [
			AS_IF([test x"$ac_cv_func_kill" = x"yes"], [
				have_processes="yes"

				AC_CHECK_HEADERS(spawn.h)
			])
		], [
			AC_CHECK_FUNCS([vfork dup2 execvp _exit], [
				AS_IF([test x"$ac_cv_func_vfork" = x"yes" \
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
		])
		;;
esac
AS_IF([test x"$have_processes" = x"yes"], [
	AC_SUBST(OFPROCESS_M, "OFProcess.m")
	AC_DEFINE(OF_HAVE_PROCESSES, 1, [Whether we have processes])
])

AC_CHECK_HEADERS_ONCE([complex.h sys/ioctl.h sys/ttycom.h])

AC_CHECK_FUNC(pledge, [
	AC_DEFINE(OF_HAVE_PLEDGE, 1, [Whether we have pledge()])
])

AS_IF([test x"$objc_runtime" = x"Apple runtime"], [
	AC_CHECK_HEADER(Foundation/NSObject.h, [
		AC_SUBST(FOUNDATION_COMPAT_M, "foundation-compat.m")
		AC_SUBST(BRIDGE, "bridge")

		AS_IF([test x"$enable_shared" != x"no"], [
			AC_SUBST(OBJFWBRIDGE_SHARED_LIB,
				"${LIB_PREFIX}objfwbridge${LIB_SUFFIX}")
		])
		AS_IF([test x"$enable_static" = x"yes" \
		    -o x"$enable_shared" = x"no"], [
			AC_SUBST(OBJFWBRIDGE_STATIC_LIB, "libobjfwbridge.a")
		])
		AS_IF([test x"$build_framework" = x"yes"], [
			AC_SUBST(OBJFWBRIDGE_FRAMEWORK,
				"ObjFWBridge.framework")
		])
	])
])

dnl This needs to be after all other header checks, as they include unistd.h,
dnl which in old glibc versions uses __block. This is worked around in the code
dnl by providing a wrapper for unistd.h which takes care of this.
AC_MSG_CHECKING(whether Objective C compiler supports blocks)
old_OBJCFLAGS="$OBJCFLAGS"
OBJCFLAGS="$OBJCFLAGS -Xclang -fblocks"
AC_TRY_COMPILE([], [
	int (^foo)(int bar);
	foo = ^ (int bar) { return 0; }
], [
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS -Xclang -fblocks"
	AC_SUBST(OFBLOCKTESTS_M, "OFBlockTests.m")
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
	OBJCFLAGS="$old_OBJCFLAGS"
])

AS_IF([test x"$GOBJC" = x"yes"], [
	OBJCFLAGS="$OBJCFLAGS -Wwrite-strings -Wpointer-arith -Werror"

	AC_MSG_CHECKING(whether we need -Wno-strict-aliasing due to GCC bugs)
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

		static struct {
			struct objc_class *_isa;
		} object;
	], [
		Foo *test = (Foo *)&object;
		(void)test; /* Get rid of unused variable warning */
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$OBJCFLAGS -Wno-strict-aliasing"
	])

	AC_MSG_CHECKING(
	    whether we need -Wno-unused-property-ivar due to Clang bugs)
	AC_TRY_COMPILE([
		#ifdef __has_attribute
		# if __has_attribute(objc_root_class)
		__attribute__((__objc_root_class__))
		# endif
		#endif
		@interface Foo
		{
			struct objc_class *_isa;
			Foo *_foo;
		}

		@property (readonly, nonatomic) Foo *foo;

		+ (Foo *)foo;
		@end

		@implementation Foo
		@synthesize foo = _foo;

		+ (Foo *)foo
		{
			return (Foo *)0;
		}
		@end
	], [
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$OBJCFLAGS -Wno-unused-property-ivar"
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
	OBJCFLAGS="$OBJCFLAGS -Wunreachable-code"
	AC_MSG_CHECKING(whether -Wunreachable-code can be used)
	AC_TRY_COMPILE([
		#include <stdlib.h>

		typedef void *SEL;

		#ifdef __has_attribute
		# if __has_attribute(objc_root_class)
		__attribute__((__objc_root_class__))
		# endif
		#endif
		@interface Object
		- (void)doesNotRecognizeSelector: (SEL)selector
		#ifdef __clang__
		    __attribute__((__noreturn__))
		#endif
		    ;
		- (void)dealloc;
		@end

		@interface Foo: Object
		@end

		void
		test(void)
		{
			if (sizeof(int) == 4)
				__asm__ ("");
			else if (sizeof(int) == 8)
				__asm__ ("");
			else
				abort();
		}

		/*
		 * Unfortunately, this cannot be shorter, as it only works when
		 * it is used inside a macro.
		 */
		#ifdef __clang__
		# define OF_DEALLOC_UNSUPPORTED				\
			[self doesNotRecognizeSelector: _cmd];		\
									\
			abort();					\
									\
			_Pragma("clang diagnostic push ignore \"-Wunreachable-code\"");	\
			[super dealloc];				\
			_Pragma("clang diagnostic pop");
		#else
		# define OF_DEALLOC_UNSUPPORTED				\
			[self doesNotRecognizeSelector: _cmd];		\
									\
			abort();					\
									\
			[super dealloc];
		#endif

		@implementation Foo
		- (void)dealloc
		{
			OF_DEALLOC_UNSUPPORTED
		}
		@end
	], [], [
		AC_MSG_RESULT(yes)
	], [
		AC_MSG_RESULT(no)
		OBJCFLAGS="$old_OBJCFLAGS"
	])

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Wdocumentation"
	AC_MSG_CHECKING(whether -Wdocumentation works correctly)
	AC_TRY_COMPILE([
		/*!
		 * @class Test conftest.m conftest.m
		 */
		#ifdef __has_attribute
		# if __has_attribute(objc_root_class)
		__attribute__((__objc_root_class__))
		# endif
		#endif
		@interface Test
		@end
	], [
	], [
		AC_MSG_RESULT(yes)
	], [
		AC_MSG_RESULT(no)
		OBJCFLAGS="$old_OBJCFLAGS"
	])

	AS_IF([test x"$check_pedantic" = x"yes"], [
		old_OBJCFLAGS="$OBJCFLAGS"
		OBJCFLAGS="$OBJCFLAGS -pedantic"
		AC_MSG_CHECKING(whether -pedantic is buggy)
		AC_TRY_COMPILE([
			#include <stdlib.h>

			#include <assert.h>

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
			- (void)assert;
			@end

			@implementation Bar
			- (void)assert
			{
				/*
				 * Some versions of glibc break with -pedantic
				 * when using assert.
				 */
				assert(1);
			}
			@end
		], [], [
			AC_MSG_RESULT(no)
		], [
			AC_MSG_RESULT(yes)
			OBJCFLAGS="$old_OBJCFLAGS"
		])
	])

	AS_IF([test x"$ac_cv_header_complex_h" = x"yes"], [
		AC_MSG_CHECKING(whether we need -Wno-gnu-imaginary-constant)
		AC_TRY_COMPILE([
			#include <complex.h>
		], [
			complex float f = 0.5 + 0.5 * I;
			(void)f;
		], [
			AC_MSG_RESULT(no)
		], [
			AC_MSG_RESULT(yes)
			OBJCFLAGS="$OBJCFLAGS -Wno-gnu-imaginary-constant"
		])
	])
])

AS_IF([test x"$cross_compiling" = x"yes"], [
	AC_SUBST(BIN_PREFIX, "${host_alias}-")

	case "$host" in
		i?86-*-mingw*)
			AC_CHECK_PROG(WINE, wine, wine)
			;;
		x86_64-*-mingw*)
			AC_CHECK_PROG(WINE, wine64, wine64)
			;;
	esac

	AS_IF([test x"$WINE" != x""], [
		AC_SUBST(RUN_TESTS, "run")
		AC_SUBST(WRAPPER, "$WINE")
	])

	AS_IF([test x"$with_wii" = x"yes"], [
		dnl Keep this lowercase, as WIILOAD is a variable used by
		dnl wiiload and thus likely already set by the user to something
		dnl that is not the path of the wiiload binary.
		AC_CHECK_PROG(wiiload, wiiload, wiiload)

		AS_IF([test x"$wiiload" != x""], [
			AC_SUBST(WRAPPER, "$wiiload")
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

AC_SUBST(OBJFW_CPPFLAGS)
AC_SUBST(OBJFW_OBJCFLAGS)

AC_SUBST(TESTS_LIBS)

AC_CONFIG_FILES([
	buildsys.mk
	extra.mk
	src/Info.plist
	src/bridge/Info.plist
	tests/Info.plist
	tests/plugin/Info.plist
	utils/objfw-config
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
