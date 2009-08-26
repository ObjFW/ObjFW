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

extern int _OFXMLParser_reference;

@class OFXMLParser;

@protocol OFXMLParserDelegate
-     (void)xmlParser: (OFXMLParser*)parser
  didStartTagWithName: (OFString*)name
	       prefix: (OFString*)prefix
	    namespace: (OFString*)ns
	   attributes: (OFArray*)attrs;
-   (void)xmlParser: (OFXMLParser*)parser
  didEndTagWithName: (OFString*)name
	     prefix: (OFString*)prefix
	  namespace: (OFString*)ns;
- (void)xmlParser: (OFXMLParser*)parser
      foundString: (OFString*)string;
- (void)xmlParser: (OFXMLParser*)parser
     foundComment: (OFString*)comment;
-    (OFString*)xmlParser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity;
@end

@protocol OFXMLUnescapingDelegate
- (OFString*)foundUnknownEntityNamed: (OFString*)entitiy;
@end

@interface OFXMLParser: OFObject <OFXMLUnescapingDelegate>
{
	OFObject <OFXMLParserDelegate> *delegate;
	enum {
		OF_XMLPARSER_OUTSIDE_TAG,
		OF_XMLPARSER_TAG_OPENED,
		OF_XMLPARSER_IN_TAG_NAME,
		OF_XMLPARSER_IN_CLOSE_TAG_NAME,
		OF_XMLPARSER_IN_TAG,
		OF_XMLPARSER_IN_ATTR_NAME,
		OF_XMLPARSER_EXPECT_DELIM,
		OF_XMLPARSER_IN_ATTR_VALUE,
		OF_XMLPARSER_EXPECT_CLOSE,
		OF_XMLPARSER_EXPECT_SPACE_OR_CLOSE,
		OF_XMLPARSER_IN_COMMENT_1,
		OF_XMLPARSER_IN_COMMENT_2,
		OF_XMLPARSER_IN_COMMENT_3,
		OF_XMLPARSER_IN_COMMENT_4
	} state;
	OFString *cache;
	OFString *name;
	OFString *prefix;
	OFString *ns;
	OFArray *attrs;
	OFString *attr_name;
	OFString *attr_prefix;
	char delim;
	OFArray *previous;
}

+ xmlParser;
- (id)delegate;
- setDelegate: (OFObject <OFXMLParserDelegate>*)delegate;
- parseBuffer: (const char*)buf
     withSize: (size_t)size;
@end

@interface OFString (OFXMLUnescaping)
- stringByXMLUnescaping;
- stringByXMLUnescapingWithHandler: (OFObject <OFXMLUnescapingDelegate>*)h;
@end

@interface OFObject (OFXMLParserDelegate) <OFXMLParserDelegate>
@end
