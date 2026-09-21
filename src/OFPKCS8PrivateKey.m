/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFPKCS8PrivateKey.h"
#import "OFData.h"
#import "OFIRI.h"
#import "OFIRIHandler.h"
#import "OFPEMParser.h"

#import "OFInvalidArgumentException.h"

static void
parsePrivateKeyCallback(OFString *section, OFData *data, void *ctx)
{
	if (![section isEqual: @"PRIVATE KEY"])
                return;

	OFPKCS8PrivateKey **privateKey = ctx;
	*privateKey =
	    [data.valueByParsingDER parsedAs: [OFPKCS8PrivateKey class]];
}

@implementation OFPKCS8PrivateKey
+ (OFPKCS8PrivateKey *)privateKeyFromPEMFileAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();

	OFPKCS8PrivateKey *privateKey = nil;
	OFParsePEM([OFIRIHandler openItemAtIRI: IRI mode: @"r"],
	    parsePrivateKeyCallback, &privateKey);

	if (privateKey == nil)
		@throw [OFInvalidArgumentException exception];

	objc_retain(privateKey);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(privateKey);
}
@end
