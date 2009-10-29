/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFString.h"

@interface UpperLowerGenerator: OFObject
{
	of_unichar_t upper[0x110000];
	of_unichar_t lower[0x110000];
}

- (void)fillTablesFromFile: (OFString*)file;
- (size_t)writeTable: (of_unichar_t*)table
	    withName: (OFString*)name
	      toFile: (OFString*)file;
- (size_t)writeUpperTableToFile: (OFString*)file;
- (size_t)writeLowerTableToFile: (OFString*)file;
- (void)writeHeaderToFile: (OFString*)file
       withUpperTableSize: (size_t)upper_size
	   lowerTableSize: (size_t)lower_size;
@end
