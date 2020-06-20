/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#import "ObjFW.h"
#import "amiga-library.h"
#import "macros.h"

#include <proto/exec.h>

struct ObjFWBase;

#import "inline.h"

#include <locale.h>
#include <stdio.h>
#include <stdlib.h>

#if defined(OF_AMIGAOS_M68K)
# include <stabs.h>
# define SYM(name) __asm__("_" name)
#elif defined(OF_MORPHOS)
# include <constructor.h>
# define SYM(name) __asm__(name)
#endif

#ifdef HAVE_SJLJ_EXCEPTIONS
extern int _Unwind_SjLj_RaiseException(void *);
#else
extern int _Unwind_RaiseException(void *);
#endif
extern void _Unwind_DeleteException(void *);
extern void *_Unwind_GetLanguageSpecificData(void *);
extern uintptr_t _Unwind_GetRegionStart(void *);
extern uintptr_t _Unwind_GetDataRelBase(void *);
extern uintptr_t _Unwind_GetTextRelBase(void *);
extern uintptr_t _Unwind_GetIP(void *);
extern uintptr_t _Unwind_GetGR(void *, int);
extern void _Unwind_SetIP(void *, uintptr_t);
extern void _Unwind_SetGR(void *, int, uintptr_t);
#ifdef HAVE_SJLJ_EXCEPTIONS
extern void _Unwind_SjLj_Resume(void *);
#else
extern void _Unwind_Resume(void *);
#endif
#ifdef OF_AMIGAOS_M68K
extern void __register_frame_info(const void *, void *);
extern void *__deregister_frame_info(const void *);
#endif
extern int _Unwind_Backtrace(int (*)(void *, void *), void *);

struct Library *ObjFWBase;

static void __attribute__((__used__))
ctor(void)
{
	static bool initialized = false;
	struct of_libc libc = {
		.malloc = malloc,
		.calloc = calloc,
		.realloc = realloc,
		.free = free,
		.vfprintf = vfprintf,
		.fflush = fflush,
		.abort = abort,
#ifdef HAVE_SJLJ_EXCEPTIONS
		._Unwind_SjLj_RaiseException = _Unwind_SjLj_RaiseException,
#else
		._Unwind_RaiseException = _Unwind_RaiseException,
#endif
		._Unwind_DeleteException = _Unwind_DeleteException,
		._Unwind_GetLanguageSpecificData =
		    _Unwind_GetLanguageSpecificData,
		._Unwind_GetRegionStart = _Unwind_GetRegionStart,
		._Unwind_GetDataRelBase = _Unwind_GetDataRelBase,
		._Unwind_GetTextRelBase = _Unwind_GetTextRelBase,
		._Unwind_GetIP = _Unwind_GetIP,
		._Unwind_GetGR = _Unwind_GetGR,
		._Unwind_SetIP = _Unwind_SetIP,
		._Unwind_SetGR = _Unwind_SetGR,
#ifdef HAVE_SJLJ_EXCEPTIONS
		._Unwind_SjLj_Resume = _Unwind_SjLj_Resume,
#else
		._Unwind_Resume = _Unwind_Resume,
#endif
#ifdef OF_AMIGAOS_M68K
		.__register_frame_info = __register_frame_info,
		.__deregister_frame_info = __deregister_frame_info,
#endif
		.vsnprintf = vsnprintf,
#ifdef OF_AMIGAOS_M68K
		.vsscanf = vsscanf,
#endif
		.exit = exit,
		.signal = signal,
		.setlocale = setlocale,
		._Unwind_Backtrace = _Unwind_Backtrace
	};

	if (initialized)
		return;

	if ((ObjFWBase = OpenLibrary(OBJFW_AMIGA_LIB,
	    OBJFW_LIB_MINOR)) == NULL) {
		/*
		 * The linklib can be used by other libraries as well, so we
		 * can't have the compiler optimize this to another function,
		 * hence the use of an unnecessary format specifier.
		 */
		fprintf(stderr, "Failed to open %s!\n", OBJFW_AMIGA_LIB);
		abort();
	}

	if (!glue_of_init(1, &libc, __sF)) {
		/*
		 * The linklib can be used by other libraries as well, so we
		 * can't have the compiler optimize this to another function,
		 * hence the use of an unnecessary format specifier.
		 */
		fprintf(stderr, "Failed to initialize %s!\n", OBJFW_AMIGA_LIB);
		abort();
	}

	initialized = true;
}

static void __attribute__((__used__))
dtor(void)
{
	CloseLibrary(ObjFWBase);
}

#if defined(OF_AMIGAOS_M68K)
ADD2INIT(ctor, -2);
ADD2EXIT(dtor, -2);
#elif defined(OF_MORPHOS)
CONSTRUCTOR_P(ObjFW, 4000)
{
	ctor();

	return 0;
}

DESTRUCTOR_P(ObjFW, 4000)
{
	dtor();
}
#endif

int
of_application_main(int *argc, char ***argv,
    id <OFApplicationDelegate> delegate)
{
	return glue_of_application_main(argc, argv, delegate);
}

const char *
of_http_request_method_to_string(of_http_request_method_t method)
{
	return glue_of_http_request_method_to_string(method);
}

of_http_request_method_t
of_http_request_method_from_string(OFString *string)
{
	return glue_of_http_request_method_from_string(string);
}

OFString *
of_http_status_code_to_string(short code)
{
	return glue_of_http_status_code_to_string(code);
}

size_t
of_sizeof_type_encoding(const char *type)
{
	return glue_of_sizeof_type_encoding(type);
}

size_t
of_alignof_type_encoding(const char *type)
{
	return glue_of_alignof_type_encoding(type);
}

void
of_logv(OFConstantString *format, va_list arguments)
{
	glue_of_logv(format, arguments);
}

OFString *
of_zip_archive_entry_version_to_string(uint16_t version)
{
	return glue_of_zip_archive_entry_version_to_string(version);
}

OFString *
of_zip_archive_entry_compression_method_to_string(uint16_t compressionMethod)
{
	return glue_of_zip_archive_entry_compression_method_to_string(
	    compressionMethod);
}

size_t
of_zip_archive_entry_extra_field_find(OFData *extraField, uint16_t tag,
    uint16_t *size)
{
	return glue_of_zip_archive_entry_extra_field_find(
	    extraField, tag, size);
}

void
of_pbkdf2(OFHMAC *HMAC, size_t iterations, const unsigned char *salt,
    size_t saltLength, const char *password, size_t passwordLength,
    unsigned char *key, size_t keyLength, bool allowsSwappableMemory)
{
	glue_of_pbkdf2(HMAC, iterations, salt, saltLength,
	    password, passwordLength, key, keyLength, allowsSwappableMemory);
}

void
of_scrypt(size_t blockSize, size_t costFactor, size_t parallelization,
    const unsigned char *salt, size_t saltLength, const char *password,
    size_t passwordLength, unsigned char *key, size_t keyLength,
    bool allowsSwappableMemory)
{
	glue_of_scrypt(blockSize, costFactor, parallelization, salt, saltLength,
	    password, passwordLength, key, keyLength, allowsSwappableMemory);
}

of_socket_address_t
of_socket_address_parse_ip(OFString *IP, uint16_t port)
{
	of_socket_address_t address;

	glue_of_socket_address_parse_ip(&address, IP, port);

	return address;
}

of_socket_address_t
of_socket_address_parse_ipv4(OFString *IP, uint16_t port)
{
	of_socket_address_t address;

	glue_of_socket_address_parse_ipv4(&address, IP, port);

	return address;
}

of_socket_address_t
of_socket_address_parse_ipv6(OFString *IP, uint16_t port)
{
	of_socket_address_t address;

	glue_of_socket_address_parse_ipv6(&address, IP, port);

	return address;
}

of_socket_address_t
of_socket_address_ipx(const unsigned char *node, uint32_t network,
    uint16_t port)
{
	of_socket_address_t address;

	glue_of_socket_address_ipx(&address, node, network, port);

	return address;
}

bool
of_socket_address_equal(const of_socket_address_t *address1,
    const of_socket_address_t *address2)
{
	return glue_of_socket_address_equal(address1, address2);
}

uint32_t
of_socket_address_hash(const of_socket_address_t *address)
{
	return glue_of_socket_address_hash(address);
}

OFString *
of_socket_address_ip_string(const of_socket_address_t *address, uint16_t *port)
{
	return glue_of_socket_address_ip_string(address, port);
}

void
of_socket_address_set_port(of_socket_address_t *address, uint16_t port)
{
	glue_of_socket_address_set_port(address, port);
}

uint16_t
of_socket_address_get_port(const of_socket_address_t *address)
{
	return glue_of_socket_address_get_port(address);
}

void
of_socket_address_set_ipx_network(of_socket_address_t *address,
    uint32_t network)
{
	glue_of_socket_address_set_ipx_network(address, network);
}

uint32_t
of_socket_address_get_ipx_network(const of_socket_address_t *address)
{
	return glue_of_socket_address_get_ipx_network(address);
}

void
of_socket_address_set_ipx_node(of_socket_address_t *address,
    const unsigned char *node)
{
	glue_of_socket_address_set_ipx_node(address, node);
}

void
of_socket_address_get_ipx_node(const of_socket_address_t *address,
    unsigned char *node)
{
	glue_of_socket_address_get_ipx_node(address, node);
}
