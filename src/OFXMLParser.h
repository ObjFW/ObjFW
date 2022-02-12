/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

@class OFArray OF_GENERIC(ObjectType);
@class OFMutableData;
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
@class OFStream;
@class OFXMLParser;

/**
 * @protocol OFXMLParserDelegate OFXMLParser.h ObjFW/OFXMLParser.h
 *
 * @brief A protocol that needs to be implemented by delegates for OFXMLParser.
 */
@protocol OFXMLParserDelegate <OFObject>
@optional
/**
 * @brief This callback is called when the XML parser found a processing
 *	  instruction.
 *
 * @param parser The parser which found a processing instruction
 * @param target The target of the processing instruction
 * @param data The data of the processing instruction
 */
-			  (void)parser: (OFXMLParser *)parser
  foundProcessingInstructionWithTarget: (OFString *)target
				  data: (OFString *)data;

/**
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
-    (void)parser: (OFXMLParser *)parser
  didStartElement: (OFString *)name
	   prefix: (nullable OFString *)prefix
	namespace: (nullable OFString *)ns
       attributes: (nullable OFArray OF_GENERIC(OFXMLAttribute *) *)attributes;

/**
 * @brief This callback is called when the XML parser found the end of a tag.
 *
 * @param parser The parser which found the end of a tag
 * @param name The name of the tag which just ended
 * @param prefix The prefix of the tag which just ended or `nil`
 * @param ns The namespace of the tag which just ended or `nil`
 */
-  (void)parser: (OFXMLParser *)parser
  didEndElement: (OFString *)name
	 prefix: (nullable OFString *)prefix
      namespace: (nullable OFString *)ns;

/**
 * @brief This callback is called when the XML parser found characters.
 *
 * In case there are comments or CDATA, it is possible that this callback is
 * called multiple times in a row.
 *
 * @param parser The parser which found a string
 * @param characters The characters the XML parser found
 */
- (void)parser: (OFXMLParser *)parser foundCharacters: (OFString *)characters;

/**
 * @brief This callback is called when the XML parser found CDATA.
 *
 * @param parser The parser which found a string
 * @param CDATA The CDATA the XML parser found
 */
- (void)parser: (OFXMLParser *)parser foundCDATA: (OFString *)CDATA;

/**
 * @brief This callback is called when the XML parser found a comment.
 *
 * @param parser The parser which found a comment
 * @param comment The comment the XML parser found
 */
- (void)parser: (OFXMLParser *)parser foundComment: (OFString *)comment;

/**
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
- (nullable OFString *)parser: (OFXMLParser *)parser
      foundUnknownEntityNamed: (OFString *)entity;
@end

/**
 * @class OFXMLParser OFXMLParser.h ObjFW/OFXMLParser.h
 *
 * @brief An event-based XML parser.
 *
 * OFXMLParser is an event-based XML parser which calls the delegate's callbacks
 * as soon as it finds something, thus suitable for streams as well.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFXMLParser: OFObject
{
	id <OFXMLParserDelegate> _Nullable _delegate;
	uint_least8_t _state;
	size_t _i, _last;
	const char *_Nullable _data;
	OFMutableData *_buffer;
	OFString *_Nullable _name, *_Nullable _prefix;
	OFMutableArray
	    OF_GENERIC(OFMutableDictionary OF_GENERIC(OFString *, OFString *) *)
	    *_namespaces;
	OFMutableArray OF_GENERIC(OFXMLAttribute *) *_attributes;
	OFString *_Nullable _attributeName, *_Nullable _attributePrefix;
	char _delimiter;
	OFMutableArray OF_GENERIC(OFString *) *_previous;
	size_t _level;
	bool _acceptProlog;
	size_t _lineNumber;
	bool _lastCarriageReturn, _finishedParsing;
	OFStringEncoding _encoding;
	size_t _depthLimit;
}

/**
 * @brief The delegate that is used by the XML parser.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFXMLParserDelegate> delegate;

/**
 * @brief The current line number.
 */
@property (readonly, nonatomic) size_t lineNumber;

/**
 * @brief Whether the XML parser has finished parsing.
 */
@property (readonly, nonatomic) bool hasFinishedParsing;

/**
 * @brief The depth limit for the XML parser.
 *
 * If the depth limit is exceeded, an OFMalformedXMLException is thrown.
 *
 * The default is 32. 0 means unlimited (insecure!).
 */
@property (nonatomic) size_t depthLimit;

/**
 * @brief Creates a new XML parser.
 *
 * @return A new, autoreleased OFXMLParser
 */
+ (instancetype)parser;

/**
 * @brief Parses the specified buffer with the specified size.
 *
 * @param buffer The buffer to parse
 * @param length The length of the buffer
 */
- (void)parseBuffer: (const char *)buffer length: (size_t)length;

/**
 * @brief Parses the specified string.
 *
 * @param string The string to parse
 */
- (void)parseString: (OFString *)string;

/**
 * @brief Parses the specified stream.
 *
 * @param stream The stream to parse
 */
- (void)parseStream: (OFStream *)stream;
@end

OF_ASSUME_NONNULL_END
