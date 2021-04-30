/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

#define COMPARE_V6(a, a0, a1, a2, a3, a4, a5, a6, a7)		\
	(a.sockaddr.in6.sin6_addr.s6_addr[0] == (a0 >> 8) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[1] == (a0 & 0xFF) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[2] == (a1 >> 8) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[3] == (a1 & 0xFF) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[4] == (a2 >> 8) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[5] == (a2 & 0xFF) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[6] == (a3 >> 8) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[7] == (a3 & 0xFF) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[8] == (a4 >> 8) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[9] == (a4 & 0xFF) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[10] == (a5 >> 8) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[11] == (a5 & 0xFF) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[12] == (a6 >> 8) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[13] == (a6 & 0xFF) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[14] == (a7 >> 8) &&	\
	a.sockaddr.in6.sin6_addr.s6_addr[15] == (a7 & 0xFF))
#define SET_V6(a, a0, a1, a2, a3, a4, a5, a6, a7)		\
	a.sockaddr.in6.sin6_addr.s6_addr[0] = a0 >> 8;		\
	a.sockaddr.in6.sin6_addr.s6_addr[1] = a0 & 0xFF;	\
	a.sockaddr.in6.sin6_addr.s6_addr[2] = a1 >> 8;		\
	a.sockaddr.in6.sin6_addr.s6_addr[3] = a1 & 0xFF;	\
	a.sockaddr.in6.sin6_addr.s6_addr[4] = a2 >> 8;		\
	a.sockaddr.in6.sin6_addr.s6_addr[5] = a2 & 0xFF;	\
	a.sockaddr.in6.sin6_addr.s6_addr[6] = a3 >> 8;		\
	a.sockaddr.in6.sin6_addr.s6_addr[7] = a3 & 0xFF;	\
	a.sockaddr.in6.sin6_addr.s6_addr[8] = a4 >> 8;		\
	a.sockaddr.in6.sin6_addr.s6_addr[9] = a4 & 0xFF;	\
	a.sockaddr.in6.sin6_addr.s6_addr[10] = a5 >> 8;		\
	a.sockaddr.in6.sin6_addr.s6_addr[11] = a5 & 0xFF;	\
	a.sockaddr.in6.sin6_addr.s6_addr[12] = a6 >> 8;		\
	a.sockaddr.in6.sin6_addr.s6_addr[13] = a6 & 0xFF;	\
	a.sockaddr.in6.sin6_addr.s6_addr[14] = a7 >> 8;		\
	a.sockaddr.in6.sin6_addr.s6_addr[15] = a7 & 0xFF;

static OFString *module = @"Socket";

@implementation TestsAppDelegate (SocketTests)
- (void)socketTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSocketAddress addr;

	TEST(@"Parsing an IPv4",
	    R(addr = OFSocketAddressParseIP(@"127.0.0.1", 1234)) &&
	    OFFromBigEndian32(addr.sockaddr.in.sin_addr.s_addr) == 0x7F000001 &&
	    OFFromBigEndian16(addr.sockaddr.in.sin_port) == 1234)

	EXPECT_EXCEPTION(@"Refusing invalid IPv4 #1", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"127.0.0.0.1", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv4 #2", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"127.0.0.256", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv4 #3", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"127.0.0. 1", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv4 #4", OFInvalidFormatException,
	    OFSocketAddressParseIP(@" 127.0.0.1", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv4 #5", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"127.0.a.1", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv4 #6", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"127.0..1", 1234))

	TEST(@"Port of an IPv4 address", OFSocketAddressPort(&addr) == 1234)

	TEST(@"Converting an IPv4 to a string",
	    [OFSocketAddressString(&addr) isEqual: @"127.0.0.1"])

	TEST(@"Parsing an IPv6 #1",
	    R(addr = OFSocketAddressParseIP(
	    @"1122:3344:5566:7788:99aa:bbCc:ddee:ff00", 1234)) &&
	    COMPARE_V6(addr,
	    0x1122, 0x3344, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0xDDEE, 0xFF00) &&
	    OFFromBigEndian16(addr.sockaddr.in6.sin6_port) == 1234)

	TEST(@"Parsing an IPv6 #2",
	    R(addr = OFSocketAddressParseIP(@"::", 1234)) &&
	    COMPARE_V6(addr, 0, 0, 0, 0, 0, 0, 0, 0) &&
	    OFFromBigEndian16(addr.sockaddr.in6.sin6_port) == 1234)

	TEST(@"Parsing an IPv6 #3",
	    R(addr = OFSocketAddressParseIP(@"aaAa::bBbb", 1234)) &&
	    COMPARE_V6(addr, 0xAAAA, 0, 0, 0, 0, 0, 0, 0xBBBB) &&
	    OFFromBigEndian16(addr.sockaddr.in6.sin6_port) == 1234)

	TEST(@"Parsing an IPv6 #4",
	    R(addr = OFSocketAddressParseIP(@"aaAa::", 1234)) &&
	    COMPARE_V6(addr, 0xAAAA, 0, 0, 0, 0, 0, 0, 0) &&
	    OFFromBigEndian16(addr.sockaddr.in6.sin6_port) == 1234)

	TEST(@"Parsing an IPv6 #5",
	    R(addr = OFSocketAddressParseIP(@"::aaAa", 1234)) &&
	    COMPARE_V6(addr, 0, 0, 0, 0, 0, 0, 0, 0xAAAA) &&
	    OFFromBigEndian16(addr.sockaddr.in6.sin6_port) == 1234)

	EXPECT_EXCEPTION(@"Refusing invalid IPv6 #1", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"1:::2", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv6 #2", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"1: ::2", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv6 #3", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"1:: :2", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv6 #4", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"1::2::3", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv6 #5", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"10000::1", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv6 #6", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"::10000", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv6 #7", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"::1::", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv6 #8", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"1:2:3:4:5:6:7:", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv6 #9", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"1:2:3:4:5:6:7::", 1234))

	EXPECT_EXCEPTION(@"Refusing invalid IPv6 #10", OFInvalidFormatException,
	    OFSocketAddressParseIP(@"1:2", 1234))

	TEST(@"Port of an IPv6 address", OFSocketAddressPort(&addr) == 1234)

	SET_V6(addr, 0, 0, 0, 0, 0, 0, 0, 0)
	TEST(@"Converting an IPv6 to a string #1",
	    [OFSocketAddressString(&addr) isEqual: @"::"])

	SET_V6(addr, 0, 0, 0, 0, 0, 0, 0, 1)
	TEST(@"Converting an IPv6 to a string #2",
	    [OFSocketAddressString(&addr) isEqual: @"::1"])

	SET_V6(addr, 1, 0, 0, 0, 0, 0, 0, 0)
	TEST(@"Converting an IPv6 to a string #3",
	    [OFSocketAddressString(&addr) isEqual: @"1::"])

	SET_V6(addr,
	    0x1122, 0x3344, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0xDDEE, 0xFF00)
	TEST(@"Converting an IPv6 to a string #4",
	    [OFSocketAddressString(&addr)
	    isEqual: @"1122:3344:5566:7788:99aa:bbcc:ddee:ff00"])

	SET_V6(addr, 0x1122, 0x3344, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0xDDEE, 0)
	TEST(@"Converting an IPv6 to a string #5",
	    [OFSocketAddressString(&addr)
	    isEqual: @"1122:3344:5566:7788:99aa:bbcc:ddee:0"])

	SET_V6(addr, 0x1122, 0x3344, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0, 0)
	TEST(@"Converting an IPv6 to a string #6",
	    [OFSocketAddressString(&addr)
	    isEqual: @"1122:3344:5566:7788:99aa:bbcc::"])

	SET_V6(addr, 0, 0x3344, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0xDDEE, 0xFF00)
	TEST(@"Converting an IPv6 to a string #7",
	    [OFSocketAddressString(&addr)
	    isEqual: @"0:3344:5566:7788:99aa:bbcc:ddee:ff00"])

	SET_V6(addr, 0, 0, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0xDDEE, 0xFF00)
	TEST(@"Converting an IPv6 to a string #8",
	    [OFSocketAddressString(&addr)
	    isEqual: @"::5566:7788:99aa:bbcc:ddee:ff00"])

	SET_V6(addr, 0, 0, 0x5566, 0, 0, 0, 0xDDEE, 0xFF00)
	TEST(@"Converting an IPv6 to a string #9",
	    [OFSocketAddressString(&addr) isEqual: @"0:0:5566::ddee:ff00"])

	SET_V6(addr, 0, 0, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0, 0)
	TEST(@"Converting an IPv6 to a string #10",
	    [OFSocketAddressString(&addr)
	    isEqual: @"::5566:7788:99aa:bbcc:0:0"])

	objc_autoreleasePoolPop(pool);
}
@end
