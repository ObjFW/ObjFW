/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFObject.h"

@class OFString;
#ifndef DOXYGEN
@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
#endif

#define OF_BACKTRACE_SIZE 32

#if defined(OF_WINDOWS) && defined(OF_HAVE_SOCKETS)
# ifndef EADDRINUSE
#  define EADDRINUSE WSAEADDRINUSE
# endif
# ifndef EADDRNOTAVAIL
#  define EADDRNOTAVAIL WSAEADDRNOTAVAIL
# endif
# ifndef EAFNOSUPPORT
#  define EAFNOSUPPORT WSAEAFNOSUPPORT
# endif
# ifndef EALREADY
#  define EALREADY WSAEALREADY
# endif
# ifndef ECONNABORTED
#  define ECONNABORTED WSAECONNABORTED
# endif
# ifndef ECONNREFUSED
#  define ECONNREFUSED WSAECONNREFUSED
# endif
# ifndef ECONNRESET
#  define ECONNRESET WSAECONNRESET
# endif
# ifndef EDESTADDRREQ
#  define EDESTADDRREQ WSAEDESTADDRREQ
# endif
# ifndef EDQUOT
#  define EDQUOT WSAEDQUOT
# endif
# ifndef EHOSTDOWN
#  define EHOSTDOWN WSAEHOSTDOWN
# endif
# ifndef EHOSTUNREACH
#  define EHOSTUNREACH WSAEHOSTUNREACH
# endif
# ifndef EINPROGRESS
#  define EINPROGRESS WSAEINPROGRESS
# endif
# ifndef EISCONN
#  define EISCONN WSAEISCONN
# endif
# ifndef ELOOP
#  define ELOOP WSAELOOP
# endif
# ifndef EMSGSIZE
#  define EMSGSIZE WSAEMSGSIZE
# endif
# ifndef ENETDOWN
#  define ENETDOWN WSAENETDOWN
# endif
# ifndef ENETRESET
#  define ENETRESET WSAENETRESET
# endif
# ifndef ENETUNREACH
#  define ENETUNREACH WSAENETUNREACH
# endif
# ifndef ENOBUFS
#  define ENOBUFS WSAENOBUFS
# endif
# ifndef ENOPROTOOPT
#  define ENOPROTOOPT WSAENOPROTOOPT
# endif
# ifndef ENOTCONN
#  define ENOTCONN WSAENOTCONN
# endif
# ifndef ENOTSOCK
#  define ENOTSOCK WSAENOTSOCK
# endif
# ifndef EOPNOTSUPP
#  define EOPNOTSUPP WSAEOPNOTSUPP
# endif
# ifndef EPFNOSUPPORT
#  define EPFNOSUPPORT WSAEPFNOSUPPORT
# endif
# ifndef EPROCLIM
#  define EPROCLIM WSAEPROCLIM
# endif
# ifndef EPROTONOSUPPORT
#  define EPROTONOSUPPORT WSAEPROTONOSUPPORT
# endif
# ifndef EPROTOTYPE
#  define EPROTOTYPE WSAEPROTOTYPE
# endif
# ifndef EREMOTE
#  define EREMOTE WSAEREMOTE
# endif
# ifndef ESHUTDOWN
#  define ESHUTDOWN WSAESHUTDOWN
# endif
# ifndef ESOCKTNOSUPPORT
#  define ESOCKTNOSUPPORT WSAESOCKTNOSUPPORT
# endif
# ifndef ESTALE
#  define ESTALE WSAESTALE
# endif
# ifndef ETIMEDOUT
#  define ETIMEDOUT WSAETIMEDOUT
# endif
# ifndef ETOOMANYREFS
#  define ETOOMANYREFS WSAETOOMANYREFS
# endif
# ifndef EUSERS
#  define EUSERS WSAEUSERS
# endif
# ifndef EWOULDBLOCK
#  define EWOULDBLOCK WSAEWOULDBLOCK
# endif
extern int of_wsaerr_to_errno(int);
#endif

/*!
 * @class OFException OFException.h ObjFW/OFException.h
 *
 * @brief The base class for all exceptions in ObjFW
 *
 * The OFException class is the base class for all exceptions in ObjFW, except
 * the OFAllocFailedException.
 */
@interface OFException: OFObject
{
	void *_backtrace[OF_BACKTRACE_SIZE];
}

/*!
 * @brief Creates a new, autoreleased exception.
 *
 * @return A new, autoreleased exception
 */
+ (instancetype)exception;

/*!
 * @brief Returns a description of the exception.
 *
 * @return A description of the exception
 */
- (OFString*)description;

/*!
 * @brief Returns a backtrace of when the exception was created or nil if no
 *	  backtrace is available.
 *
 * @return A backtrace of when the exception was created
 */
- (OFArray*)backtrace;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern OFString* of_strerror(int errNo);
#ifdef __cplusplus
}
#endif
