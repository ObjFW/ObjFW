/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#import "ObjFWTest.h"

@interface OFSocketTests: OTTestCase
@end

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

@implementation OFSocketTests
- (void)testParseIPv4
{
	OFSocketAddress address = OFSocketAddressParseIP(@"127.0.0.1", 1234);

	OTAssertEqual(OFFromBigEndian32(address.sockaddr.in.sin_addr.s_addr),
	    0x7F000001);
	OTAssertEqual(OFFromBigEndian16(address.sockaddr.in.sin_port), 1234);
}

- (void)testParseRejectsInvalidIPv4
{
	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"127.0.0.0.1", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"127.0.0.256", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"127.0.0. 1", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@" 127.0.0.1", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"127.0.a.1", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"127.0..1", 1234),
	    OFInvalidFormatException);
}

- (void)testPortForIPv4
{
	OFSocketAddress address = OFSocketAddressParseIP(@"127.0.0.1", 1234);

	OTAssertEqual(OFSocketAddressIPPort(&address), 1234);
}

- (void)testStringForIPv4
{
	OFSocketAddress address = OFSocketAddressParseIP(@"127.0.0.1", 1234);

	OTAssertEqualObjects(OFSocketAddressString(&address), @"127.0.0.1");
}

- (void)testParseIPv6
{
	OFSocketAddress address;

	address = OFSocketAddressParseIP(
	    @"1122:3344:5566:7788:99aa:bbCc:ddee:ff00", 1234);
	OTAssert(COMPARE_V6(address,
	    0x1122, 0x3344, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0xDDEE, 0xFF00));
	OTAssertEqual(OFFromBigEndian16(address.sockaddr.in6.sin6_port), 1234);

	address = OFSocketAddressParseIP(@"::", 1234);
	OTAssert(COMPARE_V6(address, 0, 0, 0, 0, 0, 0, 0, 0));
	OTAssertEqual(OFFromBigEndian16(address.sockaddr.in6.sin6_port), 1234);

	address = OFSocketAddressParseIP(@"aaAa::bBbb", 1234);
	OTAssert(COMPARE_V6(address, 0xAAAA, 0, 0, 0, 0, 0, 0, 0xBBBB));
	OTAssertEqual(OFFromBigEndian16(address.sockaddr.in6.sin6_port), 1234);

	address = OFSocketAddressParseIP(@"aaAa::", 1234);
	OTAssert(COMPARE_V6(address, 0xAAAA, 0, 0, 0, 0, 0, 0, 0));
	OTAssertEqual(OFFromBigEndian16(address.sockaddr.in6.sin6_port), 1234);

	address = OFSocketAddressParseIP(@"::aaAa", 1234);
	OTAssert(COMPARE_V6(address, 0, 0, 0, 0, 0, 0, 0, 0xAAAA));
	OTAssertEqual(OFFromBigEndian16(address.sockaddr.in6.sin6_port), 1234);

	address = OFSocketAddressParseIP(@"fd00::1%123", 1234);
	OTAssert(COMPARE_V6(address, 0xFD00, 0, 0, 0, 0, 0, 0, 1));
	OTAssertEqual(OFFromBigEndian16(address.sockaddr.in6.sin6_port), 1234);
	OTAssertEqual(address.sockaddr.in6.sin6_scope_id, 123);

	address = OFSocketAddressParseIP(@"::ffff:127.0.0.1", 1234);
	OTAssert(COMPARE_V6(address, 0, 0, 0, 0, 0, 0xFFFF, 0x7F00, 1));
	OTAssertEqual(OFFromBigEndian16(address.sockaddr.in6.sin6_port), 1234);

	address = OFSocketAddressParseIP(@"64:ff9b::127.0.0.1", 1234);
	OTAssert(COMPARE_V6(address, 0x64, 0xFF9B, 0, 0, 0, 0, 0x7F00, 1));
	OTAssertEqual(OFFromBigEndian16(address.sockaddr.in6.sin6_port), 1234);
}

- (void)testParseRejectsInvalidIPv6
{
	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"1:::2", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"1: ::2", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"1:: :2", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"1::2::3", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"10000::1", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"::10000", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"::1::", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"1:2:3:4:5:6:7:", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"1:2:3:4:5:6:7::", 1234),
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(OFSocketAddressParseIP(@"1:2", 1234),
	    OFInvalidFormatException);
}

- (void)testPortForIPv6
{
	OFSocketAddress address = OFSocketAddressParseIP(@"::", 1234);

	OTAssertEqual(OFSocketAddressIPPort(&address), 1234);
}

- (void)testStringForIPv6
{
	OFSocketAddress address = OFSocketAddressParseIP(@"::", 1234);

	OTAssertEqualObjects(OFSocketAddressString(&address), @"::");

	SET_V6(address, 0, 0, 0, 0, 0, 0, 0, 1)
	OTAssertEqualObjects(OFSocketAddressString(&address), @"::1");

	SET_V6(address, 1, 0, 0, 0, 0, 0, 0, 0)
	OTAssertEqualObjects(OFSocketAddressString(&address), @"1::");

	SET_V6(address,
	    0x1122, 0x3344, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0xDDEE, 0xFF00)
	OTAssertEqualObjects(OFSocketAddressString(&address),
	    @"1122:3344:5566:7788:99aa:bbcc:ddee:ff00");

	SET_V6(address,
	    0x1122, 0x3344, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0xDDEE, 0)
	OTAssertEqualObjects(OFSocketAddressString(&address),
	    @"1122:3344:5566:7788:99aa:bbcc:ddee:0");

	SET_V6(address, 0x1122, 0x3344, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0, 0)
	OTAssertEqualObjects(OFSocketAddressString(&address),
	    @"1122:3344:5566:7788:99aa:bbcc::");

	SET_V6(address,
	    0, 0x3344, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0xDDEE, 0xFF00)
	OTAssertEqualObjects(OFSocketAddressString(&address),
	    @"0:3344:5566:7788:99aa:bbcc:ddee:ff00");

	SET_V6(address, 0, 0, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0xDDEE, 0xFF00)
	OTAssertEqualObjects(OFSocketAddressString(&address),
	    @"::5566:7788:99aa:bbcc:ddee:ff00");

	SET_V6(address, 0, 0, 0x5566, 0, 0, 0, 0xDDEE, 0xFF00)
	OTAssertEqualObjects(OFSocketAddressString(&address),
	    @"0:0:5566::ddee:ff00");

	SET_V6(address, 0, 0, 0x5566, 0x7788, 0x99AA, 0xBBCC, 0, 0)
	OTAssertEqualObjects(OFSocketAddressString(&address),
	    @"::5566:7788:99aa:bbcc:0:0");

	address.sockaddr.in6.sin6_scope_id = 123;
	OTAssertEqualObjects(OFSocketAddressString(&address),
	    @"::5566:7788:99aa:bbcc:0:0%123");
}
@end
