/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFArray.h"

extern int _OFXMLElement_reference;

@interface OFXMLElement: OFObject
{
	OFString *name;
	OFDictionary *attrs;
	OFString *stringval;
	OFArray *children;
}

+ elementWithName: (OFString*)name;
+ elementWithName: (OFString*)name
   andStringValue: (OFString*)stringval;
- initWithName: (OFString*)name;
-   initWithName: (OFString*)name
  andStringValue: (OFString*)stringval;
- (OFString*)string;
- addAttributeWithName: (OFString*)name
	      andValue: (OFString*)value;
- addChild: (OFXMLElement*)child;
@end

@interface OFString (OFXMLEscaping)
- stringByXMLEscaping;
@end
