dnl
dnl Copyright (c) 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2016, 2017,
dnl               2018, 2020, 2021, 2022, 2023, 2024, 2025
dnl   Jonathan Schleifer <js@nil.im>
dnl
dnl https://fl.nil.im/buildsys
dnl
dnl Permission to use, copy, modify, and/or distribute this software for any
dnl purpose with or without fee is hereby granted, provided that the above
dnl copyright notice and this permission notice appear in all copies.
dnl
dnl THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
dnl REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
dnl AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
dnl INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
dnl LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
dnl OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
dnl PERFORMANCE OF THIS SOFTWARE.
dnl

AC_DEFUN([BUILDSYS_INIT], [
	AC_REQUIRE([AC_CANONICAL_BUILD])
	AC_REQUIRE([AC_CANONICAL_HOST])

	AC_ARG_ENABLE(rpath,
		AS_HELP_STRING([--disable-rpath], [do not use rpath]))

	AC_ARG_ENABLE(silent-rules,
		AS_HELP_STRING([--disable-silent-rules],
			[print executed commands during build]))

	case "$build_os" in
	darwin*)
		case "$host_os" in
		darwin*)
			AC_SUBST(BUILD_AND_HOST_ARE_DARWIN, yes)
			;;
		esac
		;;
	esac

	AC_PROG_INSTALL
	case "$INSTALL" in
	./build-aux/install-sh*)
		INSTALL="$PWD/$INSTALL"
		;;
	esac

	AC_CONFIG_COMMANDS_PRE([
		AS_IF([test x"$GCC" = x"yes"],
			[AC_SUBST(DEP_CFLAGS, '-MD -MF $${out%.o}.dep')])
		AS_IF([test x"$GXX" = x"yes"],
			[AC_SUBST(DEP_CXXFLAGS, '-MD -MF $${out%.o}.dep')])
		AS_IF([test x"$GOBJC" = x"yes"],
			[AC_SUBST(DEP_OBJCFLAGS, '-MD -MF $${out%.o}.dep')])
		AS_IF([test x"$GOBJCXX" = x"yes"],
			[AC_SUBST(DEP_OBJCXXFLAGS, '-MD -MF $${out%.o}.dep')])

		AC_SUBST(AMIGA_LIB_CFLAGS)
		AC_SUBST(AMIGA_LIB_LDFLAGS)

		AS_IF([test x"$enable_silent_rules" != x"no"], [
			AC_SUBST(SILENT, '.SILENT:')
			AC_SUBST(MAKEFLAGS_SILENT, '-s')
		])
	])
])

AC_DEFUN([BUILDSYS_CHECK_IOS], [
	case "$host_os" in
	darwin*)
		AC_MSG_CHECKING(whether host is iOS)
		AC_EGREP_CPP(yes, [
			#include <TargetConditionals.h>

			#if (defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE) || \
			    (defined(TARGET_OS_SIMULATOR) && \
			    TARGET_OS_SIMULATOR)
			yes
			#endif
		], [
			host_is_ios="yes"
			AC_SUBST(HOST_IS_IOS, yes)
		], [
			host_is_ios="no"
		])
		AC_MSG_RESULT($host_is_ios)
		AC_CHECK_TOOL(CODESIGN, codesign)
		;;
	esac
])

AC_DEFUN([BUILDSYS_PROG_IMPLIB], [
	AC_REQUIRE([AC_CANONICAL_HOST])
	AC_MSG_CHECKING(whether we need an implib)
	case "$host_os" in
	cygwin* | mingw*)
		AC_MSG_RESULT(yes)
		PROG_IMPLIB_NEEDED='yes'
		PROG_IMPLIB_LDFLAGS='-Wl,--export-all-symbols,--out-implib,lib${PROG}.a'
		;;
	*)
		AC_MSG_RESULT(no)
		PROG_IMPLIB_NEEDED='no'
		PROG_IMPLIB_LDFLAGS=''
		;;
	esac

	AC_SUBST(PROG_IMPLIB_NEEDED)
	AC_SUBST(PROG_IMPLIB_LDFLAGS)
])

AC_DEFUN([BUILDSYS_STACK_PROTECTOR], [
	AC_REQUIRE([AC_CANONICAL_HOST])

	case "$host" in
	m68k-*-amigaos* | *-*-morphos*)
		dnl Stack Protector test compiles and links, but is not
		dnl actually supported.
		AC_MSG_CHECKING(for Stack Protector)
		AC_MSG_RESULT(no)
		;;
	*)
		_BUILDSYS_STACK_PROTECTOR_REAL
		;;
	esac
])

AC_DEFUN([_BUILDSYS_STACK_PROTECTOR_REAL], [
	AC_REQUIRE([AC_CANONICAL_HOST])
	AC_MSG_CHECKING(for Stack Protector)

	old_CFLAGS="$CFLAGS"
	old_CXXFLAGS="$CXXFLAGS"
	old_OBJCFLAGS="$OBJCFLAGS"
	old_OBJCXXFLAGS="$OBJCXXFLAGS"
	old_LDFLAGS="$LDFLAGS"

	CFLAGS="$CFLAGS -fstack-protector-strong"
	CXXFLAGS="$CXXFLAGS -fstack-protector-strong"
	OBJCFLAGS="$OBJCFLAGS -fstack-protector-strong"
	OBJCXXFLAGS="$OBJCXXFLAGS -fstack-protector-strong"
	LDFLAGS="$LDFLAGS -fstack-protector-strong"

	AC_LINK_IFELSE([
		AC_LANG_PROGRAM([
			#include <stdio.h>
		], [
			char buf[16];

			puts("Stack Protector test");
		])
	], [
		AC_MSG_RESULT(strong)
		AC_SUBST(STACK_PROTECTOR_CFLAGS, -fstack-protector-strong)
		AC_SUBST(STACK_PROTECTOR_LDFLAGS, -fstack-protector-strong)
	], [
		CFLAGS="$old_CFLAGS -fstack-protector"
		CXXFLAGS="$old_CXXFLAGS -fstack-protector"
		OBJCFLAGS="$old_OBJCFLAGS -fstack-protector"
		OBJCXXFLAGS="$old_OBJCXXFLAGS -fstack-protector"
		LDFLAGS="$old_LDFLAGS -fstack-protector"
		
		AC_LINK_IFELSE([
			AC_LANG_PROGRAM([
				#include <stdio.h>
			], [
				char buf[16];

				puts("Stack Protector test");
			])
		], [
			AC_MSG_RESULT(yes)
			AC_SUBST(STACK_PROTECTOR_CFLAGS, -fstack-protector)
			AC_SUBST(STACK_PROTECTOR_LDFLAGS, -fstack-protector)
		], [	
			AC_MSG_RESULT(no)
		])
	])

	CFLAGS="$old_CFLAGS"
	CXXFLAGS="$old_CXXFLAGS"
	OBJCFLAGS="$old_OBJCFLAGS"
	OBJCXXFLAGS="$old_OBJCXXFLAGS"
	LDFLAGS="$old_LDFLAGS"
])

AC_DEFUN([BUILDSYS_PIE], [
	AC_REQUIRE([AC_CANONICAL_HOST])
	AC_MSG_CHECKING(for Position Independent Executable support)

	old_CFLAGS="$CFLAGS"
	old_CXXFLAGS="$CXXFLAGS"
	old_OBJCFLAGS="$OBJCFLAGS"
	old_OBJCXXFLAGS="$OBJCXXFLAGS"
	old_LDFLAGS="$LDFLAGS"

	CFLAGS="$CFLAGS -fPIE"
	CXXFLAGS="$CXXFLAGS -fPIE"
	OBJCFLAGS="$OBJCFLAGS -fPIE"
	OBJCXXFLAGS="$OBJCXXFLAGS -fPIE"
	LDFLAGS="$LDFLAGS -Wl,-pie"

	AC_LINK_IFELSE([
		AC_LANG_PROGRAM([
			#include <stdio.h>
		], [
			puts("PIE test");
		])
	], [
		AC_MSG_RESULT(yes)
		AC_SUBST(PIE_CFLAGS, -fPIE)
		AC_SUBST(PIE_LDFLAGS, [-Wl,-pie])
	], [
		AC_MSG_RESULT(no)
	])

	CFLAGS="$old_CFLAGS"
	CXXFLAGS="$old_CXXFLAGS"
	OBJCFLAGS="$old_OBJCFLAGS"
	OBJCXXFLAGS="$old_OBJCXXFLAGS"
	LDFLAGS="$old_LDFLAGS"
])

AC_DEFUN([BUILDSYS_RELRO], [
	AC_REQUIRE([AC_CANONICAL_HOST])
	AC_MSG_CHECKING(for RELRO support)

	case "$host_os" in
	morphos*)
		AC_MSG_RESULT(no)
		;;
	*)
		old_LDFLAGS="$LDFLAGS"
		LDFLAGS="$LDFLAGS -Wl,-z,relro,-z,now"
		AC_LINK_IFELSE([
			AC_LANG_PROGRAM([
				#include <stdio.h>
			], [
				puts("RELRO test");
			])
		], [
			AC_MSG_RESULT(yes)
			AC_SUBST(RELRO_LDFLAGS, [-Wl,-z,relro,-z,now])
		], [
			AC_MSG_RESULT(no)
		])

		LDFLAGS="$old_LDFLAGS"
		;;
	esac
])

AC_DEFUN([BUILDSYS_SHARED_LIB], [
	AC_REQUIRE([AC_CANONICAL_HOST])
	AC_REQUIRE([BUILDSYS_CHECK_IOS])
	AC_MSG_CHECKING(for shared library type)

	case "$host" in
	*-*-darwin*)
		AC_MSG_RESULT(Darwin)
		LIB_CFLAGS='-fPIC -DPIC'
		LIB_LDFLAGS='-dynamiclib -current_version ${LIB_MAJOR}.${LIB_MINOR} -compatibility_version ${LIB_MAJOR}'
		LIB_LDFLAGS_INSTALL_NAME='-Wl,-install_name,${libdir}/$${out%.dylib}.${LIB_MAJOR}.dylib'
		LIB_PREFIX='lib'
		LIB_SUFFIX='.dylib'
		AS_IF([test x"$enable_rpath" != x"no"], [
			LDFLAGS_RPATH='-Wl,-rpath,${libdir}'
		])
		INSTALL_LIB='&& ${INSTALL} -m 755 $$i ${DESTDIR}${libdir}/$${i%.dylib}.${LIB_MAJOR}.${LIB_MINOR}.dylib && ${LN_S} -f $${i%.dylib}.${LIB_MAJOR}.${LIB_MINOR}.dylib ${DESTDIR}${libdir}/$${i%.dylib}.${LIB_MAJOR}.dylib && ${LN_S} -f $${i%.dylib}.${LIB_MAJOR}.${LIB_MINOR}.dylib ${DESTDIR}${libdir}/$$i'
		UNINSTALL_LIB='&& rm -f ${DESTDIR}${libdir}/$$i ${DESTDIR}${libdir}/$${i%.dylib}.${LIB_MAJOR}.dylib ${DESTDIR}${libdir}/$${i%.dylib}.${LIB_MAJOR}.${LIB_MINOR}.dylib'
		CLEAN_LIB=''
		;;
	*-*-mingw* | *-*-cygwin*)
		AC_MSG_RESULT(MinGW / Cygwin)
		LIB_CFLAGS=''
		LIB_LDFLAGS='-shared -Wl,--export-all-symbols'
		LIB_LDFLAGS_INSTALL_NAME=''
		LIB_PREFIX=''
		LIB_SUFFIX='${LIB_MAJOR}.dll'
		LINK_LIB='&& rm -f lib$${out%${LIB_SUFFIX}}.dll.a && ${LN_S} $$out lib$${out%${LIB_SUFFIX}}.dll.a'
		INSTALL_LIB='&& ${MKDIR_P} ${DESTDIR}${bindir} && ${INSTALL} -m 755 $$i ${DESTDIR}${bindir}/$$i && ${INSTALL} -m 755 lib$${i%${LIB_SUFFIX}}.dll.a ${DESTDIR}${libdir}/lib$${i%${LIB_SUFFIX}}.dll.a'
		UNINSTALL_LIB='&& rm -f ${DESTDIR}${bindir}/$$i ${DESTDIR}${libdir}/lib$${i%${LIB_SUFFIX}}.dll.a'
		CLEAN_LIB='${SHARED_LIB}.a ${SHARED_LIB_NOINST}.a'
		;;
	*-*-openbsd* | *-*-mirbsd*)
		AC_MSG_RESULT(OpenBSD)
		LIB_CFLAGS='-fPIC -DPIC'
		LIB_LDFLAGS='-shared'
		LIB_LDFLAGS_INSTALL_NAME=''
		LIB_PREFIX='lib'
		LIB_SUFFIX='.so.${LIB_MAJOR}.${LIB_MINOR}'
		AS_IF([test x"$enable_rpath" != x"no"], [
			LDFLAGS_RPATH='-Wl,-rpath,${libdir}'
		])
		INSTALL_LIB='&& ${INSTALL} -m 755 $$i ${DESTDIR}${libdir}/$$i'
		UNINSTALL_LIB='&& rm -f ${DESTDIR}${libdir}/$$i'
		CLEAN_LIB=''
		;;
	*-*-solaris*)
		AC_MSG_RESULT(Solaris)
		LIB_CFLAGS='-fPIC -DPIC'
		LIB_LDFLAGS='-shared -Wl,-soname=$$out.${LIB_MAJOR}.${LIB_MINOR}'
		LIB_LDFLAGS_INSTALL_NAME=''
		LIB_PREFIX='lib'
		LIB_SUFFIX='.so'
		AS_IF([test x"$enable_rpath" != x"no"], [
			LDFLAGS_RPATH='-Wl,-rpath,${libdir}'
		])
		INSTALL_LIB='&& ${INSTALL} -m 755 $$i ${DESTDIR}${libdir}/$$i.${LIB_MAJOR}.${LIB_MINOR} && rm -f ${DESTDIR}${libdir}/$$i && ${LN_S} $$i.${LIB_MAJOR}.${LIB_MINOR} ${DESTDIR}${libdir}/$$i'
		UNINSTALL_LIB='&& rm -f ${DESTDIR}${libdir}/$$i ${DESTDIR}${libdir}/$$i.${LIB_MAJOR}.${LIB_MINOR}'
		CLEAN_LIB=''
		;;
	*-*-android*)
		AC_MSG_RESULT(Android)
		LIB_CFLAGS='-fPIC -DPIC'
		LIB_LDFLAGS='-shared -Wl,-soname=$$out.${LIB_MAJOR}'
		LIB_LDFLAGS_INSTALL_NAME=''
		LIB_PREFIX='lib'
		LIB_SUFFIX='.so'
		INSTALL_LIB='&& ${INSTALL} -m 755 $$i ${DESTDIR}${libdir}/$$i.${LIB_MAJOR}.${LIB_MINOR}.${LIB_PATCH} && ${LN_S} -f $$i.${LIB_MAJOR}.${LIB_MINOR}.${LIB_PATCH} ${DESTDIR}${libdir}/$$i.${LIB_MAJOR} && ${LN_S} -f $$i.${LIB_MAJOR}.${LIB_MINOR}.${LIB_PATCH} ${DESTDIR}${libdir}/$$i'
		UNINSTALL_LIB='&& rm -f ${DESTDIR}${libdir}/$$i ${DESTDIR}${libdir}/$$i.${LIB_MAJOR} ${DESTDIR}${libdir}/$$i.${LIB_MAJOR}.${LIB_MINOR}.${LIB_PATCH}'
		CLEAN_LIB=''
		;;
	hppa*-*-hpux*)
		AC_MSG_RESULT([HP-UX (PA-RISC)])
		LIB_CFLAGS='-fPIC -DPIC'
		LIB_LDFLAGS='-shared -Wl,+h,$$out'
		LIB_LDFLAGS_INSTALL_NAME=''
		LIB_PREFIX='lib'
		LIB_SUFFIX='.${LIB_MAJOR}'
		LINK_LIB='&& rm -f $${out%%.*}.sl && ${LN_S} $$out $${out%%.*}.sl'
		AS_IF([test x"$enable_rpath" != x"no"], [
			LDFLAGS_RPATH='-Wl,+b,${libdir}'
		])
		INSTALL_LIB='&& ${INSTALL} -m 755 $$i ${DESTDIR}${libdir}/$$i && ${LN_S} -f $$i ${DESTDIR}${libdir}/$${i%%.*}.sl'
		UNINSTALL_LIB='&& rm -f ${DESTDIR}${libdir}/$$i ${DESTDIR}${libdir}/$${i%%.*}.sl'
		CLEAN_LIB=''
		;;
	ia64*-*-hpux*)
		AC_MSG_RESULT([HP-UX (Itanium)])
		LIB_CFLAGS='-fPIC -DPIC'
		LIB_LDFLAGS='-shared -Wl,+h,$$out'
		LIB_LDFLAGS_INSTALL_NAME=''
		LIB_PREFIX='lib'
		LIB_SUFFIX='.${LIB_MAJOR}'
		LINK_LIB='&& rm -f $${out%%.*}.so && ${LN_S} $$out $${out%%.*}.so'
		AS_IF([test x"$enable_rpath" != x"no"], [
			LDFLAGS_RPATH='-Wl,+b,${libdir}'
		])
		INSTALL_LIB='&& ${INSTALL} -m 755 $$i ${DESTDIR}${libdir}/$$i && ${LN_S} -f $$i ${DESTDIR}${libdir}/$${i%%.*}.so'
		UNINSTALL_LIB='&& rm -f ${DESTDIR}${libdir}/$$i ${DESTDIR}${libdir}/$${i%%.*}.so'
		CLEAN_LIB=''
		;;
	*)
		AC_MSG_RESULT(ELF)
		LIB_CFLAGS='-fPIC -DPIC'
		LIB_LDFLAGS='-shared -Wl,-soname=$$out.${LIB_MAJOR}'
		LIB_LDFLAGS_INSTALL_NAME=''
		LIB_PREFIX='lib'
		LIB_SUFFIX='.so'
		AS_IF([test x"$enable_rpath" != x"no"], [
			LDFLAGS_RPATH='-Wl,-rpath,${libdir}'
		])
		INSTALL_LIB='&& ${INSTALL} -m 755 $$i ${DESTDIR}${libdir}/$$i.${LIB_MAJOR}.${LIB_MINOR}.${LIB_PATCH} && ${LN_S} -f $$i.${LIB_MAJOR}.${LIB_MINOR}.${LIB_PATCH} ${DESTDIR}${libdir}/$$i.${LIB_MAJOR} && ${LN_S} -f $$i.${LIB_MAJOR}.${LIB_MINOR}.${LIB_PATCH} ${DESTDIR}${libdir}/$$i'
		UNINSTALL_LIB='&& rm -f ${DESTDIR}${libdir}/$$i ${DESTDIR}${libdir}/$$i.${LIB_MAJOR} ${DESTDIR}${libdir}/$$i.${LIB_MAJOR}.${LIB_MINOR}.${LIB_PATCH}'
		CLEAN_LIB=''
		;;
	esac

	AC_SUBST(LIB_CFLAGS)
	AC_SUBST(LIB_LDFLAGS)
	AC_SUBST(LIB_LDFLAGS_INSTALL_NAME)
	AC_SUBST(LIB_PREFIX)
	AC_SUBST(LIB_SUFFIX)
	AC_SUBST(LINK_LIB)
	AC_SUBST(LDFLAGS_RPATH)
	AC_SUBST(INSTALL_LIB)
	AC_SUBST(UNINSTALL_LIB)
	AC_SUBST(CLEAN_LIB)
])

AC_DEFUN([BUILDSYS_FRAMEWORK], [
	AC_REQUIRE([AC_CANONICAL_HOST])
	AC_REQUIRE([BUILDSYS_CHECK_IOS])
	AC_REQUIRE([BUILDSYS_SHARED_LIB])

	case "$host_os" in
	darwin*)
		FRAMEWORK_LDFLAGS='-dynamiclib -current_version ${LIB_MAJOR}.${LIB_MINOR} -compatibility_version ${LIB_MAJOR}'
		AS_IF([test x"$host_is_ios" = x"yes"], [
			FRAMEWORK_LDFLAGS_INSTALL_NAME='-Wl,-install_name,@executable_path/Frameworks/$$out/$${out%.framework}'
		], [
			FRAMEWORK_LDFLAGS_INSTALL_NAME='-Wl,-install_name,@executable_path/../Frameworks/$$out/$${out%.framework}'
		])

		AC_SUBST(FRAMEWORK_LDFLAGS)
		AC_SUBST(FRAMEWORK_LDFLAGS_INSTALL_NAME)
		AC_SUBST(FRAMEWORK_LIBS)

		$1
		;;
	*)
		$2
		;;
	esac
])

AC_DEFUN([BUILDSYS_PLUGIN], [
	AC_REQUIRE([AC_CANONICAL_HOST])
	AC_REQUIRE([BUILDSYS_CHECK_IOS])
	AC_MSG_CHECKING(for plugin type)

	case "$host" in
	*-*-darwin*)
		AC_MSG_RESULT(Darwin)
		PLUGIN_CFLAGS='-fPIC -DPIC'
		PLUGIN_LDFLAGS='-bundle'
		PLUGIN_SUFFIX='.dylib'
		;;
	*-*-mingw* | *-*-cygwin*)
		AC_MSG_RESULT(MinGW / Cygwin)
		PLUGIN_CFLAGS=''
		PLUGIN_LDFLAGS='-shared -Wl,--export-all-symbols'
		PLUGIN_SUFFIX='.dll'
		;;
	hppa*-*-hpux*)
		AC_MSG_RESULT([HP-UX (PA-RISC)])
		PLUGIN_CFLAGS='-fPIC -DPIC'
		PLUGIN_LDFLAGS='-shared'
		PLUGIN_SUFFIX='.sl'
		;;
	*)
		AC_MSG_RESULT(ELF)
		PLUGIN_CFLAGS='-fPIC -DPIC'
		PLUGIN_LDFLAGS='-shared'
		PLUGIN_SUFFIX='.so'
		;;
	esac

	AC_SUBST(PLUGIN_CFLAGS)
	AC_SUBST(PLUGIN_LDFLAGS)
	AC_SUBST(PLUGIN_SUFFIX)
])

AC_DEFUN([BUILDSYS_BUNDLE], [
	AC_REQUIRE([AC_CANONICAL_HOST])
	AC_REQUIRE([BUILDSYS_CHECK_IOS])
	AC_REQUIRE([BUILDSYS_PLUGIN])

	case "$host_os" in
	darwin*)
		AS_IF([test x"$host_is_ios" = x"yes"], [
			LINK_BUNDLE='${MKDIR_P} $$out && ${INSTALL} -m 644 Info.plist $$out/Info.plist && ${LD} -o $$out/$${out%.bundle} ${PLUGIN_OBJS} ${PLUGIN_OBJS_EXTRA} ${PLUGIN_LDFLAGS} ${LDFLAGS} ${LIBS}'
		], [
			LINK_BUNDLE='${MKDIR_P} $$out/Contents/MacOS && ${INSTALL} -m 644 Info.plist $$out/Contents/Info.plist && ${LD} -o $$out/Contents/MacOS/$${out%.bundle} ${PLUGIN_OBJS} ${PLUGIN_OBJS_EXTRA} ${PLUGIN_LDFLAGS} ${LDFLAGS} ${LIBS}'
		])

		AC_SUBST(LINK_BUNDLE)

		$1
		;;
	*)
		$2
		;;
	esac
])
