/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFXMLElementBuilder.h"
#import "OFArray.h"
#import "OFXMLAttribute.h"
#import "OFXMLCDATA.h"
#import "OFXMLCharacters.h"
#import "OFXMLComment.h"
#import "OFXMLElement.h"
#import "OFXMLParser.h"
#import "OFXMLProcessingInstruction.h"

#import "OFMalformedXMLException.h"

@implementation OFXMLElementBuilder
@synthesize delegate = _delegate;

+ (instancetype)builder
{
	return objc_autoreleaseReturnValue([[self alloc] init]);
}

- (instancetype)init
{
	self = [super init];

	@try {
		_stack = [[OFMutableArray alloc] init];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_stack);

	[super dealloc];
}

-			  (void)parser: (OFXMLParser *)parser
  foundProcessingInstructionWithTarget: (OFString *)target
				  text: (OFString *)text
{
	OFXMLProcessingInstruction *node = [OFXMLProcessingInstruction
	    processingInstructionWithTarget: target
				       text: text];
	OFXMLElement *parent = _stack.lastObject;

	if (parent != nil)
		[parent addChild: node];
	else if ([_delegate respondsToSelector:
	    @selector(elementBuilder:didBuildOrphanNode:)])
		[_delegate elementBuilder: self didBuildOrphanNode: node];
}

-    (void)parser: (OFXMLParser *)parser
  didStartElement: (OFString *)name
	   prefix: (OFString *)prefix
	namespace: (OFString *)namespace
       attributes: (OFArray *)attributes
{
	OFXMLElement *element = [OFXMLElement elementWithName: name
						    namespace: namespace];

	for (OFXMLAttribute *attribute in attributes) {
		if (attribute.namespace == nil &&
		    [attribute.name isEqual: @"xmlns"])
			continue;

		if ([attribute.namespace isEqual:
		    @"http://www.w3.org/2000/xmlns/"])
			[element setPrefix: attribute.name
			      forNamespace: attribute.stringValue];

		[element addAttribute: attribute];
	}

	[_stack.lastObject addChild: element];
	[_stack addObject: element];
}

-  (void)parser: (OFXMLParser *)parser
  didEndElement: (OFString *)name
	 prefix: (OFString *)prefix
      namespace: (OFString *)namespace
{
	switch (_stack.count) {
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
			  didBuildElement: _stack.firstObject];
		break;
	}

	[_stack removeLastObject];
}

-    (void)parser: (OFXMLParser *)parser
  foundCharacters: (OFString *)characters
{
	OFXMLCharacters *node;
	OFXMLElement *parent;

	node = [OFXMLCharacters charactersWithString: characters];
	parent = _stack.lastObject;

	if (parent != nil)
		[parent addChild: node];
	else if ([_delegate respondsToSelector:
	    @selector(elementBuilder:didBuildOrphanNode:)])
		[_delegate elementBuilder: self didBuildOrphanNode: node];
}

- (void)parser: (OFXMLParser *)parser
    foundCDATA: (OFString *)CDATA
{
	OFXMLCDATA *node = [OFXMLCDATA CDATAWithString: CDATA];
	OFXMLElement *parent = _stack.lastObject;

	if (parent != nil)
		[parent addChild: node];
	else if ([_delegate respondsToSelector:
	    @selector(elementBuilder:didBuildOrphanNode:)])
		[_delegate elementBuilder: self didBuildOrphanNode: node];
}

- (void)parser: (OFXMLParser *)parser
  foundComment: (OFString *)comment
{
	OFXMLComment *node = [OFXMLComment commentWithText: comment];
	OFXMLElement *parent = _stack.lastObject;

	if (parent != nil)
		[parent addChild: node];
	else if ([_delegate respondsToSelector:
	    @selector(elementBuilder:didBuildOrphanNode:)])
		[_delegate elementBuilder: self didBuildOrphanNode: node];
}

-      (OFString *)parser: (OFXMLParser *)parser
  foundUnknownEntityNamed: (OFString *)entity
{
	if ([_delegate respondsToSelector:
	    @selector(elementBuilder:foundUnknownEntityNamed:)])
		return [_delegate elementBuilder: self
			 foundUnknownEntityNamed: entity];

	return nil;
}
@end
