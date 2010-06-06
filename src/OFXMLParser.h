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

extern int _OFXMLParser_reference;

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
-     (void)xmlParser: (OFXMLParser*)parser
  didStartTagWithName: (OFString*)name
	       prefix: (OFString*)prefix
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
-   (void)xmlParser: (OFXMLParser*)parser
  didEndTagWithName: (OFString*)name
	     prefix: (OFString*)prefix
	  namespace: (OFString*)ns;

/**
 * This callback is called when the XML parser found a string.
 *
 * \param parser The parser which found a string
 * \param string The string the XML parser found
 */
- (void)xmlParser: (OFXMLParser*)parser
      foundString: (OFString*)string;

/**
 * This callback is called when the XML parser found a comment.
 *
 * \param parser The parser which found a comment
 * \param comment The comment the XML parser found
 */
- (void)xmlParser: (OFXMLParser*)parser
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
-    (OFString*)xmlParser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity;
@end

/**
 * \brief A protocol that needs to be implemented by delegates for
 *	  -[stringByXMLUnescapingWithHandler:].
 */
@protocol OFXMLUnescapingDelegate
/**
 * This callback is called when an unknown entity was found while trying to
 * unescape XML. The callback is supposed to return a substitution for the
 * entity or nil if it is unknown to the callback as well, in which case an
 * exception will be thrown.
 *
 * \param entity The name of the entity that is unknown
 * \return A substitution for the entity or nil
 */
- (OFString*)foundUnknownEntityNamed: (OFString*)entity;
@end

/**
 * \brief An event-based XML parser.
 *
 * OFXMLParser is an event-based XML parser which calls the delegate's callbacks
 * as soon asit finds something, thus suitable for streams as well.
 */
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

/**
 * \brief A category for unescaping XML in strings.
 */
@interface OFString (OFXMLUnescaping)
/**
 * Unescapes XML in the string.
 */
- (OFString*)stringByXMLUnescaping;

/**
 * Unescapes XML in the string and uses the specified handler for unknown
 * entities.
 *
 * \param h An OFXMLUnescapingDelegate as a handler for unknown entities
 */
- (OFString*)stringByXMLUnescapingWithHandler:
    (OFObject <OFXMLUnescapingDelegate>*)h;
@end

@interface OFObject (OFXMLParserDelegate) <OFXMLParserDelegate>
@end
