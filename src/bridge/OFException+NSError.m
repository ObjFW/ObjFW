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

#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>

#import "OFString.h"

#import "OFException+NSError.h"

@implementation OFException (NSError)
#ifdef OF_HAVE_BLOCKS
+ (BOOL)tryBlock: (void (^)(void))block
	   error: (NSError **)error
{
	@try {
		block();
		return YES;
	} @catch (OFException *e) {
		if (error != NULL) {
			NSDictionary *userInfo = [NSDictionary
			    dictionaryWithObject: e
					  forKey: @"exception"];
			*error = [NSError errorWithDomain: @"OFException"
						     code: 0
						 userInfo: userInfo];
		}

		return NO;
	}
}
#endif
@end
