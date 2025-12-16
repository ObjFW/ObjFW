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

#include "config.h"

#import "OFImageFormatHandler.h"
#import "OFBMPImageFormatHandler.h"
#import "OFDictionary.h"
#import "OFQOIImageFormatHandler.h"

#import "OFNotImplementedException.h"

@implementation OFImageFormatHandler
@synthesize imageFormat = _imageFormat;

static OFMutableDictionary OF_GENERIC(OFImageFormat, OFImageFormatHandler *)
    *handlers;

+ (void)initialize
{
	if (self != [OFImageFormatHandler class])
		return;

	handlers = [[OFMutableDictionary alloc] init];

	[self registerClass: [OFBMPImageFormatHandler class]
	     forImageFormat: OFImageFormatBMP];
	[self registerClass: [OFQOIImageFormatHandler class]
	     forImageFormat: OFImageFormatQOI];
}

+ (bool)registerClass: (Class)class forImageFormat: (OFImageFormat)imageFormat
{
	@synchronized (handlers) {
		OFImageFormatHandler *handler;

		if ([handlers objectForKey: imageFormat] != nil)
			return false;

		handler = [[class alloc] initWithImageFormat: imageFormat];
		@try {
			[handlers setObject: handler forKey: imageFormat];
		} @finally {
			objc_release(handler);
		}
	}

	return true;
}

+ (OFImageFormatHandler *)handlerForImageFormat: (OFImageFormat)imageFormat
{
	OF_KINDOF(OFImageFormatHandler *) handler;

	@synchronized (handlers) {
		handler = [handlers objectForKey: imageFormat];
	}

	if (handler == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return handler;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithImageFormat: (OFImageFormat)imageFormat
{
	self = [super init];

	@try {
		_imageFormat = [imageFormat copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_imageFormat);

	[super dealloc];
}

- (OFImage *)readImageFromStream: (OFSeekableStream *)stream
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)writeImage: (OFImage *)image
	  toStream: (OFSeekableStream *)stream
	   options: (OFDictionary OF_GENERIC(OFString *, id) *)options
{
	OF_UNRECOGNIZED_SELECTOR
}
@end
