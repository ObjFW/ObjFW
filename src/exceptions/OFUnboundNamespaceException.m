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

#import "OFUnboundNamespaceException.h"
#import "OFString.h"

#import "OFNotImplementedException.h"

@implementation OFUnboundNamespaceException
+ exceptionWithClass: (Class)class_
	   namespace: (OFString*)ns
{
	return [[[self alloc] initWithClass: class_
				  namespace: ns] autorelease];
}

+ exceptionWithClass: (Class)class_
	      prefix: (OFString*)prefix
{
	return [[[self alloc] initWithClass: class_
				     prefix: prefix] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
      namespace: (OFString*)ns_
{
	self = [super initWithClass: class_];

	@try {
		ns = [ns_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithClass: (Class)class_
	 prefix: (OFString*)prefix_
{
	self = [super initWithClass: class_];

	@try {
		prefix = [prefix_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[ns release];
	[prefix release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	if (ns != nil)
		description = [[OFString alloc] initWithFormat:
		    @"The namespace %@ is not bound in class %@", ns, inClass];
	else if (prefix != nil)
		description = [[OFString alloc] initWithFormat:
		    @"The prefix %@ is not bound to any namespace in class %@",
		    prefix, inClass];

	return description;
}

- (OFString*)namespace
{
	return ns;
}

- (OFString*)prefix
{
	return prefix;
}
@end
