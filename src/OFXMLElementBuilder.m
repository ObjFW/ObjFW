/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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
#import "OFXMLAttribute.h"
#import "OFXMLCharacters.h"
#import "OFXMLCDATA.h"
#import "OFXMLComment.h"
#import "OFXMLProcessingInstructions.h"
#import "OFXMLParser.h"
#import "OFMutableArray.h"

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

	[super dealloc];
}

- (id <OFXMLElementBuilderDelegate>)delegate
{
	return delegate;
}

- (void)setDelegate: (id <OFXMLElementBuilderDelegate>)delegate_
{
	delegate = delegate_;
}

-		 (void)parser: (OFXMLParser*)parser
  foundProcessingInstructions: (OFString*)pi
{
	OFXMLProcessingInstructions *node = [OFXMLProcessingInstructions
	    processingInstructionsWithString: pi];
	OFXMLElement *parent = [stack lastObject];

	if (parent != nil)
		[parent addChild: node];
	else
		[delegate   elementBuilder: self
		    didBuildParentlessNode: node];
}

-    (void)parser: (OFXMLParser*)parser
  didStartElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attributes
{
	OFXMLElement *element;
	OFXMLAttribute **objects;
	size_t i, count;

	element = [OFXMLElement elementWithName: name
				      namespace: ns];

	objects = [attributes objects];
	count = [attributes count];

	for (i = 0; i < count; i++) {
		if ([objects[i] namespace] == nil &&
		    [[objects[i] name] isEqual: @"xmlns"])
			continue;

		if ([[objects[i] namespace]
		    isEqual: @"http://www.w3.org/2000/xmlns/"])
			[element setPrefix: [objects[i] name]
			      forNamespace: [objects[i] stringValue]];

		[element addAttribute: objects[i]];
	}

	[[stack lastObject] addChild: element];
	[stack addObject: element];
}

-  (void)parser: (OFXMLParser*)parser
  didEndElement: (OFString*)name
     withPrefix: (OFString*)prefix
      namespace: (OFString*)ns
{
	switch ([stack count]) {
	case 0:
		[delegate elementBuilder: self
		    didNotExpectCloseTag: name
			      withPrefix: prefix
			       namespace: ns];
		return;
	case 1:
		[delegate elementBuilder: self
			 didBuildElement: [stack firstObject]];
		break;
	}

	[stack removeLastObject];
}

-    (void)parser: (OFXMLParser*)parser
  foundCharacters: (OFString*)characters
{
	OFXMLCharacters *node;
	OFXMLElement *parent;

	node = [OFXMLCharacters charactersWithString: characters];
	parent = [stack lastObject];

	if (parent != nil)
		[parent addChild: node];
	else
		[delegate   elementBuilder: self
		    didBuildParentlessNode: node];
}

- (void)parser: (OFXMLParser*)parser
    foundCDATA: (OFString*)CDATA
{
	OFXMLCDATA *node = [OFXMLCDATA CDATAWithString: CDATA];
	OFXMLElement *parent = [stack lastObject];

	if (parent != nil)
		[parent addChild: node];
	else
		[delegate   elementBuilder: self
		    didBuildParentlessNode: node];
}

- (void)parser: (OFXMLParser*)parser
  foundComment: (OFString*)comment
{
	OFXMLComment *node = [OFXMLComment commentWithString: comment];
	OFXMLElement *parent = [stack lastObject];

	if (parent != nil)
		[parent addChild: node];
	else
		[delegate   elementBuilder: self
		    didBuildParentlessNode: node];
}

-	(OFString*)parser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity
{
	return [delegate elementBuilder: self
		foundUnknownEntityNamed: entity];
}
@end

@implementation OFObject (OFXMLElementBuilderDelegate)
- (void)elementBuilder: (OFXMLElementBuilder*)builder
       didBuildElement: (OFXMLElement*)elem
{
}

-   (void)elementBuilder: (OFXMLElementBuilder*)builder
  didBuildParentlessNode: (OFXMLNode*)node
{
}

- (void)elementBuilder: (OFXMLElementBuilder*)builder
  didNotExpectCloseTag: (OFString*)name
	    withPrefix: (OFString*)prefix
	     namespace: (OFString*)ns
{
	@throw [OFMalformedXMLException exceptionWithClass: [builder class]];
}

- (OFString*)elementBuilder: (OFXMLElementBuilder*)builder
    foundUnknownEntityNamed: (OFString*)entity
{
	return nil;
}
@end
