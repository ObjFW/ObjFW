/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#include "config.h"

#import "OFAddressTranslationFailedException.h"
#import "OFString.h"

#import "common.h"

@implementation OFAddressTranslationFailedException
+ newWithClass: (Class)class_
	  host: (OFString*)host
{
	return [[self alloc] initWithClass: class_
				      host: host];
}

- initWithClass: (Class)class_
{
	self = [super initWithClass: class_];

	errNo = GET_AT_ERRNO;

	return self;
}

- initWithClass: (Class)class_
	   host: (OFString*)host_
{
	self = [super initWithClass: class_];

	@try {
		host  = [host_ copy];
		errNo = GET_AT_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[host release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	if (host != nil)
		description = [[OFString alloc] initWithFormat:
		    @"The host %@ could not be translated to an address in "
		    @"class %@. This means that either the host was not found, "
		    @"there was a problem with the name server, there was a "
		    @"problem with your network connection or you specified an "
		    @"invalid host. " ERRFMT, host, inClass, AT_ERRPARAM];
	else
		description = [[OFString alloc] initWithFormat:
		    @"An address translation failed in class %@! " ERRFMT,
		    inClass, AT_ERRPARAM];

	return description;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)host
{
	return host;
}
@end
