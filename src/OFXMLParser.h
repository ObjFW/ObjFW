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
@class OFStream;

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
typedef void (^of_xml_parser_processing_instructions_block_t)(
    OFXMLParser *parser, OFString *pi);
typedef void (^of_xml_parser_element_start_block_t)(OFXMLParser *parser,
    OFString *name, OFString *prefix, OFString *ns, OFArray *attrs);
typedef void (^of_xml_parser_element_end_block_t)(OFXMLParser *parser,
    OFString *name, OFString *prefix, OFString *ns);
typedef void (^of_xml_parser_string_block_t)(OFXMLParser *parser,
    OFString *string);
typedef OFString* (^of_xml_parser_unknown_entity_block_t)(OFXMLParser *parser,
    OFString *entity);
#endif

/**
 * \brief A protocol that needs to be implemented by delegates for OFXMLParser.
 */
@protocol OFXMLParserDelegate
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
 * \param cdata The CDATA the XML parser found
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
	OFMutableString *cache;
	OFString *name;
	OFString *prefix;
	OFMutableArray *namespaces;
	OFMutableArray *attrs;
	OFString *attrName;
	OFString *attrPrefix;
	char delim;
	OFMutableArray *previous;
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	of_xml_parser_processing_instructions_block_t
	    processingInstructionsHandler;
	of_xml_parser_element_start_block_t elementStartHandler;
	of_xml_parser_element_end_block_t elementEndHandler;
	of_xml_parser_string_block_t charactersHandler;
	of_xml_parser_string_block_t CDATAHandler;
	of_xml_parser_string_block_t commentHandler;
	of_xml_parser_unknown_entity_block_t unknownEntityHandler;
#endif
	size_t level;
	size_t lineNumber;
	BOOL lastCarriageReturn;
	BOOL finishedParsing;
}

#ifdef OF_HAVE_PROPERTIES
@property (retain) id <OFXMLParserDelegate> delegate;
# ifdef OF_HAVE_BLOCKS
@property (copy) of_xml_parser_processing_instructions_block_t
    processingInstructionsHandler;
@property (copy) of_xml_parser_element_start_block_t elementStartHandler;
@property (copy) of_xml_parser_element_end_block_t elementEndHandler;
@property (copy) of_xml_parser_string_block_t charactersHandler;
@property (copy) of_xml_parser_string_block_t CDATAHandler;
@property (copy) of_xml_parser_string_block_t commentHandler;
@property (copy) of_xml_parser_unknown_entity_block_t unknownEntityHandler;
# endif
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

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
/**
 * \return The processing instructions handler
 */
- (of_xml_parser_processing_instructions_block_t)processingInstructionsHandler;

/**
 * Sets the processing instructions handler.
 *
 * \param block A processing instructions handler
 */
- (void)setProcessingInstructionsHandler:
    (of_xml_parser_processing_instructions_block_t)block;

/**
 * \return The element start handler
 */
- (of_xml_parser_element_start_block_t)elementStartHandler;

/**
 * Sets the element start handler.
 *
 * \param block An element start handler
 */
- (void)setElementStartHandler: (of_xml_parser_element_start_block_t)block;

/**
 * \return The element end handler
 */
- (of_xml_parser_element_end_block_t)elementEndHandler;

/**
 * Sets the element end handler.
 *
 * \param block An element end handler
 */
- (void)setElementEndHandler: (of_xml_parser_element_end_block_t)block;

/**
 * \return The characters handler
 */
- (of_xml_parser_string_block_t)charactersHandler;

/**
 * Sets the characters handler.
 *
 * \param block A characters handler
 */
- (void)setCharactersHandler: (of_xml_parser_string_block_t)block;

/**
 * \return The CDATA handler
 */
- (of_xml_parser_string_block_t)CDATAHandler;

/**
 * Sets the CDATA handler.
 *
 * \param block A CDATA handler
 */
- (void)setCDATAHandler: (of_xml_parser_string_block_t)block;

/**
 * \return The comment handler
 */
- (of_xml_parser_string_block_t)commentHandler;

/**
 * Sets the comment handler.
 *
 * \param block A comment handler
 */
- (void)setCommentHandler: (of_xml_parser_string_block_t)block;

/**
 * \return The unknown entity handler
 */
- (of_xml_parser_unknown_entity_block_t)unknownEntityHandler;

/**
 * Sets the unknown entity handler.
 *
 * \param block An unknown entity handler
 */
- (void)setUnknownEntityHandler: (of_xml_parser_unknown_entity_block_t)block;
#endif

/**
 * Parses a buffer with the specified size.
 *
 * \param buf The buffer to parse
 * \param size The size of the buffer
 */
- (void)parseBuffer: (const char*)buf
	   withSize: (size_t)size;

/**
 * Parses the specified string.
 *
 * \param str The string to parse
 */
- (void)parseString: (OFString*)str;

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
