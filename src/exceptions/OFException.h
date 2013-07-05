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

#import "OFObject.h"

@class OFString;
@class OFArray;
@class OFMutableArray;

#define OF_BACKTRACE_SIZE 32

#if defined(_WIN32) && defined(OF_HAVE_SOCKETS)
# define EADDRINUSE WSAEADDRINUSE
# define EADDRNOTAVAIL WSAEADDRNOTAVAIL
# define EAFNOSUPPORT WSAEAFNOSUPPORT
# define EALREADY WSAEALREADY
# define ECONNABORTED WSAECONNABORTED
# define ECONNABORTED WSAECONNABORTED
# define ECONNREFUSED WSAECONNREFUSED
# define ECONNRESET WSAECONNRESET
# define ECONNRESET WSAECONNRESET
# define EDESTADDRREQ WSAEDESTADDRREQ
# define EDQUOT WSAEDQUOT
# define EHOSTDOWN WSAEHOSTDOWN
# define EHOSTUNREACH WSAEHOSTUNREACH
# define EINPROGRESS WSAEINPROGRESS
# define EISCONN WSAEISCONN
# define ELOOP WSAELOOP
# define EMSGSIZE WSAEMSGSIZE
# define ENETDOWN WSAENETDOWN
# define ENETRESET WSAENETRESET
# define ENETUNREACH WSAENETUNREACH
# define ENOBUFS WSAENOBUFS
# define ENOPROTOOPT WSAENOPROTOOPT
# define ENOTCONN WSAENOTCONN
# define ENOTSOCK WSAENOTSOCK
# define EOPNOTSUPP WSAEOPNOTSUPP
# define EPFNOSUPPORT WSAEPFNOSUPPORT
# define EPROCLIM WSAEPROCLIM
# define EPROTONOSUPPORT WSAEPROTONOSUPPORT
# define EPROTOTYPE WSAEPROTOTYPE
# define EREMOTE WSAEREMOTE
# define ESHUTDOWN WSAESHUTDOWN
# define ESOCKTNOSUPPORT WSAESOCKTNOSUPPORT
# define ESTALE WSAESTALE
# define ETIMEDOUT WSAETIMEDOUT
# define ETOOMANYREFS WSAETOOMANYREFS
# define EUSERS WSAEUSERS
# define EWOULDBLOCK WSAEWOULDBLOCK
extern int of_wsaerr_to_errno(int);
#endif

/*!
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
