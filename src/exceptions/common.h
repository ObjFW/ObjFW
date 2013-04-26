/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <string.h>

#import "macros.h"

#ifndef _WIN32
# if defined(OF_HAVE_SOCKETS) && !defined(HAVE_THREADSAFE_GETADDRINFO)
#  include <netdb.h>
# endif
# include <errno.h>
# define GET_ERRNO	errno
# ifdef OF_HAVE_SOCKETS
#  ifndef HAVE_THREADSAFE_GETADDRINFO
#   define GET_AT_ERRNO	h_errno
#  else
#   define GET_AT_ERRNO	errno
#  endif
# define GET_SOCK_ERRNO	errno
# endif
# define ERRFMT			"Error string was: %s"
# define ERRPARAM		strerror(_errNo)
# ifdef OF_HAVE_SOCKETS
#  ifndef HAVE_THREADSAFE_GETADDRINFO
#   define AT_ERRPARAM		hstrerror(_errNo)
#  else
#   define AT_ERRPARAM		strerror(_errNo)
#  endif
# endif
#else
# include <windows.h>
# define GET_ERRNO		GetLastError()
# ifdef OF_HAVE_SOCKETS
#  define GET_AT_ERRNO		WSAGetLastError()
#  define GET_SOCK_ERRNO	WSAGetLastError()
# endif
# define ERRFMT			"Error code was: %d"
# define ERRPARAM		_errNo
# ifdef OF_HAVE_SOCKETS
#  define AT_ERRPARAM		_errNo
# endif
#endif
