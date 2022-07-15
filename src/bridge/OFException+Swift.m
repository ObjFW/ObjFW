/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFException+Swift.h"

@implementation OFException (NSError)
#ifdef OF_HAVE_BLOCKS
+ (void)try: (void (^)(void))try
      catch: (void (^)(OF_KINDOF(OFException *e)))catch
{
	@try {
		try();
	} @catch (OFException *e) {
		catch(e);
	}
}

+ (void)try: (void (^)(void))try
    finally: (void (^)(void))finally
{
	@try {
		try();
	} @finally {
		finally();
	}
}

+ (void)try: (void (^)(void))try
      catch: (void (^)(OF_KINDOF(OFException *e)))catch
    finally: (void (^)(void))finally
{
	@try {
		try();
	} @catch (OFException *e) {
		catch(e);
	} @finally {
		finally();
	}
}
#endif

- (void)throw
{
	@throw self;
}
@end
