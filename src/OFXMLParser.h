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

#import "OFObject.h"
#import "OFString.h"
#import "OFXMLAttribute.h"

@class OFXMLParser;
@class OFArray;
@class OFMutableArray;
@class OFDataArray;
@class OFStream;

/**
 * \brief A protocol that needs to be implemented by delegates for OFXMLParser.
 */
#ifndef OF_XML_PARSER_M
@protocol OFXMLParserDelegate <OFObject>
#else
@protocol OFXMLParserDelegate
#endif
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
/**
 * This callback is called when the XML parser found processing instructions.
 *
 * \param parser The parser which found processing instructions
 * \param pi The processing instructions
 */
-		 (void)parser: (OFXMLParser*)parser
  foundProcessingInstructions: (OFString*)pi;

/**
 * This callback is called when the XML parser found the start of a new tag.
 *
 * \param parser The parser which found a new tag
 * \param name The name of the tag which just started
 * \param prefix The prefix of the tag which just started or nil
 * \param ns The namespace of the tag which just started or nil
 * \param attributes The attributes included in the tag which just started or
 *		     nil
 */
-    (void)parser: (OFXMLParser*)parser
  didStartElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attributes;

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
 * \param characters The characters the XML parser found
 */
-    (void)parser: (OFXMLParser*)parser
  foundCharacters: (OFString*)characters;

/**
 * This callback is called when the XML parser found CDATA.
 *
 * \param parser The parser which found a string
 * \param CDATA The CDATA the XML parser found
 */
- (void)parser: (OFXMLParser*)parser
    foundCDATA: (OFString*)CDATA;

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
	id <OFXMLParserDelegate> delegate;
	enum {
		OF_XMLPARSER_OUTSIDE_TAG,
		OF_XMLPARSER_TAG_OPENED,
		OF_XMLPARSER_IN_PROCESSING_INSTRUCTIONS,
		OF_XMLPARSER_IN_TAG_NAME,
		OF_XMLPARSER_IN_CLOSE_TAG_NAME,
		OF_XMLPARSER_IN_TAG,
		OF_XMLPARSER_IN_ATTR_NAME,
		OF_XMLPARSER_EXPECT_DELIM,
		OF_XMLPARSER_IN_ATTR_VALUE,
		OF_XMLPARSER_EXPECT_CLOSE,
		OF_XMLPARSER_EXPECT_SPACE_OR_CLOSE,
		OF_XMLPARSER_IN_EXCLAMATIONMARK,
		OF_XMLPARSER_IN_CDATA_OPENING,
		OF_XMLPARSER_IN_CDATA_1,
		OF_XMLPARSER_IN_CDATA_2,
		OF_XMLPARSER_IN_COMMENT_OPENING,
		OF_XMLPARSER_IN_COMMENT_1,
		OF_XMLPARSER_IN_COMMENT_2,
		OF_XMLPARSER_IN_DOCTYPE,
		OF_XMLPARSER_NUM_STATES
	} state;
	OFDataArray *cache;
	OFString *name;
	OFString *prefix;
	OFMutableArray *namespaces;
	OFMutableArray *attributes;
	OFString *attributeName;
	OFString *attributePrefix;
	char delimiter;
	OFMutableArray *previous;
	size_t level;
	BOOL acceptProlog;
	size_t lineNumber;
	BOOL lastCarriageReturn;
	BOOL finishedParsing;
	of_string_encoding_t encoding;
}

#ifdef OF_HAVE_PROPERTIES
@property (retain) id <OFXMLParserDelegate> delegate;
#endif

/**
 * \return A new, autoreleased OFXMLParser
 */
+ parser;

/**
 * \return The delegate that is used by the XML parser
 */
- (id <OFXMLParserDelegate>)delegate;

/**
 * Sets the delegate the OFXMLParser should use.
 *
 * \param delegate The delegate to use
 */
- (void)setDelegate: (id <OFXMLParserDelegate>)delegate;

/**
 * Parses a buffer with the specified size.
 *
 * \param buffer The buffer to parse
 * \param length The length of the buffer
 */
- (void)parseBuffer: (const char*)buffer
	 withLength: (size_t)length;

/**
 * Parses the specified string.
 *
 * \param string The string to parse
 */
- (void)parseString: (OFString*)string;

/**
 * Parses the specified stream.
 *
 * \param stream The stream to parse
 */
- (void)parseStream: (OFStream*)stream;

/**
 * Parses the specified file.
 *
 * \param path The path to the file to parse
*/
- (void)parseFile: (OFString*)path;

/**
 * \return The current line number
 */
- (size_t)lineNumber;

/**
 * \return Whether the XML parser has finished parsing
 */
- (BOOL)finishedParsing;
@end

@interface OFObject (OFXMLParserDelegate) <OFXMLParserDelegate>
@end
