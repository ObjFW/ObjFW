/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import <stdint.h>

#import "OFObject.h"

@interface OFMD5Hash: OFObject
{
	uint32_t buf[4];
	uint32_t bits[2];
	uint8_t	 in[64];
}

- init;
- (void)updateWithBuffer: (const uint8_t*)buf
		  ofSize: (size_t)size;
- (uint8_t*)digest;
@end
