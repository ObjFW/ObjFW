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

#import "OFXMLElementBuilder.h"
#import "OFXMLElement.h"
#import "OFXMLParser.h"
#import "OFMutableArray.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

@implementation OFXMLElementBuilder
+ elementBuilder
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		stack = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[stack release];
	[(id)delegate release];

	[super dealloc];
}

- (id <OFXMLElementBuilderDelegate>)delegate
{
	return [[(id)delegate retain] autorelease];
}

- (void)setDelegate: (id <OFXMLElementBuilderDelegate>)delegate_
{
	[(id)delegate_ retain];
	[(id)delegate release];
	delegate = delegate_;
}

-    (void)parser: (OFXMLParser*)parser
  didStartElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attrs
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *elem;
	OFXMLAttribute **attrs_c;
	size_t i, attrs_cnt;
	IMP add_attr;

	elem = [OFXMLElement elementWithName: name
				   namespace: ns];

	attrs_c = [attrs cArray];
	attrs_cnt = [attrs count];
	add_attr = [elem methodForSelector: @selector(addAttribute:)];

	for (i = 0; i < attrs_cnt; i++) {
		if ([attrs_c[i] namespace] == nil &&
		    [[attrs_c[i] name] isEqual: @"xmlns"])
			continue;

		if ([[attrs_c[i] namespace]
		    isEqual: @"http://www.w3.org/2000/xmlns/"])
			[elem setPrefix: [attrs_c[i] name]
			   forNamespace: [attrs_c[i] stringValue]];

		add_attr(elem, @selector(addAttribute:), attrs_c[i]);
	}

	[[stack lastObject] addChild: elem];
	[stack addObject: elem];

	[pool release];
}

-  (void)parser: (OFXMLParser*)parser
  didEndElement: (OFString*)name
     withPrefix: (OFString*)prefix
      namespace: (OFString*)ns
{
	if ([stack count] == 0) {
		[delegate elementBuilder: self
		    didNotExpectCloseTag: name
			      withPrefix: prefix
			       namespace: ns];
		return;
	}

	if ([stack count] == 1)
		[delegate elementBuilder: self
			 didBuildElement: [stack firstObject]];

	[stack removeNObjects: 1];
}

-    (void)parser: (OFXMLParser*)parser
  foundCharacters: (OFString*)str
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *elem = [OFXMLElement elementWithCharacters: str];

	if ([stack count] == 0)
		[delegate elementBuilder: self
			 didBuildElement: elem];
	else
		[[stack lastObject] addChild: elem];

	[pool release];
}

- (void)parser: (OFXMLParser*)parser
    foundCDATA: (OFString*)cdata
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *elem = [OFXMLElement elementWithCDATA: cdata];

	if ([stack count] == 0)
		[delegate elementBuilder: self
			 didBuildElement: elem];
	else
		[[stack lastObject] addChild: elem];

	[pool release];
}

- (void)parser: (OFXMLParser*)parser
  foundComment: (OFString*)comment
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *elem = [OFXMLElement elementWithComment: comment];

	if ([stack count] == 0)
		[delegate elementBuilder: self
			 didBuildElement: elem];
	else
		[[stack lastObject] addChild: elem];

	[pool release];
}
@end

@implementation OFObject (OFXMLElementBuilderDelegate)
- (void)elementBuilder: (OFXMLElementBuilder*)builder
       didBuildElement: (OFXMLElement*)elem
{
}

- (void)elementBuilder: (OFXMLElementBuilder*)builder
  didNotExpectCloseTag: (OFString*)name
	    withPrefix: (OFString*)prefix
	     namespace: (OFString*)ns
{
	@throw [OFMalformedXMLException newWithClass: [builder class]];
}
@end
