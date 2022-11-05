AC_INIT(ObjFW, 1.1dev, js@nil.im)
AC_CONFIG_SRCDIR(src)
AC_CONFIG_AUX_DIR(build-aux)
AC_CONFIG_MACRO_DIR(build-aux/m4)

AC_DEFINE(OBJFW_VERSION_MAJOR, 1, [The major version of ObjFW])
AC_DEFINE(OBJFW_VERSION_MINOR, 1, [The minor version of ObjFW])
dnl This may only be set to 1.1 once 1.1 is released
AC_SUBST(BUNDLE_VERSION, 1.0.0)
AC_SUBST(BUNDLE_SHORT_VERSION, 1.0)

for i in configure.ac build-aux/m4/*; do
	AS_IF([test $i -nt configure], [
		AC_MSG_ERROR([$i is newer than configure! Run ./autogen.sh!])
	])
done

BUILDSYS_INIT

AC_CANONICAL_HOST

dnl Used to disable checking for -pedantic on some platforms where it's broken
check_pedantic="yes"

case "$host" in
arm-*-riscos*)
	AS_IF([test x"$OBJCFLAGS" = x""], [OBJCFLAGS="-O2 -g"])
	flags="-mfloat-abi=softfp -mfpu=vfp -mlibscl"
	ASFLAGS="$ASFLAGS -mfloat-abi=softfp -mfpu=vfp"
	OBJCFLAGS="$OBJCFLAGS $flags"
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flags"
	LDFLAGS="$LDFLAGS $flags"

	enable_shared="no"
	enable_threads="no"
	enable_sockets="no"
	enable_files="no"
	;;
m68k-*-amigaos*)
	AS_IF([test x"$OBJCFLAGS" = x""], [OBJCFLAGS="-O0"])
	OBJCFLAGS="$OBJCFLAGS -noixemul"
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS -noixemul"
	CPPFLAGS="$CPPFLAGS -D__NO_NET_API"
	LDFLAGS="$LDFLAGS -noixemul"
	LIBS="$LIBS -ldebug"

	enable_files="yes"	# Required for reading ENV:
	enable_shared="no"
	with_tls="no"
	supports_amiga_lib="yes"

	AS_IF([test x"$enable_amiga_lib" != x"no"], [
		AC_SUBST(OBJFWRT_AMIGA_LIB,
			['objfwrt${OBJFWRT_LIB_MAJOR}.library'])
		dnl For 68000, GCC emits calls to helper functions that
		dnl do not work properly in a library.
		t="-mcpu=68020 -fbaserel -noixemul -ffreestanding"
		AC_SUBST(AMIGA_LIB_CFLAGS, $t)
		t="$t -resident -nostartfiles -nodefaultlibs -ldebug -lc"
		AC_SUBST(AMIGA_LIB_LDFLAGS, $t)
	])

	AC_SUBST(LIBBASES_M, libbases.m)
	;;
powerpc-*-amigaos*)
	CPPFLAGS="$CPPFLAGS -D__USE_INLINE__"

	enable_files="yes"	# Required for reading ENV:
	enable_shared="no"
	with_tls="no"

	AC_SUBST(LIBBASES_M, libbases.m)
	;;
*-morphos*)
	AS_IF([test x"$OBJCFLAGS" = x""], [OBJCFLAGS="-O2 -g"])
	OBJCFLAGS="$OBJCFLAGS -noixemul"
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS -noixemul"
	LDFLAGS="$LDFLAGS -noixemul"
	LIBS="$LIBS -ldebug"

	enable_files="yes"	# Required for reading ENV:
	enable_shared="no"
	supports_amiga_lib="yes"

	AS_IF([test x"$enable_amiga_lib" != x"no"], [
		AC_SUBST(OBJFWRT_AMIGA_LIB,
			['objfwrt${OBJFW_LIB_MAJOR}ppc.library'])
		t="-mresident32 -ffreestanding -noixemul"
		AC_SUBST(AMIGA_LIB_CFLAGS, $t)
		t="-mresident32 -nostartfiles -nodefaultlibs -noixemul -ldebug"
		AC_SUBST(AMIGA_LIB_LDFLAGS, "$t -lc")
	])

	AC_SUBST(LIBBASES_M, libbases.m)
	;;
*-msdosdjgpp*)
	enable_shared="no"
	enable_threads="no"
	enable_sockets="no"
	;;
*-*-mingw*)
	LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition -static-libgcc"
	LIBS="$LIBS -lversion"

	AC_SUBST(USE_SRCS_WINDOWS, '${SRCS_WINDOWS}')
	;;
*-psp-*)
	AS_IF([test x"$DEVKITPSP" = x""], [
		AC_MSG_ERROR([DEVKITPSP is not set! Please set DEVKITPSP.])
	])

	AS_IF([test x"$OBJCFLAGS" = x""], [OBJCFLAGS="-O2"])
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
hppa*-*-hpux*)
	dnl Don't default to -g: It creates errors from the assembler and breaks
	dnl exceptions.
	AS_IF([test x"$OBJCFLAGS" = x""], [OBJCFLAGS="-O2"])
	dnl HP-UX 11.11's inttypes.h defines UINTPTR_MAX etc. to nothing. GCC's
	dnl stdint.h defines those correctly, but if inttypes.h gets included
	dnl after something included stdint.h, it gets broken again. Therefore,
	dnl always include inttypes.h as the very first thing.
	dnl We need to put this into OBJCFLAGS and not CPPFLAGS as CPPFLAGS are
	dnl also used for .S files.
	OBJCFLAGS="$OBJCFLAGS -include inttypes.h"
	dnl We need -latomic for GCC's atomics to work.
	LIBS="$LIBS -latomic"
	;;
*-*-mint*)
	enable_shared="no"
	enable_threads="no"	# TODO
	with_tls="no"
	;;
esac

AS_IF([test x"$host_os" = x"msdosdjgpp" -a x"$build_os" = x"msdosdjgpp"], [
	dnl Hack to make configure find these on DOS.
	: ${AR:=ar.exe}
	: ${GREP:=grep.exe}
	: ${RANLIB:=ranlib.exe}
])

AC_LANG([Objective C])
case "$host_os" in
morphos*)
	dnl Don't use clang on MorphOS - it does not support baserel, which is
	dnl required for the .library.
	potential_compilers="gcc"
	;;
*)
	potential_compilers="clang egcc gcc"
	;;
esac
AC_PROG_OBJC($potential_compilers)
AC_PROG_OBJCPP
AC_PROG_LN_S
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
	OBJFW_CPPFLAGS="$OBJFW_CPPFLAGS -DGEKKO -I\$DEVKITPRO/libogc/include"
	LDFLAGS="$LDFLAGS -mrvl -mcpu=750 -meabi -mhard-float"
	LIBS="$LIBS -L$DEVKITPRO/libogc/lib/wii -lfat -logc"
	TESTS_LIBS="$TESTS_LIBS -lwiiuse -lbte"
	enable_shared="no"
	enable_threads="no"	# TODO
	with_tls="no"

	AC_DEFINE(OF_WII, 1, [Whether we are compiling for Wii])
	AC_SUBST(MAP_LDFLAGS, ['-Wl,-Map,$@.map'])
])

AC_ARG_WITH(wii-u,
	AS_HELP_STRING([--with-wii-u], [build for Wii U]))
AS_IF([test x"$with_wii_u" = x"yes"], [
	AS_IF([test x"$DEVKITPRO" = x""], [
		AC_MSG_ERROR([DEVKITPRO is not set! Please set DEVKITPRO.])
	])

	flags="-mcpu=750 -meabi -mhard-float"
	OBJCFLAGS="$OBJCFLAGS $flags"
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flags"
	CPPFLAGS="-isystem $DEVKITPRO/wut/include -D__WIIU__ -D__WUT__"
	OBJFW_CPPFLAGS="$OBJFW_CPPFLAGS -isystem \$DEVKITPRO/wut/include"
	OBJFW_CPPFLAGS="$OBJFW_CPPFLAGS -D__WIIU__ -D__WUT__"
	LDFLAGS="-specs=$DEVKITPRO/wut/share/wut.specs"
	LIBS="-L$DEVKITPRO/wut/lib -L$DEVKITPRO/wut/lib/stubs -lwut"
	enable_files="no"	# TODO
	enable_shared="no"	# TODO
	enable_threads="no"	# TODO
	enable_sockets="no"	# TODO

	AC_DEFINE(OF_WII_U, 1, [Whether we are compiling for Wii U])
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
	OBJFW_CPPFLAGS="$OBJFW_CPPFLAGS -DARM9 -I\$DEVKITPRO/libnds/include"
	ASFLAGS="$ASFLAGS -march=armv5te"
	LDFLAGS="$LDFLAGS -specs=ds_arm9.specs"
	LIBS="$LIBS -L$DEVKITPRO/libnds/lib -lfilesystem -lfat -lnds9"
	enable_shared="no"
	enable_threads="no"	# TODO
	enable_sockets="no"	# TODO
	check_pedantic="no"

	AC_DEFINE(OF_NINTENDO_DS, 1, [Whether we are compiling for Nintendo DS])
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
	OBJFW_CPPFLAGS="$OBJFW_CPPFLAGS -DARM11 -I\$DEVKITPRO/libctru/include"
	ASFLAGS="$ASFLAGS -march=armv6k"
	LDFLAGS="$LDFLAGS -specs=3dsx.specs -march=armv6k -mtune=mpcore"
	LDFLAGS="$LDFLAGS -mfloat-abi=hard -mtp=soft -mword-relocations"
	LIBS="$LIBS -L$DEVKITPRO/libctru/lib -lctru"
	enable_shared="no"
	enable_threads="no"	# TODO
	with_tls="no"
	check_pedantic="no"

	AC_DEFINE(OF_NINTENDO_3DS, 1,
		[Whether we are compiling for Nintendo 3DS])
	AC_SUBST(MAP_LDFLAGS, ['-Wl,-Map,$@.map'])
])

AC_ARG_WITH(nintendo-switch,
	AS_HELP_STRING([--with-nintendo-switch], [build for Nintendo Switch]))
AS_IF([test x"$with_nintendo_switch" = x"yes"], [
	AS_IF([test x"$DEVKITPRO" = x""], [
		AC_MSG_ERROR([DEVKITPRO is not set! Please set DEVKITPRO.])
	])

	flags="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIE"
	OBJCFLAGS="$OBJCFLAGS $flags"
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS $flags"
	CPPFLAGS="$CPPFLAGS -D__SWITCH__ -I$DEVKITPRO/libnx/include"
	OBJFW_CPPFLAGS="$OBJFW_CPPFLAGS -D__SWITCH__ -I$DEVKITPRO/libnx/include"
	ASFLAGS="$ASFLAGS $flags"
	LDFLAGS="$LDFLAGS -specs=$DEVKITPRO/libnx/switch.specs $flags"
	LIBS="$LIBS -L$DEVKITPRO/libnx/lib -lnx"
	enable_shared="no"
	enable_threads="yes"
	enable_sockets="no"	# TODO
	check_pedantic="no"

	AC_DEFINE(OF_NINTENDO_SWITCH, 1,
		[Whether we are compiling for Nintendo Switch])
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
	mips*-*-*)
		dnl Clang generates MIPS assembly not accepted by GNU as,
		dnl however, Clang's integrated assembler doesn't accept
		dnl everything used in ObjFW's assembly files. Therefore, use
		dnl the integrated assembler for ObjC files, but not for
		dnl assembly files.
		OBJCFLAGS="$OBJCFLAGS -integrated-as"
		OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS -integrated-as"
		;;
	i?86-*-darwin* | x86_64-*-darwin*)
		dnl Don't use -no-integrated-as on Darwin. It breaks building
		dnl for the iOS simulator.
		;;
	sparc64-*-*openbsd*)
		dnl Clang generates assembly output on SPARC64 that OpenBSD's
		dnl assembler does not accept.
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

AX_CHECK_COMPILER_FLAGS(-pipe, [OBJCFLAGS="$OBJCFLAGS -pipe"])
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
	dnl The inline headers generate code that triggers -Wpointer-sign.
	OBJCFLAGS="$OBJCFLAGS -Wno-pointer-sign"
	;;
esac

AC_MSG_CHECKING(whether Objective C compiler supports properties)
AC_COMPILE_IFELSE([
	AC_LANG_PROGRAM([
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
	], [[
		Foo *foo = (id)0;
		[foo setBar: (id)0];
		foo = [foo bar];
	]])
], [
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
	AC_MSG_ERROR(Compiler does not support properties!)
])

AC_CHECK_TOOL(AR, ar)
AC_PROG_RANLIB

case "$host_os" in
mingw*)
	AC_CHECK_TOOL(RC, windres)
	;;
esac

AC_ARG_ENABLE(shared,
	AS_HELP_STRING([--disable-shared], [do not build shared library]))
AS_IF([test x"$enable_shared" != x"no"], [
	BUILDSYS_SHARED_LIB
	AC_SUBST(OBJFW_SHARED_LIB, "${LIB_PREFIX}objfw${LIB_SUFFIX}")
	AC_SUBST(EXCEPTIONS_LIB_A, "exceptions.lib.a")
	AC_SUBST(FORWARDING_LIB_A, "forwarding.lib.a")
	AC_SUBST(LOOKUP_ASM_LIB_A, "lookup-asm.lib.a")

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
AS_IF([test x"$enable_amiga_lib" != x"no"], [
	AC_SUBST(OBJFW_STATIC_LIB, "libobjfw.a")
	AC_SUBST(EXCEPTIONS_A, "exceptions.a")
	AC_SUBST(FORWARDING_A, "forwarding.a")
	AC_SUBST(LOOKUP_ASM_AMIGALIB_A, "lookup-asm.amigalib.a")
])

AC_ARG_ENABLE(static, AS_HELP_STRING([--enable-static], [build static library]))
AS_IF([test x"$enable_shared" = x"no" -a x"$enable_amiga_lib" = x"no"], [
	enable_static="yes"
])
AS_IF([test x"$enable_static" = x"yes"], [
	AC_SUBST(OBJFW_STATIC_LIB, "libobjfw.a")
	AC_SUBST(EXCEPTIONS_A, "exceptions.a")
	AC_SUBST(FORWARDING_A, "forwarding.a")
	AC_SUBST(LOOKUP_ASM_A, "lookup-asm.a")
])

AC_DEFINE_UNQUOTED(PLUGIN_SUFFIX, "$PLUGIN_SUFFIX", [Suffix for plugins])
AS_IF([test x"$enable_files" != x"no" -a x"$PLUGIN_SUFFIX" != x""], [
	AC_SUBST(USE_SRCS_PLUGINS, '${SRCS_PLUGINS}')
	AC_SUBST(TESTPLUGIN, "plugin")
	AC_DEFINE(OF_HAVE_PLUGINS, 1, [Whether we have plugin support])
	AC_CONFIG_FILES(tests/plugin/Info.plist)

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
	    defined(__NEWLIB__) || defined(__MORPHOS__) || defined(__MINT__)
	egrep_cpp_yes
	#endif
], [
	AC_MSG_RESULT(yes)
	CPPFLAGS="-D_FILE_OFFSET_BITS=64 -D_TIME_BITS=64 $CPPFLAGS"
	CPPFLAGS="-D_GNU_SOURCE $CPPFLAGS"
	gnu_source="yes"
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
	AC_DEFINE(OF_OBJFW_RUNTIME, 1, [Whether we use the ObjFW runtime])

	AC_MSG_CHECKING([whether -fobjc-runtime=objfw is supported])

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Xclang -fobjc-runtime=objfw"
	AC_LINK_IFELSE([
		AC_LANG_PROGRAM([
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
		], [[
			[Test test];
		]])
	], [
		OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS -Xclang -fobjc-runtime=objfw"
		AC_MSG_RESULT(yes)
	], [
		OBJCFLAGS="$old_OBJCFLAGS -fgnu-runtime"
		OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS -fgnu-runtime"
		AC_MSG_RESULT(no)
		old_compiler="yes"
	])

	AC_SUBST(RUNTIME, "runtime")
	AC_CONFIG_FILES(src/runtime/Info.plist)

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
		AC_SUBST(LIBOBJFWRT_DEP, "../src/runtime/libobjfwrt.a")
		AC_SUBST(LIBOBJFWRT_DEP_LVL2, "../../src/runtime/libobjfwrt.a")
	])

	AS_IF([test x"$enable_seluid24" = x"yes"], [
		AC_DEFINE(OF_SELUID24, 1, [Whether to use 24 bit selector UIDs])
	])

	AC_MSG_CHECKING(for exception type)
	AC_COMPILE_IFELSE([
		AC_LANG_PROGRAM([
			extern void foo();
		], [
			@try {
				foo();
			} @finally {
				foo();
			}
		])
	], [
		AS_IF([$EGREP __gnu_objc_personality_v0 conftest.$ac_objext \
		    >/dev/null], [
			exception_type="DWARF"
		])
		AS_IF([$EGREP __gnu_objc_personality_sj0 conftest.$ac_objext \
		    >/dev/null], [
			exception_type="SjLj"
		])
		AS_IF([$EGREP __gnu_objc_personality_seh0 conftest.$ac_objext \
		    >/dev/null], [
			exception_type="SEH"
		])

		case "$exception_type" in
		DWARF)
			AC_DEFINE(HAVE_DWARF_EXCEPTIONS, 1,
				[Whether DWARF exceptions are used])
			raise_exception="_Unwind_RaiseException"
			;;
		SjLj)
			AC_DEFINE(HAVE_SJLJ_EXCEPTIONS, 1,
				[Whether SjLj exceptions are used])
			raise_exception="_Unwind_SjLj_RaiseException"
			;;
		SEH)
			AC_DEFINE(HAVE_SEH_EXCEPTIONS, 1,
				[Whether SEH exceptions are used])
			raise_exception="_Unwind_RaiseException"
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

	AC_SEARCH_LIBS($raise_exception, [c++abi gcc_s gcc unwind], [
		dnl c++abi requires pthread on OpenBSD
		AS_IF([test x"$ac_lib" = x"c++abi"], [LIBS="$LIBS -lpthread"])
	], [
		AC_MSG_ERROR([$raise_exception missing!])
	], [-lpthread])

	AC_CHECK_FUNCS(_Unwind_GetDataRelBase _Unwind_GetTextRelBase)
	;;
"Apple runtime")
	AC_DEFINE(OF_APPLE_RUNTIME, 1, [Whether we use the Apple ObjC runtime])

	AC_CHECK_LIB(objc, objc_msgSend, [
		AC_SUBST(RUNTIME_LIBS, "-lobjc")
		AC_SUBST(RUNTIME_FRAMEWORK_LIBS, "-lobjc")
	], [
		AC_MSG_ERROR([libobjc not found!])
	])

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -lobjc"

	AC_CHECK_FUNC(objc_autoreleasePoolPush, [], [
		AC_SUBST(RUNTIME_AUTORELEASE_M, "runtime/autorelease.m")
	])
	AC_CHECK_FUNC(objc_constructInstance, [], [
		AC_SUBST(RUNTIME_INSTANCE_M, "runtime/instance.m")
	])

	OBJCFLAGS="$old_OBJCFLAGS"
	;;
esac

case "$host_os" in
mint*)
	dnl _Unwind_Backtrace crashes on MiNT
	;;
hpux*)
	dnl _Unwind_Backtrace() returns complete garbage on HP-UX.
	;;
*)
	AC_CHECK_FUNCS(_Unwind_Backtrace)
	;;
esac

case "$host_os" in
darwin*)
	AC_SUBST(LDFLAGS_REEXPORT, ["-Wl,-reexport-lobjfw"])
	AS_IF([test x"$objc_runtime" = x"Apple runtime"], [
		AC_SUBST(REEXPORT_RUNTIME, ["-Wl,-reexport-lobjc"])
		AC_SUBST(REEXPORT_RUNTIME_FRAMEWORK, ["-Wl,-reexport-lobjc"])
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

AC_MSG_CHECKING(whether Objective C compiler supports ARC)
old_OBJCFLAGS="$OBJCFLAGS"
OBJCFLAGS="$OBJCFLAGS -fobjc-arc -fobjc-arc-exceptions"
AC_COMPILE_IFELSE([
	AC_LANG_PROGRAM([
		#ifdef __has_attribute
		# if __has_attribute(objc_root_class)
		__attribute__((__objc_root_class__))
		# endif
		#endif
		@interface Foo
		{
			struct objc_class *_isa;
		}

		+ (id)alloc;
		@end

		@implementation Foo
		+ (id)alloc
		{
			return (id)0;
		}
		@end
	], [[
		__weak id foo = [Foo alloc];
		(void)foo;
	]])
], [
	AC_MSG_RESULT(yes)
	AC_DEFINE(COMPILER_SUPPORTS_ARC, 1, [Whether the compiler supports ARC])
	AC_SUBST(RUNTIME_ARC_TESTS_M, RuntimeARCTests.m)
], [
	AC_MSG_RESULT(no)
])
OBJCFLAGS="$old_OBJCFLAGS"

AC_C_BIGENDIAN([
	AC_DEFINE(OF_BIG_ENDIAN, 1, [Whether we are big endian])
])
AS_IF([test x"$ac_cv_c_bigendian" = x"universal"], [
	AC_DEFINE(OF_UNIVERSAL, 1, [Whether we are building a universal binary])
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
	AC_DEFINE(SSIZE_MAX, [(SIZE_MAX / 2)], [Maximum value for ssize_t])
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
	AC_CHECK_SIZEOF(uintptr_t)
	AC_DEFINE(UINTPTR_MAX,
		[(SIZEOF_UINTPTR_T * CHAR_BIT)], [Maximum value for uintptr_t])
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
	AC_COMPILE_IFELSE([
		AC_LANG_SOURCE([
			double endianess = 2.993700760838795055656993580068609688772747263874402942272934826871811872228512759832626847251963763755836687759498519784550143745834860002945223766052808125982053455555265216112722718870586961456110693379343178124592311441022662940307099598578775368547768968914916965731708568179631324904813506101190853720749196062963892799499230635163056742330563321122389331703618066046034494287335316842529021563862331183541255013987734473643350285400060357711238514186776429325214739886098119655678483017894951556639821088508565036657794343031121375178126860889964700274558728491825977274341798997758923017217660272136611938897932105874133412726223468780517578125e-259;
		])
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

case "$host_cpu" in
arm* | earm*)
	AC_MSG_CHECKING(for VFP2 or above)
	AC_COMPILE_IFELSE([
		AC_LANG_PROGRAM([], [
			#if !defined(__arm64__) && !defined(__aarch64__) && \
			    !defined(__ARM64_ARCH_8__)
			__asm__ __volatile__ (
			    "vstmdb	sp!, {d0-d7}"
			);
			#endif
		])
	], [
		AC_DEFINE(HAVE_VFP2, 1, [Whether we have VFP2 or above])
		AC_MSG_RESULT(yes)
	], [
		AC_MSG_RESULT(no)
	])
	;;
esac

AC_CHECK_LIB(m, fmod, LIBS="$LIBS -lm")
AC_CHECK_LIB(complex, creal, TESTS_LIBS="$TESTS_LIBS -lcomplex")

AC_CHECK_FUNCS(strtof truncf)

AC_CHECK_FUNC(asprintf, [
	case "$host" in
	*-*-mint*)
		dnl asprintf is not in headers
		have_asprintf="no"
		;;
	*-*-mingw*)
		dnl asprintf from MinGW is broken on older Windows versions
		have_asprintf="no"
		;;
	*-psp-*)
		dnl asprintf is broken on the PSP
		have_asprintf="no"
		;;
	*)
		have_asprintf="yes"
		AC_DEFINE(HAVE_ASPRINTF, 1, [Whether we have asprintf()])
		;;
	esac
], [
	have_asprintf="no"
])

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
		AC_DEFINE($4, 1, [Whether we have support for $3])
		ENCODINGS_SRCS="$ENCODINGS_SRCS $1.m"
	])
])
ENCODING_FLAG(codepage-437, codepage_437, [Codepage 437], HAVE_CODEPAGE_437)
ENCODING_FLAG(codepage-850, codepage_850, [Codepage 850], HAVE_CODEPAGE_850)
ENCODING_FLAG(codepage-858, codepage_858, [Codepage 858], HAVE_CODEPAGE_858)
ENCODING_FLAG(iso-8859-2, iso_8859_2, [ISO 8859-2], HAVE_ISO_8859_2)
ENCODING_FLAG(iso-8859-3, iso_8859_3, [ISO 8859-3], HAVE_ISO_8859_3)
ENCODING_FLAG(iso-8859-15, iso_8859_15, [ISO 8859-15], HAVE_ISO_8859_15)
ENCODING_FLAG(koi8-r, koi8_r, [KOI8-R], HAVE_KOI8_R)
ENCODING_FLAG(koi8-u, koi8_u, [KOI8-U], HAVE_KOI8_U)
ENCODING_FLAG(mac-roman, mac_roman, [Mac Roman encoding], HAVE_MAC_ROMAN)
ENCODING_FLAG(windows-1251, windows_1251, [Windows-1251], HAVE_WINDOWS_1251)
ENCODING_FLAG(windows-1252, windows_1252, [Windows-1252], HAVE_WINDOWS_1252)

AS_IF([test x"$ENCODINGS_SRCS" = x""], [
	ENCODINGS_SRCS="dummy.m"
])
AC_SUBST(ENCODINGS_SRCS)
AS_IF([test x"$enable_shared" != x"no"], [
	AC_SUBST(ENCODINGS_LIB_A, "encodings.lib.a")
])
AS_IF([test x"$enable_static" = x"yes" -o x"$enable_shared" = x"no"], [
	AC_SUBST(ENCODINGS_A, "encodings.a")
])

AC_CHECK_FUNCS(arc4random arc4random_buf getrandom random, break)

AS_IF([test x"$host_os" != x"morphos"], [
	AC_CHECK_LIB(dl, dlopen, LIBS="$LIBS -ldl")
])
AC_CHECK_HEADERS_ONCE(dlfcn.h)
case "$host_os" in
netbsd*)
	dnl dladdr exists on NetBSD, but it is completely broken.
	dnl When using it with code that uses __thread, it freezes the process
	dnl so that it has to be killed using SIGKILL.
	dnl When disabling __thread, it doesn't freeze, but all symbols are
	dnl wrong.
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
	amigaos* | morphos*)
		AC_MSG_RESULT(Amiga)
		have_amiga_threads="yes"
		;;
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

		AC_CHECK_LIB(pthread, main, LIBS="$LIBS -lpthread")

		AC_LINK_IFELSE([
			AC_LANG_PROGRAM([
				#include <pthread.h>
			], [
				pthread_create(NULL, NULL, NULL, NULL);
			])
		], [], [
			AC_MSG_ERROR(No supported threads found!)
		])

		AC_DEFINE(OF_HAVE_PTHREADS, 1, [Whether we have pthreads])

		AC_COMPILE_IFELSE([
			AC_LANG_PROGRAM([
				#include <pthread.h>
			], [
				pthread_mutexattr_t attr;
				pthread_mutexattr_settype(&attr,
				    PTHREAD_MUTEX_RECURSIVE);
			])
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
	AC_SUBST(OBJC_SYNC, objc_sync)

	AC_ARG_ENABLE(compiler-tls,
		AS_HELP_STRING([--disable-compiler-tls],
			[disable compiler thread local storage]))

	case "$host" in
	aarch64*-*-android*)
		dnl Compiler TLS is broken on AArch64 Android with Clang
		enable_compiler_tls="no"
		;;
	m68k-*-amigaos* | powerpc-*-amigaos*)
		dnl Compiler TLS is broken on AmigaOS
		enable_compiler_tls="no"
		;;
	*-*-mingw*)
		dnl Causes emutls to be pulled in, which pulls in winpthread.
		enable_compiler_tls="no"
		;;
	*-*-morphos*)
		dnl Compiler TLS needs helpers that we don't want in the
		dnl .library
		enable_compiler_tls="no"
		;;
	esac

	AS_IF([test x"$enable_compiler_tls" != x"no"], [
		AC_CHECK_HEADER(threads.h, [
			AC_DEFINE(OF_HAVE_THREADS_H, 1,
				[Whether we have threads.h])
		])

		AC_MSG_CHECKING(whether _Thread_local works)
		AC_LINK_IFELSE([
			AC_LANG_PROGRAM([
				static _Thread_local int x = 0;
			], [
				x++;
			])
		], [
			AS_IF([test x"$enable_shared" != x"no"], [
				old_OBJCFLAGS="$OBJCFLAGS"
				OBJCFLAGS="$OBJCFLAGS -fPIC"
				AC_COMPILE_IFELSE([
					AC_LANG_PROGRAM([
						static _Thread_local int x = 0;
					], [
						x++;
					])
				], [
					AC_MSG_RESULT(yes)
					AC_DEFINE(OF_HAVE__THREAD_LOCAL, 1,
						[Whether _Thread_local works])
					have_thread_local="yes"
				], [
					AC_MSG_RESULT(no)
				])
				OBJCFLAGS="$old_OBJCFLAGS"
			], [
				AC_MSG_RESULT(yes)
				AC_DEFINE(OF_HAVE__THREAD_LOCAL, 1,
					[Whether _Thread_local works])
				have_thread_local="yes"
			])
		], [
			AC_MSG_RESULT(no)
		])

		AS_IF([test x"$have_thread_local" != x"yes"], [
			AC_MSG_CHECKING(whether __thread works)
			AC_LINK_IFELSE([
				AC_LANG_PROGRAM([
					/*
					 * It seems __thread is buggy with
					 * GCC 4.1 */
					#if __GNUC__ == 4 && __GNUC_MINOR__ < 2
					# error buggy
					#endif

					__thread int x = 0;
				], [
					x++;
				])
			], [
				AS_IF([test x"$enable_shared" != x"no"], [
					old_OBJCFLAGS="$OBJCFLAGS"
					OBJCFLAGS="$OBJCFLAGS -fPIC"
					AC_COMPILE_IFELSE([
						AC_LANG_PROGRAM([
							__thread int x = 0;
						], [
							x++;
						])
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
	AC_LINK_IFELSE([
		AC_LANG_PROGRAM([
			#include <stdbool.h>
			#include <stdint.h>
		], [
			int32_t i, j;
			if (__atomic_add_fetch(&i, 1, __ATOMIC_RELAXED))
				j = __atomic_sub_fetch(&i, 1, __ATOMIC_RELAXED);
			while (!__atomic_compare_exchange_n(&i, &j, 1, false,
			    __ATOMIC_RELAXED, __ATOMIC_RELAXED));
			__atomic_thread_fence(__ATOMIC_SEQ_CST);
		])
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
	AC_LINK_IFELSE([
		AC_LANG_PROGRAM([
			#include <stdint.h>
		], [
			int32_t i, j;
			if (__sync_add_and_fetch(&i, 1))
				j = __sync_sub_and_fetch(&i, 1);
			while (!__sync_bool_compare_and_swap(&i, 0, 1));
		])
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
	AC_SUBST(OBJFW_NEW, "objfw-new")
	AC_SUBST(OFARC, "ofarc")
	AC_SUBST(OFHASH, "ofhash")

	case "$host_os" in
	msdosdjgpp*)
		dnl DJGPP has the type, but it's not really usable.
		;;
	*)
		AC_CHECK_TYPE(off64_t, [
			AC_DEFINE(OF_HAVE_OFF64_T, 1, [Whether we have off64_t])
			AC_CHECK_FUNCS([lseek64 lstat64 open64 stat64])
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
	AC_COMPILE_IFELSE([
		AC_LANG_PROGRAM([
			#include <dirent.h>
		], [
			DIR *dir = 0;
			struct dirent entry, *result;

			readdir_r(dir, &entry, &result);
		])
	], [
		AC_MSG_RESULT(yes)
		AC_DEFINE(HAVE_READDIR_R, 1, [Whether we have readdir_r()])
	], [
		AC_MSG_RESULT(no)
	])
	OBJCFLAGS="$old_OBJCFLAGS"
])

AC_CHECK_HEADERS(dirent.h)
AC_CHECK_FUNCS([sysconf gmtime_r localtime_r])

case "$host_os" in
amigaos* | morphos*)
	dnl We don't want fcntl() or nanosleep() on AmigaOS / MorphOS, despite
	dnl a symbol existing. The reason is that we cannot use fcntl() for
	dnl sockets and that nanosleep() is yet another function that uses
	dnl errno, so would need to be passed from the linklib.
	;;
*)
	AC_CHECK_HEADERS(fcntl.h)
	AC_CHECK_FUNCS([fcntl nanosleep])
	;;
esac

AC_CHECK_HEADERS(xlocale.h)
AC_CHECK_FUNCS([strtod_l strtof_l asprintf_l])
AS_IF([test x"$gnu_source" != x"yes" -a \( \
    x"$ac_cv_func_strtod_l" = x"yes" -o x"$ac_cv_func_strtof_l" = x"yes" -o \
    x"$ac_cv_func_asprintf_l" = x"yes" \)], [
	AC_MSG_CHECKING(whether *_l functions need _GNU_SOURCE)
	AC_COMPILE_IFELSE([
		AC_LANG_PROGRAM([
			#include <stdlib.h>
			#include <stdio.h>

			#include <locale.h>
			#ifdef HAVE_XLOCALE_H
			# include <xlocale.h>
			#endif
		], [
			#ifdef HAVE_STRTOD_L
			(void)strtod_l;
			#endif
			#ifdef HAVE_STRTOF_L
			(void)strtof_l;
			#endif
			#ifdef HAVE_ASPRINTF_L
			(void)asprintf_l;
			#endif
		])
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		CPPFLAGS="-D_GNU_SOURCE $CPPFLAGS"
	])
])

dnl This check needs to happen after the above, as _GNU_SOURCE can change the
dnl return type.
AC_CHECK_FUNCS(strerror_r, [
	AC_MSG_CHECKING(for return type of strerror_r)
	AC_COMPILE_IFELSE([
		AC_LANG_PROGRAM([
			#include <stdio.h>
			#include <string.h>
		], [
			switch (strerror_r(0, NULL, 0)) {
			case 0:;
			}
		])
	], [
		AC_MSG_RESULT(int)
	], [
		AC_MSG_RESULT(char *)
		AC_DEFINE(STRERROR_R_RETURNS_CHARP, 1,
			[Whether strerror_r returns char *])
	])
])

AC_CHECK_HEADERS(sys/utsname.h)
AC_CHECK_FUNCS(uname)

AC_CHECK_FUNC(pipe, [
	AC_DEFINE(OF_HAVE_PIPE, 1, [Whether we have pipe()])
])

AC_ARG_ENABLE(sockets,
	AS_HELP_STRING([--disable-sockets], [disable socket support]))
AS_IF([test x"$enable_sockets" != x"no"], [
	AC_DEFINE(OF_HAVE_SOCKETS, 1, [Whether we have sockets])
	AC_SUBST(USE_SRCS_SOCKETS, '${SRCS_SOCKETS}')

	case "$host_os" in
	amigaos* | morphos*)
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
	AC_CHECK_HEADERS([arpa/inet.h netdb.h net/if.h])
	AC_CHECK_FUNCS([if_indextoname if_nametoindex])
	AC_CHECK_HEADER(sys/un.h, [
		AC_DEFINE(OF_HAVE_SYS_UN_H, 1, [Whether we have sys/un.h])
	])
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
		dnl Work around a bug in autoconf 2.61 that creates a broken
		dnl configure if this branch is empty.
		:
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

	AC_CHECK_HEADERS(afunix.h, [
		AC_DEFINE(OF_HAVE_AFUNIX_H, 1, [Whether we have afunix.h])
	], [], [
		#ifdef _WIN32
		# include <winsock2.h>
		#endif
	])
	AC_CHECK_MEMBER(struct sockaddr_un.sun_path, [
		AC_DEFINE(OF_HAVE_UNIX_SOCKETS, 1,
			[Whether we have UNIX sockets])
		AC_SUBST(USE_SRCS_UNIX_SOCKETS, '${SRCS_UNIX_SOCKETS}')
	], [], [
		#ifdef OF_HAVE_SYS_TYPES_H
		# include <sys/types.h>
		#endif
		#ifdef OF_HAVE_SYS_UN_H
		# include <sys/un.h>
		#endif
		#ifdef _WIN32
		# include <winsock2.h>
		#endif
		#ifdef HAVE_AFUNIX_H
		# include <afunix.h>
		#endif

		#ifdef __morphos__
		# error MorphOS has the struct but does not support it
		#endif

		#ifdef __MINT__
		# error Gives invalid argument at runtime
		#endif
	])

	AC_CHECK_HEADER(netipx/ipx.h, [
		AC_DEFINE(OF_HAVE_NETIPX_IPX_H, 1,
			[Whether we have netipx/ipx.h])
	])
	AC_CHECK_MEMBER(struct sockaddr_ipx.sipx_network, [], [
		AC_CHECK_MEMBER(struct sockaddr_ipx.sa_netnum, [], [], [
			#ifdef _WIN32
			typedef int BOOL;
			#endif

			#ifdef OF_HAVE_NETIPX_IPX_H
			# include <netipx/ipx.h>
			#endif

			#ifdef _WIN32
			# ifdef __MINGW32__
			#  include <_mingw.h>
			#  ifdef __MINGW64_VERSION_MAJOR
			#   include <winsock2.h>
			#  endif
			# endif
			# include <windows.h>
			# include <wsipx.h>
			#endif
		])
	], [
		#ifdef _WIN32
		typedef int BOOL;
		#endif

		#ifdef OF_HAVE_NETIPX_IPX_H
		# include <netipx/ipx.h>
		#endif

		#ifdef _WIN32
		# ifdef __MINGW32__
		#  include <_mingw.h>
		#  ifdef __MINGW64_VERSION_MAJOR
		#   include <winsock2.h>
		#  endif
		# endif
		# include <windows.h>
		# include <wsipx.h>
		#endif
	])
	AS_IF([test x"$ac_cv_member_struct_sockaddr_ipx_sipx_network" = x"yes" \
	    -o x"$ac_cv_member_struct_sockaddr_ipx_sa_netnum" = x"yes"], [
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
			# include <wsipx.h>
			#endif

			#ifdef AF_IPX
			egrep_cpp_yes
			#endif
		], [
			AC_DEFINE(OF_HAVE_IPX, 1, [Whether we have IPX/SPX])
			AC_SUBST(USE_SRCS_IPX, '${SRCS_IPX}')
		])
	])

	AC_CHECK_HEADER(netat/appletalk.h, [
		AC_DEFINE(OF_HAVE_NETAT_APPLETALK_H, 1,
			[Whether we have netat/appletalk.h])
	])
	AC_CHECK_HEADER(netatalk/at.h, [
		AC_DEFINE(OF_HAVE_NETATALK_AT_H, 1,
			[Whether we have netatalk/at.h])
	])
	AC_CHECK_MEMBER(struct sockaddr_at.sat_addr, [], [
		AC_CHECK_MEMBER(struct sockaddr_at.sat_net, [], [], [
			#ifdef _WIN32
			typedef int BOOL;
			#endif

			#ifdef OF_HAVE_SYS_TYPES_H
			# include <sys/types.h>
			#endif
			#if defined(OF_HAVE_NETAT_APPLETALK_H)
			# include <netat/appletalk.h>
			#elif defined(OF_HAVE_NETATALK_AT_H)
			# include <netatalk/at.h>
			#endif

			#ifdef _WIN32
			# ifdef __MINGW32__
			#  include <_mingw.h>
			#  ifdef __MINGW64_VERSION_MAJOR
			#   include <winsock2.h>
			#  endif
			# endif
			# include <windows.h>
			# include <atalkwsh.h>
			#endif
		])
	], [
		#ifdef _WIN32
		typedef int BOOL;
		#endif

		#ifdef OF_HAVE_SYS_TYPES_H
		# include <sys/types.h>
		#endif
		#if defined(OF_HAVE_NETAT_APPLETALK_H)
		# include <netat/appletalk.h>
		#elif defined(OF_HAVE_NETATALK_AT_H)
		# include <netatalk/at.h>
		#endif

		#ifdef _WIN32
		# ifdef __MINGW32__
		#  include <_mingw.h>
		#  ifdef __MINGW64_VERSION_MAJOR
		#   include <winsock2.h>
		#  endif
		# endif
		# include <windows.h>
		# include <atalkwsh.h>
		#endif
	])
	AS_IF([test x"$ac_cv_member_struct_sockaddr_at_sat_addr" = x"yes" \
	    -o x"$ac_cv_member_struct_sockaddr_at_sat_net" = x"yes"], [
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
			# include <atalkwsh.h>
			#endif

			#ifdef AF_APPLETALK
			egrep_cpp_yes
			#endif
		], [
			AC_DEFINE(OF_HAVE_APPLETALK, 1,
			    [Whether we have AppleTalk])
			AC_SUBST(USE_SRCS_APPLETALK, '${SRCS_APPLETALK}')
		])
	])

	AC_CHECK_FUNCS(paccept accept4, break)

	AC_CHECK_FUNCS(kqueue1 kqueue, [
		AC_DEFINE(HAVE_KQUEUE, 1, [Whether we have kqueue])
		AC_SUBST(OF_KQUEUE_KERNEL_EVENT_OBSERVER_M,
			"OFKqueueKernelEventObserver.m")
		break
	])
	AC_CHECK_FUNCS(epoll_create1 epoll_create, [
		AC_DEFINE(HAVE_EPOLL, 1, [Whether we have epoll])
		AC_SUBST(OF_EPOLL_KERNEL_EVENT_OBSERVER_M,
			"OFEpollKernelEventObserver.m")
		break
	])

	AS_IF([test x"$with_wii" = x"yes"], [
		AC_DEFINE(HAVE_POLL, 1, [Whether we have poll()])
		AC_SUBST(OF_POLL_KERNEL_EVENT_OBSERVER_M,
			"OFPollKernelEventObserver.m")
	], [
		AC_CHECK_HEADERS(poll.h)
		AC_CHECK_FUNC(poll, [
			AC_DEFINE(HAVE_POLL, 1, [Whether we have poll()])
			AC_SUBST(OF_POLL_KERNEL_EVENT_OBSERVER_M,
				"OFPollKernelEventObserver.m")
		])
	])

	case "$host_os" in
	amigaos* | mingw* | morphos*)
		AC_DEFINE(HAVE_SELECT, 1, [Whether we have select() or similar])
		AC_SUBST(OF_SELECT_KERNEL_EVENT_OBSERVER_M,
			"OFSelectKernelEventObserver.m")
		;;
	*)
		AC_CHECK_HEADERS(sys/select.h)
		AC_CHECK_FUNC(select, [
			AC_DEFINE(HAVE_SELECT, 1,
				[Whether we have select() or similar])
			AC_SUBST(OF_SELECT_KERNEL_EVENT_OBSERVER_M,
				"OFSelectKernelEventObserver.m")
		])
		;;
	esac

	AC_ARG_WITH(tls,
		AS_HELP_STRING([--with-tls], [
			enable TLS support using the specified library
			(yes, openssl, gnutls, securetransport or no)]))
	AS_IF([test x"$with_tls" = x""], [with_tls="yes"])
	tls_support="no"

	AS_IF([test x"$with_tls" = x"securetransport" \
		-o x"$with_tls" = x"yes"], [
		AC_CHECK_HEADERS(Security/SecureTransport.h, [
			old_LIBS="$LIBS"
			LIBS="-framework Security -framework Foundation $LIBS"

			AC_CHECK_FUNC(SSLHandshake, [
				AC_DEFINE(HAVE_SECURE_TRANSPORT, 1,
					[Whether we have Secure Transport])

				tls_support="Secure Transport"
				TLS_LIBS="-framework Foundation $TLS_LIBS"
				TLS_LIBS="-framework Security $TLS_LIBS"

				AC_SUBST(OF_SECURE_TRANSPORT_TLS_STREAM_M,
					"OFSecureTransportTLSStream.m")

				AC_CHECK_FUNCS(SSLCreateContext)
			], [])

			LIBS="$old_LIBS"
		])
	])

	AS_IF([test x"$with_tls" = x"gnutls" \
		-o \( x"$with_tls" = x"yes" -a x"$tls_support" = x"no" \)], [
		PKG_CHECK_MODULES(gnutls, [gnutls >= 3.5.0], [
			AC_DEFINE(HAVE_GNUTLS, 1, [Whether we have GnuTLS])

			tls_support="GnuTLS"
			TLS_CPPFLAGS="$gnutls_CFLAGS $TLS_CPPFLAGS"
			TLS_LIBS="$gnutls_LIBS $TLS_LIBS"

			AC_SUBST(OF_GNUTLS_TLS_STREAM_M, "OFGnuTLSTLSStream.m")
		], [
			dnl Disable default action-if-not-found, which exits
			dnl configure with an error.
			:
		])
	])

	AS_IF([test x"$with_tls" = x"openssl" \
		-o \( x"$with_tls" = x"yes" -a x"$tls_support" = x"no" \)], [
		case "$host_os" in
		morphos*)
			ssl="ssl_shared"
			crypto="crypto_shared"
			;;
		*)
			ssl="ssl"
			crypto="crypto"
			;;
		esac

		AC_CHECK_LIB($ssl, SSL_set1_host, [
			AC_CHECK_HEADER(openssl/ssl.h, [
				AC_DEFINE(HAVE_OPENSSL, 1,
					[Whether we have OpenSSL])

				tls_support="OpenSSL"
				TLS_LIBS="-l$ssl -l$crypto $TLS_LIBS"

				AC_SUBST(OF_OPENSSL_TLS_STREAM_M,
					"OFOpenSSLTLSStream.m")
			])
		], [], [-l$crypto])
	])

	AS_IF([test x"$tls_support" != x"no"], [
		AC_SUBST(TLS, "tls")
		AC_SUBST(TLS_CPPFLAGS)
		AC_SUBST(TLS_LIBS)
		AC_DEFINE(HAVE_TLS_SUPPORT, 1,
			[Whether we have an implementation for TLS])
		AC_CONFIG_FILES(src/tls/Info.plist)

		OFHTTP_LIBS="-lobjfwtls $TLS_LIBS $OFHTTP_LIBS"

		AS_IF([test x"$enable_shared" != x"no"], [
			AC_SUBST(OBJFWTLS_SHARED_LIB,
				"${LIB_PREFIX}objfwtls${LIB_SUFFIX}")
		])
		AS_IF([test x"$enable_static" = x"yes" \
		    -o x"$enable_shared" = x"no"], [
			AC_SUBST(OBJFWTLS_STATIC_LIB, "libobjfwtls.a")
		])
		AS_IF([test x"$build_framework" = x"yes"], [
			AC_SUBST(OBJFWTLS_FRAMEWORK, "ObjFWTLS.framework")
		])
	])

	AS_IF([test x"$with_tls" != x"no" -a x"$tls_support" = x"no"], [
		AC_MSG_ERROR(m4_normalize([
			No TLS implementation was found. Please install OpenSSL,
			GnuTLS or use --without-tls.
		]))
	])

	AS_IF([test x"$enable_threads" != x"no"], [
		AC_SUBST(OF_HTTP_CLIENT_TESTS_M, "OFHTTPClientTests.m")
	])

	AC_SUBST(OFDNS, "ofdns")
	AS_IF([test x"$enable_files" != x"no"], [
		AC_SUBST(OFHTTP, "ofhttp")
		AC_SUBST(OFHTTP_LIBS)
	])
])

AC_DEFUN([CHECK_BUILTIN_BSWAP], [
	AC_MSG_CHECKING(for __builtin_bswap$1)
	AC_LINK_IFELSE([
		AC_LANG_PROGRAM([
			#include <stdint.h>
			#include <stdio.h>
			#include <errno.h>
		], [
			uint$1_t i = errno;
			printf("%d", (int)__builtin_bswap$1(i));
		])
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

case "$host_os" in
darwin*)
	AC_MSG_CHECKING(whether we are compiling for macOS)
	AC_EGREP_CPP(egrep_cpp_yes, [
		#include <TargetConditionals.h>

		#if (!defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE) && \
		    (!defined(TARGET_OS_SIMULATOR) || !TARGET_OS_SIMULATOR)
		egrep_cpp_yes
		#endif
	], [
		AC_MSG_RESULT(yes)
		have_subprocesses="yes"

		AC_CHECK_FUNCS(posix_spawnp)
		AC_CHECK_HEADERS(spawn.h)
	], [
		AC_MSG_RESULT(no)
		have_subprocesses="no"
	])
	;;
mingw*)
	have_subprocesses="yes"
	;;
msdosdjgpp*)
	have_subprocesses="no"
	;;
*)
	AC_HEADER_SYS_WAIT
	AC_CHECK_FUNCS(kill)

	AC_CHECK_FUNCS(posix_spawnp, [
		AS_IF([test x"$ac_cv_func_kill" = x"yes"], [
			have_subprocesses="yes"

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
				have_subprocesses="yes"
			])
		], [
			break
		])
	])
	;;
esac
AS_IF([test x"$have_subprocesses" = x"yes"], [
	AC_SUBST(OF_SUBPROCESS_M, "OFSubprocess.m")
	AC_DEFINE(OF_HAVE_SUBPROCESSES, 1, [Whether we have subprocesses])
])

AC_CHECK_HEADERS_ONCE([complex.h sys/ioctl.h sys/ttycom.h])
AC_CHECK_FUNCS(isatty)

AC_CHECK_FUNC(pledge, [
	AC_DEFINE(OF_HAVE_PLEDGE, 1, [Whether we have pledge()])
])

AS_IF([test x"$objc_runtime" = x"Apple runtime"], [
	AC_CHECK_HEADER(Foundation/NSObject.h, [
		AC_SUBST(BRIDGE, "bridge")
		AC_CONFIG_FILES(src/bridge/Info.plist)

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
AC_COMPILE_IFELSE([
	AC_LANG_PROGRAM([], [
		int (^foo)(int bar);
		foo = ^ (int bar) { return 0; }
	])
], [
	OBJFW_OBJCFLAGS="$OBJFW_OBJCFLAGS -Xclang -fblocks"
	AC_SUBST(OF_BLOCK_TESTS_M, "OFBlockTests.m")
	AC_MSG_RESULT(yes)
], [
	AC_MSG_RESULT(no)
	OBJCFLAGS="$old_OBJCFLAGS"
])

AS_IF([test x"$GOBJC" = x"yes"], [
	OBJCFLAGS="$OBJCFLAGS -Wwrite-strings -Wpointer-arith -Werror"

	AC_MSG_CHECKING(whether we need -Wno-strict-aliasing due to GCC bugs)
	AC_COMPILE_IFELSE([
		AC_LANG_PROGRAM([
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
		])
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$OBJCFLAGS -Wno-strict-aliasing"
	])

	AC_MSG_CHECKING(
	    whether we need -Wno-unused-property-ivar due to Clang bugs)
	AC_COMPILE_IFELSE([
		AC_LANG_SOURCE([
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
		])
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$OBJCFLAGS -Wno-unused-property-ivar"
	])

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Wcast-align"
	AC_MSG_CHECKING(whether -Wcast-align is buggy)
	AC_COMPILE_IFELSE([
		AC_LANG_SOURCE([
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
		])
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$old_OBJCFLAGS"
	])

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Wunreachable-code"
	AC_MSG_CHECKING(whether -Wunreachable-code can be used)
	AC_COMPILE_IFELSE([
		AC_LANG_SOURCE([[
			#include <stdlib.h>

			struct objc_selector;
			typedef const struct objc_selector *SEL;

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
			 * Unfortunately, this cannot be shorter, as it only
			 * works when it is used inside a macro.
			 */
			#ifdef __clang__
			# define OF_DEALLOC_UNSUPPORTED			\
				[self doesNotRecognizeSelector: _cmd];	\
									\
				abort();				\
									\
				_Pragma("clang diagnostic push");	\
			       	_Pragma("clang diagnostic ignored	\
				    \"-Wunreachable-code\"");		\
				[super dealloc];			\
				_Pragma("clang diagnostic pop");
			#else
			# define OF_DEALLOC_UNSUPPORTED			\
				[self doesNotRecognizeSelector: _cmd];	\
									\
				abort();				\
									\
				[super dealloc];
			#endif

			@implementation Foo
			- (void)dealloc
			{
				OF_DEALLOC_UNSUPPORTED
			}
			@end
		]])
	], [
		AC_MSG_RESULT(yes)
	], [
		AC_MSG_RESULT(no)
		OBJCFLAGS="$old_OBJCFLAGS"
	])

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Wdocumentation"
	AC_MSG_CHECKING(whether -Wdocumentation works correctly)
	AC_COMPILE_IFELSE([
		AC_LANG_SOURCE([
			/**
			 * @class Test conftest.m conftest.m
			 */
			#ifdef __has_attribute
			# if __has_attribute(objc_root_class)
			__attribute__((__objc_root_class__))
			# endif
			#endif
			@interface Test
			@end

			/**
			 * @struct Foo conftest.m conftest.m
			 */
			typedef struct {} Foo;
		])
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
		AC_COMPILE_IFELSE([
			AC_LANG_SOURCE([
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
					 * Some versions of glibc break with
					 * -pedantic when using assert.
					 */
					assert(1);
				}
				@end
			])
		], [
			AC_MSG_RESULT(no)
		], [
			AC_MSG_RESULT(yes)
			OBJCFLAGS="$old_OBJCFLAGS"
		])
	])

	AS_IF([test x"$ac_cv_header_complex_h" = x"yes"], [
		AC_MSG_CHECKING(whether we need -Wno-gnu-imaginary-constant)
		AC_COMPILE_IFELSE([
			AC_LANG_PROGRAM([
				#include <complex.h>
			], [
				complex float f = 0.5 + 0.5 * I;
				(void)f;
			])
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
])

AC_ARG_WITH(fish_completions,
	AS_HELP_STRING([--with-fish-completions],
		[install completions for the fish shell]))
AS_IF([test x"$with_fish_completions" = x""], [
	AC_CHECK_PROG(FISH, fish, fish)
	AS_IF([test x"$FISH" != x""], [with_fish_completions="yes"])
])
AS_IF([test x"$with_fish_completions" = x"yes"], [
	AC_SUBST(FISH_COMPLETIONS, fish)
])

dnl We don't call AC_PROG_CPP, but only AC_PROG_OBJCPP and set CPP to OBJCPP
dnl and add OBJCPPFLAGS to CPPFLAGS, thus we need to AC_SUBST these ourself.
AC_SUBST(CPP)
AC_SUBST(CPPFLAGS)
dnl We use the ObjC compiler as our assembler
AC_SUBST(AS, $OBJC)
AC_SUBST(ASFLAGS)
AC_SUBST(DEP_ASFLAGS, '${DEP_OBJCFLAGS}')

AC_SUBST(OBJFW_CPPFLAGS)
AC_SUBST(OBJFW_OBJCFLAGS)

AC_SUBST(TESTS_LIBS)

AC_CONFIG_FILES([
	buildsys.mk
	extra.mk
	src/Info.plist
	tests/Info.plist
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
    -a x"$have_spinlocks" != x"yes" -a x"$have_amiga_threads" != x"yes"], [
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
