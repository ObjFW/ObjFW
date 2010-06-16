/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFString.h"
#import "OFXMLAttribute.h"

@class OFXMLParser;
@class OFArray;
@class OFMutableArray;

/**
 * \brief A protocol that needs to be implemented by delegates for OFXMLParser.
 */
@protocol OFXMLParserDelegate
/**
 * This callback is called when the XML parser found the start of a new tag.
 *
 * \param parser The parser which found a new tag
 * \param name The name of the tag which just started
 * \param prefix The prefix of the tag which just started or nil
 * \param ns The namespace of the tag which just started or nil
 * \param attrs The attributes included in the tag which just started or nil
 */
-    (void)parser: (OFXMLParser*)parser
  didStartElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attrs;

/**
 * This callback is called when the XML parser found the end of a tag.
 *
 * \param parser The parser which found the end of a tag
 * \param name The name of the tag which just ended
 * \param prefix The prefix of the tag which just ended or nil
 * \param ns The namespace of the tag which just ended or nil
 */
-  (void)parser: (OFXMLParser*)parser
  didEndElement: (OFString*)name
     withPrefix: (OFString*)prefix
      namespace: (OFString*)ns;

/**
 * This callback is called when the XML parser found characters.
 *
 * In case there are comments or CDATA, it is possible that this callback is
 * called multiple times in a row.
 *
 * \param parser The parser which found a string
 * \param string The string the XML parser found
 */
-    (void)parser: (OFXMLParser*)parser
  foundCharacters: (OFString*)string;

/**
 * This callback is called when the XML parser found CDATA.
 *
 * \param parser The parser which found a string
 * \param string The string the XML parser found
 */
- (void)parser: (OFXMLParser*)parser
    foundCDATA: (OFString*)cdata;

/**
 * This callback is called when the XML parser found a comment.
 *
 * \param parser The parser which found a comment
 * \param comment The comment the XML parser found
 */
- (void)parser: (OFXMLParser*)parser
  foundComment: (OFString*)comment;

/**
 * This callback is called when the XML parser found an entity it doesn't know.
 * The callback is supposed to return a substitution for the entity or nil if
 * it is not known to the callback as well, in which case an exception will be
 * risen.
 *
 * \param parser The parser which found an unknown entity
 * \param entity The name of the entity the XML parser didn't know
 * \return A substitution for the entity or nil
 */
-	(OFString*)parser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity;
@end

/**
 * \brief An event-based XML parser.
 *
 * OFXMLParser is an event-based XML parser which calls the delegate's callbacks
 * as soon asit finds something, thus suitable for streams as well.
 */
@interface OFXMLParser: OFObject <OFStringXMLUnescapingDelegate>
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
		OF_XMLPARSER_IN_CDATA_OR_COMMENT,
		OF_XMLPARSER_IN_CDATA_OPENING_1,
		OF_XMLPARSER_IN_CDATA_OPENING_2,
		OF_XMLPARSER_IN_CDATA_OPENING_3,
		OF_XMLPARSER_IN_CDATA_OPENING_4,
		OF_XMLPARSER_IN_CDATA_OPENING_5,
		OF_XMLPARSER_IN_CDATA_OPENING_6,
		OF_XMLPARSER_IN_CDATA_1,
		OF_XMLPARSER_IN_CDATA_2,
		OF_XMLPARSER_IN_CDATA_3,
		OF_XMLPARSER_IN_COMMENT_OPENING,
		OF_XMLPARSER_IN_COMMENT_1,
		OF_XMLPARSER_IN_COMMENT_2,
		OF_XMLPARSER_IN_COMMENT_3
	} state;
	OFMutableString *cache;
	OFString *name;
	OFString *prefix;
	OFMutableArray *namespaces;
	OFMutableArray *attrs;
	OFString *attrName;
	OFString *attrPrefix;
	char delim;
	OFMutableArray *previous;
}

#ifdef OF_HAVE_PROPERTIES
@property (retain) OFObject <OFXMLParserDelegate> *delegate;
#endif

/**
 * \return A new, autoreleased OFXMLParser
 */
+ xmlParser;

/**
 * \return The delegate that is used by the XML parser
 */
- (OFObject <OFXMLParserDelegate>*)delegate;

/**
 * Sets the delegate the OFXMLParser should use.
 *
 * \param delegate The delegate to use
 */
- (void)setDelegate: (OFObject <OFXMLParserDelegate>*)delegate;

/**
 * Parses a buffer with the specified size.
 *
 * \param buf The buffer to parse
 * \param size The size of the buffer
 */
- (void)parseBuffer: (const char*)buf
	   withSize: (size_t)size;
@end

@interface OFObject (OFXMLParserDelegate) <OFXMLParserDelegate>
@end
