/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

OF_ASSUME_NONNULL_BEGIN

@class OFXMLParser;
#ifndef DOXYGEN
@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
#endif
@class OFDataArray;
@class OFStream;

/*!
 * @protocol OFXMLParserDelegate OFXMLParser.h ObjFW/OFXMLParser.h
 *
 * @brief A protocol that needs to be implemented by delegates for OFXMLParser.
 */
@protocol OFXMLParserDelegate <OFObject>
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
/*!
 * @brief This callback is called when the XML parser found processing
 *	  instructions.
 *
 * @param parser The parser which found processing instructions
 * @param pi The processing instructions
 */
-		 (void)parser: (OFXMLParser*)parser
  foundProcessingInstructions: (OFString*)pi;

/*!
 * @brief This callback is called when the XML parser found the start of a new
 *	  tag.
 *
 * @param parser The parser which found a new tag
 * @param name The name of the tag which just started
 * @param prefix The prefix of the tag which just started or `nil`
 * @param ns The namespace of the tag which just started or `nil`
 * @param attributes The attributes included in the tag which just started or
 *		     `nil`
 */
-    (void)parser: (OFXMLParser*)parser
  didStartElement: (OFString*)name
	   prefix: (nullable OFString*)prefix
	namespace: (nullable OFString*)ns
       attributes: (nullable OFArray OF_GENERIC(OFXMLAttribute*)*)attributes;

/*!
 * @brief This callback is called when the XML parser found the end of a tag.
 *
 * @param parser The parser which found the end of a tag
 * @param name The name of the tag which just ended
 * @param prefix The prefix of the tag which just ended or `nil`
 * @param ns The namespace of the tag which just ended or `nil`
 */
-  (void)parser: (OFXMLParser*)parser
  didEndElement: (OFString*)name
	 prefix: (nullable OFString*)prefix
      namespace: (nullable OFString*)ns;

/*!
 * @brief This callback is called when the XML parser found characters.
 *
 * In case there are comments or CDATA, it is possible that this callback is
 * called multiple times in a row.
 *
 * @param parser The parser which found a string
 * @param characters The characters the XML parser found
 */
-    (void)parser: (OFXMLParser*)parser
  foundCharacters: (OFString*)characters;

/*!
 * @brief This callback is called when the XML parser found CDATA.
 *
 * @param parser The parser which found a string
 * @param CDATA The CDATA the XML parser found
 */
- (void)parser: (OFXMLParser*)parser
    foundCDATA: (OFString*)CDATA;

/*!
 * @brief This callback is called when the XML parser found a comment.
 *
 * @param parser The parser which found a comment
 * @param comment The comment the XML parser found
 */
- (void)parser: (OFXMLParser*)parser
  foundComment: (OFString*)comment;

/*!
 * @brief This callback is called when the XML parser found an entity it
 *	  doesn't know.
 *
 * The callback is supposed to return a substitution for the entity or `nil` if
 * it is not known to the callback as well, in which case an exception will be
 * risen.
 *
 * @param parser The parser which found an unknown entity
 * @param entity The name of the entity the XML parser didn't know
 * @return A substitution for the entity or `nil`
 */
-	(OFString*)parser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity;
@end

/*!
 * @class OFXMLParser OFXMLParser.h ObjFW/OFXMLParser.h
 *
 * @brief An event-based XML parser.
 *
 * OFXMLParser is an event-based XML parser which calls the delegate's callbacks
 * as soon asit finds something, thus suitable for streams as well.
 */
@interface OFXMLParser: OFObject <OFStringXMLUnescapingDelegate>
{
	id <OFXMLParserDelegate> _delegate;
	enum {
		OF_XMLPARSER_IN_BYTE_ORDER_MARK,
		OF_XMLPARSER_OUTSIDE_TAG,
		OF_XMLPARSER_TAG_OPENED,
		OF_XMLPARSER_IN_PROCESSING_INSTRUCTIONS,
		OF_XMLPARSER_IN_TAG_NAME,
		OF_XMLPARSER_IN_CLOSE_TAG_NAME,
		OF_XMLPARSER_IN_TAG,
		OF_XMLPARSER_IN_ATTRIBUTE_NAME,
		OF_XMLPARSER_EXPECT_ATTRIBUTE_EQUAL_SIGN,
		OF_XMLPARSER_EXPECT_ATTRIBUTE_DELIMITER,
		OF_XMLPARSER_IN_ATTRIBUTE_VALUE,
		OF_XMLPARSER_EXPECT_TAG_CLOSE,
		OF_XMLPARSER_EXPECT_SPACE_OR_TAG_CLOSE,
		OF_XMLPARSER_IN_EXCLAMATIONMARK,
		OF_XMLPARSER_IN_CDATA_OPENING,
		OF_XMLPARSER_IN_CDATA,
		OF_XMLPARSER_IN_COMMENT_OPENING,
		OF_XMLPARSER_IN_COMMENT_1,
		OF_XMLPARSER_IN_COMMENT_2,
		OF_XMLPARSER_IN_DOCTYPE,
		OF_XMLPARSER_NUM_STATES
	} _state;
	size_t _i, _last;
	const char *_data;
	OFDataArray *_buffer;
	OFString *_name, *_prefix;
	OFMutableArray
	    OF_GENERIC(OFMutableDictionary OF_GENERIC(OFString*, OFString*)*)
	    *_namespaces;
	OFMutableArray OF_GENERIC(OFXMLAttribute*) *_attributes;
	OFString *_attributeName, *_attributePrefix;
	char _delimiter;
	OFMutableArray OF_GENERIC(OFString*) *_previous;
	size_t _level;
	bool _acceptProlog;
	size_t _lineNumber;
	bool _lastCarriageReturn, _finishedParsing;
	of_string_encoding_t _encoding;
	size_t _depthLimit;
}

/*!
 * The delegate that is used by the XML parser.
 */
@property OF_NULLABLE_PROPERTY (assign) id <OFXMLParserDelegate> delegate;

/*!
 * The depth limit for the XML parser.
 *
 * If the depth limit is exceeded, an OFMalformedXMLException is thrown.
 *
 * The default is 32. 0 means unlimited (insecure!).
 */
@property size_t depthLimit;

/*!
 * @brief Creates a new XML parser.
 *
 * @return A new, autoreleased OFXMLParser
 */
+ (instancetype)parser;

/*!
 * @brief Parses the specified buffer with the specified size.
 *
 * @param buffer The buffer to parse
 * @param length The length of the buffer
 */
- (void)parseBuffer: (const char*)buffer
	     length: (size_t)length;

/*!
 * @brief Parses the specified string.
 *
 * @param string The string to parse
 */
- (void)parseString: (OFString*)string;

/*!
 * @brief Parses the specified stream.
 *
 * @param stream The stream to parse
 */
- (void)parseStream: (OFStream*)stream;

#ifdef OF_HAVE_FILES
/*!
 * @brief Parses the specified file.
 *
 * @param path The path to the file to parse
*/
- (void)parseFile: (OFString*)path;
#endif

/*!
 * @brief Returns the current line number.
 *
 * @return The current line number
 */
- (size_t)lineNumber;

/*!
 * @brief Returns whether the XML parser has finished parsing.
 *
 * @return Whether the XML parser has finished parsing
 */
- (bool)hasFinishedParsing;
@end

@interface OFObject (OFXMLParserDelegate) <OFXMLParserDelegate>
@end

OF_ASSUME_NONNULL_END
