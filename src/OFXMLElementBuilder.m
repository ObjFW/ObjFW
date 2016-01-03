/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#include "config.h"

#import "OFXMLElementBuilder.h"
#import "OFXMLElement.h"
#import "OFXMLAttribute.h"
#import "OFXMLCharacters.h"
#import "OFXMLCDATA.h"
#import "OFXMLComment.h"
#import "OFXMLProcessingInstructions.h"
#import "OFXMLParser.h"
#import "OFArray.h"

#import "OFMalformedXMLException.h"

@implementation OFXMLElementBuilder
+ (instancetype)elementBuilder
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		_stack = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_stack release];

	[super dealloc];
}

- (id <OFXMLElementBuilderDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate: (id <OFXMLElementBuilderDelegate>)delegate
{
	_delegate = delegate;
}

-		 (void)parser: (OFXMLParser*)parser
  foundProcessingInstructions: (OFString*)pi
{
	OFXMLProcessingInstructions *node = [OFXMLProcessingInstructions
	    processingInstructionsWithString: pi];
	OFXMLElement *parent = [_stack lastObject];

	if (parent != nil)
		[parent addChild: node];
	else if ([_delegate respondsToSelector:
	    @selector(elementBuilder:didBuildParentlessNode:)])
		[_delegate elementBuilder: self
		   didBuildParentlessNode: node];
}

-    (void)parser: (OFXMLParser*)parser
  didStartElement: (OFString*)name
	   prefix: (OFString*)prefix
	namespace: (OFString*)namespace
       attributes: (OFArray*)attributes
{
	OFXMLElement *element;
	OFXMLAttribute *const *objects;
	size_t i, count;

	element = [OFXMLElement elementWithName: name
				      namespace: namespace];

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

	[[_stack lastObject] addChild: element];
	[_stack addObject: element];
}

-  (void)parser: (OFXMLParser*)parser
  didEndElement: (OFString*)name
	 prefix: (OFString*)prefix
      namespace: (OFString*)namespace
{
	switch ([_stack count]) {
	case 0:
		if ([_delegate respondsToSelector: @selector(elementBuilder:
		    didNotExpectCloseTag:prefix:namespace:)])
			[_delegate elementBuilder: self
			     didNotExpectCloseTag: name
					   prefix: prefix
					namespace: namespace];
		else
			@throw [OFMalformedXMLException exception];

		return;
	case 1:
		[_delegate elementBuilder: self
			  didBuildElement: [_stack firstObject]];
		break;
	}

	[_stack removeLastObject];
}

-    (void)parser: (OFXMLParser*)parser
  foundCharacters: (OFString*)characters
{
	OFXMLCharacters *node;
	OFXMLElement *parent;

	node = [OFXMLCharacters charactersWithString: characters];
	parent = [_stack lastObject];

	if (parent != nil)
		[parent addChild: node];
	else if ([_delegate respondsToSelector:
	    @selector(elementBuilder:didBuildParentlessNode:)])
		[_delegate  elementBuilder: self
		    didBuildParentlessNode: node];
}

- (void)parser: (OFXMLParser*)parser
    foundCDATA: (OFString*)CDATA
{
	OFXMLCDATA *node = [OFXMLCDATA CDATAWithString: CDATA];
	OFXMLElement *parent = [_stack lastObject];

	if (parent != nil)
		[parent addChild: node];
	else if ([_delegate respondsToSelector:
	    @selector(elementBuilder:didBuildParentlessNode:)])
		[_delegate elementBuilder: self
		   didBuildParentlessNode: node];
}

- (void)parser: (OFXMLParser*)parser
  foundComment: (OFString*)comment
{
	OFXMLComment *node = [OFXMLComment commentWithString: comment];
	OFXMLElement *parent = [_stack lastObject];

	if (parent != nil)
		[parent addChild: node];
	else if ([_delegate respondsToSelector:
	    @selector(elementBuilder:didBuildParentlessNode:)])
		[_delegate elementBuilder: self
		   didBuildParentlessNode: node];
}

-	(OFString*)parser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity
{
	if ([_delegate respondsToSelector:
	    @selector(elementBuilder:foundUnknownEntityNamed:)])
		return [_delegate elementBuilder: self
			 foundUnknownEntityNamed: entity];

	return nil;
}
@end
