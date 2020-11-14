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

#import "OFApplication.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFMethodSignature.h"
#import "OFObject.h"
#import "OFStdIOStream.h"
#import "OFString.h"
#import "OFZIPArchiveEntry.h"

#import "amiga-library.h"
#import "of_strptime.h"
#import "pbkdf2.h"
#import "platform.h"
#import "scrypt.h"
#import "socket.h"

#ifdef OF_AMIGAOS_M68K
# define PPC_PARAMS(...) (void)
# define M68K_ARG OF_M68K_ARG
#else
# define PPC_PARAMS(...) (__VA_ARGS__)
# define M68K_ARG(...)
#endif

#ifdef OF_MORPHOS
/* All __saveds functions in this file need to use the SysV ABI */
__asm__ (
    ".section .text\n"
    ".align 2\n"
    "__restore_r13:\n"
    "	lwz	%r13, 44(%r12)\n"
    "	blr\n"
);
#endif

bool __saveds
glue_of_init PPC_PARAMS(unsigned int version, struct of_libc *libc, FILE **sF)
{
	M68K_ARG(unsigned int, version, d0)
	M68K_ARG(struct of_libc *, libc, a0)
	M68K_ARG(FILE **, sF, a1)

	return of_init(version, libc, sF);
}

int __saveds
glue_of_application_main PPC_PARAMS(int *argc, char ***argv,
    id <OFApplicationDelegate> delegate)
{
	M68K_ARG(int *, argc, a0)
	M68K_ARG(char ***, argv, a1)
	M68K_ARG(id <OFApplicationDelegate>, delegate, a2)

	return of_application_main(argc, argv, delegate);
}

void *__saveds
glue_of_malloc PPC_PARAMS(size_t count, size_t size)
{
	M68K_ARG(size_t, count, d0)
	M68K_ARG(size_t, size, d1)

	return of_malloc(count, size);
}

void *__saveds
glue_of_calloc PPC_PARAMS(size_t count, size_t size)
{
	M68K_ARG(size_t, count, d0)
	M68K_ARG(size_t, size, d1)

	return of_calloc(count, size);
}

void *__saveds
glue_of_realloc PPC_PARAMS(void *pointer, size_t count, size_t size)
{
	M68K_ARG(void *, pointer, a0)
	M68K_ARG(size_t, count, d0)
	M68K_ARG(size_t, size, d1)

	return of_realloc(pointer, count, size);
}

uint32_t *__saveds
glue_of_hash_seed_ref(void)
{
	return of_hash_seed_ref();
}

OFStdIOStream **__saveds
glue_of_stdin_ref(void)
{
	return of_stdin_ref();
}

OFStdIOStream **__saveds
glue_of_stdout_ref(void)
{
	return of_stdout_ref();
}

OFStdIOStream **__saveds
glue_of_stderr_ref(void)
{
	return of_stderr_ref();
}

void __saveds
glue_of_logv PPC_PARAMS(OFConstantString *format, va_list arguments)
{
	M68K_ARG(OFConstantString *, format, a0)
	M68K_ARG(va_list, arguments, a1)

	of_logv(format, arguments);
}

const char *__saveds
glue_of_http_request_method_to_string PPC_PARAMS(
    of_http_request_method_t method)
{
	M68K_ARG(of_http_request_method_t, method, d0)

	return of_http_request_method_to_string(method);
}

of_http_request_method_t __saveds
glue_of_http_request_method_from_string PPC_PARAMS(OFString *string)
{
	M68K_ARG(OFString *, string, a0)

	return of_http_request_method_from_string(string);
}

OFString *__saveds
glue_of_http_status_code_to_string PPC_PARAMS(short code)
{
	M68K_ARG(short, code, d0)

	return of_http_status_code_to_string(code);
}

size_t __saveds
glue_of_sizeof_type_encoding PPC_PARAMS(const char *type)
{
	M68K_ARG(const char *, type, a0)

	return of_sizeof_type_encoding(type);
}

size_t __saveds
glue_of_alignof_type_encoding PPC_PARAMS(const char *type)
{
	M68K_ARG(const char *, type, a0)

	return of_alignof_type_encoding(type);
}

of_string_encoding_t __saveds
glue_of_string_parse_encoding PPC_PARAMS(OFString *string)
{
	M68K_ARG(OFString *, string, a0)

	return of_string_parse_encoding(string);
}

OFString *__saveds
glue_of_string_name_of_encoding PPC_PARAMS(of_string_encoding_t encoding)
{
	M68K_ARG(of_string_encoding_t, encoding, d0)

	return of_string_name_of_encoding(encoding);
}

size_t __saveds
glue_of_string_utf8_encode PPC_PARAMS(of_unichar_t c, char *UTF8)
{
	M68K_ARG(of_unichar_t, c, d0)
	M68K_ARG(char *, UTF8, a0)

	return of_string_utf8_encode(c, UTF8);
}

ssize_t __saveds
glue_of_string_utf8_decode PPC_PARAMS(const char *UTF8, size_t len,
    of_unichar_t *c)
{
	M68K_ARG(const char *, UTF8, a0)
	M68K_ARG(size_t, len, d0)
	M68K_ARG(of_unichar_t *, c, a1)

	return of_string_utf8_decode(UTF8, len, c);
}

size_t __saveds
glue_of_string_utf16_length PPC_PARAMS(const of_char16_t *string)
{
	M68K_ARG(const of_char16_t *, string, a0)

	return of_string_utf16_length(string);
}

size_t __saveds
glue_of_string_utf32_length PPC_PARAMS(const of_char32_t *string)
{
	M68K_ARG(const of_char32_t *, string, a0)

	return of_string_utf32_length(string);
}

OFString *__saveds
glue_of_zip_archive_entry_version_to_string PPC_PARAMS(uint16_t version)
{
	M68K_ARG(uint16_t, version, d0)

	return of_zip_archive_entry_version_to_string(version);
}

OFString *__saveds
glue_of_zip_archive_entry_compression_method_to_string PPC_PARAMS(
    uint16_t compressionMethod)
{
	M68K_ARG(uint16_t, compressionMethod, d0)

	return of_zip_archive_entry_compression_method_to_string(
	    compressionMethod);
}

size_t __saveds
glue_of_zip_archive_entry_extra_field_find PPC_PARAMS(OFData *extraField,
    uint16_t tag, uint16_t *size)
{
	M68K_ARG(OFData *, extraField, a0)
	M68K_ARG(uint16_t, tag, d0)
	M68K_ARG(uint16_t *, size, a1)

	return of_zip_archive_entry_extra_field_find(extraField, tag, size);
}

void __saveds
glue_of_pbkdf2 PPC_PARAMS(const of_pbkdf2_parameters_t *param)
{
	M68K_ARG(const of_pbkdf2_parameters_t *, param, a0)

	of_pbkdf2(*param);
}

void __saveds
glue_of_salsa20_8_core PPC_PARAMS(uint32_t *buffer)
{
	M68K_ARG(uint32_t *, buffer, a0)

	of_salsa20_8_core(buffer);
}

void __saveds
glue_of_scrypt_block_mix PPC_PARAMS(uint32_t *output, const uint32_t *input,
    size_t blockSize)
{
	M68K_ARG(uint32_t *, output, a0)
	M68K_ARG(const uint32_t *, input, a1)
	M68K_ARG(size_t, blockSize, d0)

	of_scrypt_block_mix(output, input, blockSize);
}

void __saveds
glue_of_scrypt_romix PPC_PARAMS(uint32_t *buffer, size_t blockSize,
    size_t costFactor, uint32_t *tmp)
{
	M68K_ARG(uint32_t *, buffer, a0)
	M68K_ARG(size_t, blockSize, d0)
	M68K_ARG(size_t, costFactor, d1)
	M68K_ARG(uint32_t *, tmp, a1)

	of_scrypt_romix(buffer, blockSize, costFactor, tmp);
}

void __saveds
glue_of_scrypt PPC_PARAMS(const of_scrypt_parameters_t *param)
{
	M68K_ARG(const of_scrypt_parameters_t *, param, a0)

	of_scrypt(*param);
}

const char *__saveds
glue_of_strptime PPC_PARAMS(const char *buf, const char *fmt, struct tm *tm,
    int16_t *tz)
{
	M68K_ARG(const char *, buf, a0)
	M68K_ARG(const char *, fmt, a1)
	M68K_ARG(struct tm *, tm, a2)
	M68K_ARG(int16_t *, tz, a3)

	return of_strptime(buf, fmt, tm, tz);
}

void __saveds
glue_of_socket_address_parse_ip PPC_PARAMS(of_socket_address_t *address,
    OFString *IP, uint16_t port)
{
	M68K_ARG(of_socket_address_t *, address, a0)
	M68K_ARG(OFString *, IP, a1)
	M68K_ARG(uint16_t, port, d0)

	*address = of_socket_address_parse_ip(IP, port);
}

void __saveds
glue_of_socket_address_parse_ipv4 PPC_PARAMS(of_socket_address_t *address,
    OFString *IP, uint16_t port)
{
	M68K_ARG(of_socket_address_t *, address, a0)
	M68K_ARG(OFString *, IP, a1)
	M68K_ARG(uint16_t, port, d0)

	*address = of_socket_address_parse_ipv4(IP, port);
}

void __saveds
glue_of_socket_address_parse_ipv6 PPC_PARAMS(of_socket_address_t *address,
    OFString *IP, uint16_t port)
{
	M68K_ARG(of_socket_address_t *, address, a0)
	M68K_ARG(OFString *, IP, a1)
	M68K_ARG(uint16_t, port, d0)

	*address = of_socket_address_parse_ipv6(IP, port);
}

void __saveds
glue_of_socket_address_ipx PPC_PARAMS(of_socket_address_t *address,
    const unsigned char *node, uint32_t network, uint16_t port)
{
	M68K_ARG(of_socket_address_t *, address, a0)
	M68K_ARG(const unsigned char *, node, a1)
	M68K_ARG(uint32_t, network, d0)
	M68K_ARG(uint16_t, port, d1)

	*address = of_socket_address_ipx(node, network, port);
}

bool __saveds
glue_of_socket_address_equal PPC_PARAMS(const of_socket_address_t *address1,
    const of_socket_address_t *address2)
{
	M68K_ARG(const of_socket_address_t *, address1, a0)
	M68K_ARG(const of_socket_address_t *, address2, a1)

	return of_socket_address_equal(address1, address2);
}

uint32_t __saveds
glue_of_socket_address_hash PPC_PARAMS(const of_socket_address_t *address)
{
	M68K_ARG(const of_socket_address_t *, address, a0)

	return of_socket_address_hash(address);
}

OFString *__saveds
glue_of_socket_address_ip_string PPC_PARAMS(const of_socket_address_t *address,
    uint16_t *port)
{
	M68K_ARG(const of_socket_address_t *, address, a0)
	M68K_ARG(uint16_t *, port, a1)

	return of_socket_address_ip_string(address, port);
}

void __saveds
glue_of_socket_address_set_port PPC_PARAMS(of_socket_address_t *address,
    uint16_t port)
{
	M68K_ARG(of_socket_address_t *, address, a0)
	M68K_ARG(uint16_t, port, d0)

	of_socket_address_set_port(address, port);
}

uint16_t __saveds
glue_of_socket_address_get_port PPC_PARAMS(const of_socket_address_t *address)
{
	M68K_ARG(const of_socket_address_t *, address, a0)

	return of_socket_address_get_port(address);
}

void __saveds
glue_of_socket_address_set_ipx_network PPC_PARAMS(of_socket_address_t *address,
    uint32_t network)
{
	M68K_ARG(of_socket_address_t *, address, a0)
	M68K_ARG(uint32_t, network, d0)

	of_socket_address_set_ipx_network(address, network);
}

uint32_t __saveds
glue_of_socket_address_get_ipx_network PPC_PARAMS(
    const of_socket_address_t *address)
{
	M68K_ARG(const of_socket_address_t *, address, a0)

	return of_socket_address_get_ipx_network(address);
}

void __saveds
glue_of_socket_address_set_ipx_node PPC_PARAMS(of_socket_address_t *address,
    const unsigned char *node)
{
	M68K_ARG(of_socket_address_t *, address, a0)
	M68K_ARG(const unsigned char *, node, a1)

	of_socket_address_set_ipx_node(address, node);
}

void __saveds
glue_of_socket_address_get_ipx_node PPC_PARAMS(
    const of_socket_address_t *address, unsigned char *node)
{
	M68K_ARG(const of_socket_address_t *, address, a0)
	M68K_ARG(unsigned char *, node, a1)

	of_socket_address_get_ipx_node(address, node);
}
