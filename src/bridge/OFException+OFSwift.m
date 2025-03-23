/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFException+OFSwift.h"

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
