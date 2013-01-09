/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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
#import "OFXMLParser.h"

@class OFMutableArray;
@class OFXMLElement;
@class OFXMLElementBuilder;

/*!
 * @brief A protocol that needs to be implemented by delegates for
 * OFXMLElementBuilder.
 */
@protocol OFXMLElementBuilderDelegate <OFObject>
/*!
 * @brief This callback is called when the OFXMLElementBuilder built an element.
 *
 * If the OFXMLElementBuilder was used as a delegate for the OFXMLParser since
 * parsing started, this will return the complete document as an OFXMLElement
 * with all children.
 *
 * @param builder The builder which built an OFXMLElement
 * @param element The OFXMLElement the OFXMLElementBuilder built
 */
- (void)elementBuilder: (OFXMLElementBuilder*)builder
       didBuildElement: (OFXMLElement*)element;

#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif

/*!
 * @brief This callback is called when the OFXMLElementBuilder built an
 *	  OFXMLNode which is not inside an element.
 *
 * This is usually called for comments or whitespace character data before the
 * root element.
 *
 * @param builder The builder which built the OFXMLNode without parent
 * @param node The OFXMLNode the OFXMLElementBuilder built
 */
-   (void)elementBuilder: (OFXMLElementBuilder*)builder
  didBuildParentlessNode: (OFXMLNode*)node;

/*!
 * @brief This callback is called when the OFXMLElementBuilder gets a close tag
 *	  which does not belong there.
 *
 * Most likely, the OFXMLElementBuilder was used to build XML only of a child
 * of the root element and the root element was closed. Often the delegate is
 * set to the OFXMLElementBuilder when a certain element is found, this can be
 * used then to set the delegate back after that certain element has been
 * closed.
 *
 * If this method is not implemented in the delegate, the default is to throw
 * an OFMalformedXMLException.
 *
 * @param builder The builder which did not expect the close tag
 * @param name The name of the close tag
 * @param prefix The prefix of the close tag
 * @param ns The namespace of the close tag
 */
- (void)elementBuilder: (OFXMLElementBuilder*)builder
  didNotExpectCloseTag: (OFString*)name
		prefix: (OFString*)prefix
	     namespace: (OFString*)ns;

/*!
 * @brief This callback is called when the XML parser for the element builder
 *	  found an unknown entity.
 *
 * @param builder The element builder which found an unknown entity
 * @param entity The name of the entity
 * @return The substitution for the entity
 */
- (OFString*)elementBuilder: (OFXMLElementBuilder*)builder
    foundUnknownEntityNamed: (OFString*)entity;
@end

/*!
 * @brief A class implementing the OFXMLParserDelegate protocol that can build
 * OFXMLElements from the document parsed by the OFXMLParser.
 *
 * It can also be used to build OFXMLElements from parts of the document by
 * first parsing stuff using the OFXMLParser with another delegate and then
 * setting the OFXMLElementBuilder as delegate for the parser.
 */
@interface OFXMLElementBuilder: OFObject <OFXMLParserDelegate>
{
	OFMutableArray *stack;
	id <OFXMLElementBuilderDelegate> delegate;
}

#ifdef OF_HAVE_PROPERTIES
@property (assign) id <OFXMLElementBuilderDelegate> delegate;
#endif

/*!
 * @brief Creates a new element builder.
 *
 * @return A new, autoreleased OFXMLElementBuilder
 */
+ (instancetype)elementBuilder;

/*!
 * @brief Returns the delegate for the OFXMLElementBuilder.
 *
 * @return The delegate for the OFXMLElementBuilder
 */
- (id <OFXMLElementBuilderDelegate>)delegate;

/*!
 * @brief Sets the delegate for the OFXMLElementBuilder.
 *
 * @param delegate The delegate for the OFXMLElementBuilder
 */
- (void)setDelegate: (id <OFXMLElementBuilderDelegate>)delegate;
@end

@interface OFObject (OFXMLElementBuilderDelegate) <OFXMLElementBuilderDelegate>
@end
