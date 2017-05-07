/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#define _WIN32_WINNT 0x0501

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>

#import "resolver.h"

#import "macros.h"

#if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
# include "threading.h"
#endif

#import "OFAddressTranslationFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
# import "OFLockFailedException.h"
# import "OFUnlockFailedException.h"
#endif

#import "socket_helpers.h"

#if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
static of_mutex_t mutex;

OF_CONSTRUCTOR()
{
	if (!of_mutex_new(&mutex))
		@throw [OFInitializationFailedException exception];
}
#endif

of_resolver_result_t **
of_resolve_host(OFString *host, uint16_t port, int type)
{
	of_resolver_result_t **ret, **retIter;
	of_resolver_result_t *results, *resultsIter;
	size_t count;
#ifdef HAVE_GETADDRINFO
	struct addrinfo hints = { 0 }, *res, *res0;
	char portCString[7];

	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = type;
	hints.ai_flags = AI_NUMERICSERV;
	snprintf(portCString, 7, "%" PRIu16, port);

# if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

	@try {
# endif
		int error;

		if ((error = getaddrinfo([host UTF8String], portCString, &hints,
		    &res0)) != 0)
			@throw [OFAddressTranslationFailedException
			    exceptionWithHost: host
					error: error];

		count = 0;
		for (res = res0; res != NULL; res = res->ai_next)
			count++;

		if (count == 0) {
			freeaddrinfo(res0);
			@throw [OFAddressTranslationFailedException
			    exceptionWithHost: host];
		}

		if ((ret = calloc(count + 1, sizeof(*ret))) == NULL) {
			freeaddrinfo(res0);
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: (count + 1) *
							sizeof(*ret)];
		}

		if ((results = malloc(count * sizeof(*results))) == NULL) {
			freeaddrinfo(res0);
			free(ret);
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: count *
							sizeof(*results)];
		}

		for (retIter = ret, resultsIter = results, res = res0;
		    res != NULL; retIter++, resultsIter++, res = res->ai_next) {
			resultsIter->family = res->ai_family;
			resultsIter->type = res->ai_socktype;
			resultsIter->protocol = res->ai_protocol;
			resultsIter->address = res->ai_addr;
			resultsIter->addressLength = (socklen_t)res->ai_addrlen;

			*retIter = resultsIter;
		}
		*retIter = NULL;

		ret[0]->private_ = res0;
# if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
	} @finally {
		if (!of_mutex_unlock(&mutex))
			@throw [OFUnlockFailedException exception];
	}
# endif
#else
# ifdef OF_HAVE_THREADS
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

	@try {
# endif
		in_addr_t s_addr;
		struct hostent *he;
		char **ip;
		struct sockaddr_in *addrs, *addrsIter;

		/*
		 * If the host is an IP address, don't try resolving it. On the
		 * Wii for example, the resolver will return an error if you
		 * specify an IP address.
		 */
		if ((s_addr = inet_addr([host UTF8String])) != INADDR_NONE) {
			of_resolver_result_t *tmp;
			struct sockaddr_in *addr;

			if ((ret = calloc(2, sizeof(*ret))) == NULL)
				@throw [OFOutOfMemoryException
				    exceptionWithRequestedSize: 2 *
								sizeof(*ret)];

			if ((tmp = malloc(sizeof(*tmp))) == NULL) {
				free(ret);
				@throw [OFOutOfMemoryException
				    exceptionWithRequestedSize: sizeof(*tmp)];
			}

			if ((addr = calloc(1, sizeof(*addr))) == NULL) {
				free(ret);
				free(tmp);
				@throw [OFOutOfMemoryException
				    exceptionWithRequestedSize: sizeof(*addr)];
			}

#ifdef OF_WII
			addr->sin_len = 8;
#endif
			addr->sin_family = AF_INET;
			addr->sin_port = OF_BSWAP16_IF_LE(port);
			addr->sin_addr.s_addr = s_addr;

			tmp->family = AF_INET;
			tmp->type = type;
			tmp->protocol = 0;
			tmp->address = (struct sockaddr *)addr;
#ifndef OF_WII
			tmp->addressLength = sizeof(*addr);
#else
			tmp->addressLength = 8;
#endif

			ret[0] = tmp;
			ret[1] = NULL;

			return ret;
		}

		if ((he = gethostbyname([host UTF8String])) == NULL ||
		    he->h_addrtype != AF_INET)
			@throw [OFAddressTranslationFailedException
			    exceptionWithHost: host
					error: h_errno];

		count = 0;
		for (ip = he->h_addr_list; *ip != NULL; ip++)
			count++;

		if (count == 0)
			@throw [OFAddressTranslationFailedException
			    exceptionWithHost: host];

		if ((ret = calloc(count + 1, sizeof(*ret))) == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: (count + 1) *
							sizeof(*ret)];

		if ((results = malloc(count * sizeof(*results))) == NULL) {
			free(ret);
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: count *
							sizeof(*results)];
		}

		if ((addrs = calloc(count, sizeof(*addrs))) == NULL) {
			free(ret);
			free(results);
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: count * sizeof(*addrs)];
		}

		for (retIter = ret, resultsIter = results, addrsIter = addrs,
		    ip = he->h_addr_list; *ip != NULL;
		    retIter++, resultsIter++, addrsIter++, ip++) {
			addrsIter->sin_family = he->h_addrtype;
			addrsIter->sin_port = OF_BSWAP16_IF_LE(port);

			if (he->h_length > sizeof(addrsIter->sin_addr.s_addr))
				@throw [OFOutOfRangeException exception];

			memcpy(&addrsIter->sin_addr.s_addr, *ip, he->h_length);

			resultsIter->family = he->h_addrtype;
			resultsIter->type = type;
			resultsIter->protocol = 0;
			resultsIter->address = (struct sockaddr *)addrsIter;
			resultsIter->addressLength = sizeof(*addrsIter);

			*retIter = resultsIter;
		}
# ifdef OF_HAVE_THREADS
	} @finally {
		if (!of_mutex_unlock(&mutex))
			@throw [OFUnlockFailedException exception];
	}
# endif
#endif

	return ret;
}

void
of_address_to_string_and_port(struct sockaddr *address, socklen_t addressLength,
    OFString *__autoreleasing *host, uint16_t *port)
{
#ifdef HAVE_GETADDRINFO
	char hostCString[NI_MAXHOST];
	char portCString[NI_MAXSERV];

# if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

	@try {
# endif
		int error;

		/* FIXME: Add NI_DGRAM for UDP? */
		if ((error = getnameinfo(address, addressLength, hostCString,
		    NI_MAXHOST, portCString, NI_MAXSERV,
		    NI_NUMERICHOST | NI_NUMERICSERV)) != 0)
			@throw [OFAddressTranslationFailedException
			    exceptionWithError: error];

		if (host != NULL)
			*host = [OFString stringWithUTF8String: hostCString];

		if (port != NULL) {
			char *endptr;
			long tmp;

			if ((tmp = strtol(portCString, &endptr, 10)) >
			    UINT16_MAX)
				@throw [OFOutOfRangeException exception];

			if (endptr != NULL && *endptr != '\0')
				@throw [OFAddressTranslationFailedException
				    exception];

			*port = (uint16_t)tmp;
		}
# if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
	} @finally {
		if (!of_mutex_unlock(&mutex))
			@throw [OFUnlockFailedException exception];
	}
# endif
#else
	char *hostCString;

	if (address->sa_family != AF_INET)
		@throw [OFInvalidArgumentException exception];

# if OF_HAVE_THREADS
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

	@try {
# endif
		if ((hostCString = inet_ntoa(
		    ((struct sockaddr_in *)(void *)address)->sin_addr)) == NULL)
			@throw [OFAddressTranslationFailedException
			    exceptionWithError: h_errno];

		if (host != NULL)
			*host = [OFString stringWithUTF8String: hostCString];

		if (port != NULL)
			*port = OF_BSWAP16_IF_LE(
			    ((struct sockaddr_in *)(void *)address)->sin_port);
# if OF_HAVE_THREADS
	} @finally {
		if (!of_mutex_unlock(&mutex))
			@throw [OFUnlockFailedException exception];
	}
# endif
#endif
}

void
of_resolver_free(of_resolver_result_t **results)
{
#ifdef HAVE_GETADDRINFO
	freeaddrinfo(results[0]->private_);
#else
	free(results[0]->address);
#endif
	free(results[0]);
	free(results);
}
