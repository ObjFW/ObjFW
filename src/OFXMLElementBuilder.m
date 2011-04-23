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

#define OF_XML_ELEMENT_BUILDER_M

#import "OFXMLElementBuilder.h"
#import "OFXMLElement.h"
#import "OFXMLParser.h"
#import "OFMutableArray.h"
#import "OFAutoreleasePool.h"

#import "OFMalformedXMLException.h"

#import "macros.h"

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
	OF_GETTER(delegate, YES)
}

- (void)setDelegate: (id <OFXMLElementBuilderDelegate>)delegate_
{
	OF_SETTER(delegate, delegate_, YES, NO)
}

-    (void)parser: (OFXMLParser*)parser
  didStartElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attributes
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *element;
	OFXMLAttribute **cArray;
	size_t i, count;
	IMP addAttribute;

	element = [OFXMLElement elementWithName: name
				      namespace: ns];

	cArray = [attributes cArray];
	count = [attributes count];
	addAttribute = [element methodForSelector: @selector(addAttribute:)];

	for (i = 0; i < count; i++) {
		if ([cArray[i] namespace] == nil &&
		    [[cArray[i] name] isEqual: @"xmlns"])
			continue;

		if ([[cArray[i] namespace]
		    isEqual: @"http://www.w3.org/2000/xmlns/"])
			[element setPrefix: [cArray[i] name]
			      forNamespace: [cArray[i] stringValue]];

		addAttribute(element, @selector(addAttribute:), cArray[i]);
	}

	[[stack lastObject] addChild: element];
	[stack addObject: element];

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
  foundCharacters: (OFString*)characters
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *element =
	    [OFXMLElement elementWithCharacters: characters];

	if ([stack count] == 0)
		[delegate elementBuilder: self
			 didBuildElement: element];
	else
		[[stack lastObject] addChild: element];

	[pool release];
}

- (void)parser: (OFXMLParser*)parser
    foundCDATA: (OFString*)CDATA
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *element = [OFXMLElement elementWithCDATA: CDATA];

	if ([stack count] == 0)
		[delegate elementBuilder: self
			 didBuildElement: element];
	else
		[[stack lastObject] addChild: element];

	[pool release];
}

- (void)parser: (OFXMLParser*)parser
  foundComment: (OFString*)comment
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *element = [OFXMLElement elementWithComment: comment];

	if ([stack count] == 0)
		[delegate elementBuilder: self
			 didBuildElement: element];
	else
		[[stack lastObject] addChild: element];

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
	@throw [OFMalformedXMLException newWithClass: [builder class]
					      parser: nil];
}
@end
