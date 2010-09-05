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

@class OFMutableArray;
@class OFXMLElement;
@class OFXMLElementBuilder;

/**
 * \brief A protocol that needs to be implemented by delegates for
 * OFXMLElementBuilder.
 */
@protocol OFXMLElementBuilderDelegate
/**
 * This callback is called when the OFXMLElementBuilder built an element.
 *
 * If the OFXMLElementBuilder was used as a delegate for the OFXMLParser since
 * parsing started, this will return the complete document as an OFXMLElement
 * with all children.
 *
 * \param builder The builder which built an OFXMLElement
 * \param elem The OFXMLElement the OFXMLElementBuilder built
 */
- (void)elementBuilder: (OFXMLElementBuilder*)builder
       didBuildElement: (OFXMLElement*)elem;
@end

/**
 * \brief A class implementing the OFXMLParserDelegate protocol that can build
 * OFXMLElements from the document parsed by the OFXMLParser.
 *
 * It can also be used to build OFXMLElements from parts of the document by
 * first parsing stuff using the OFXMLParser with another delegate and then
 * setting the OFXMLElementBuilder as delegate for the parser.
 */
@interface OFXMLElementBuilder: OFObject
{
	OFMutableArray *stack;
	id <OFXMLElementBuilderDelegate> delegate;
}

#ifdef OF_HAVE_PROPERTIES
@property (retain) id <OFXMLElementBuilderDelegate> delegate;
#endif

/**
 * \return A new, autoreleased OFXMLElementBuilder
 */
+ elementBuilder;

/**
 * \return The delegate for the OFXMLElementBuilder
 */
- (id <OFXMLElementBuilderDelegate>)delegate;

/**
 * Sets the delegate for the OFXMLElementBuilder.
 *
 * \param delegate The delegate for the OFXMLElementBuilder
 */
- (void)setDelegate: (id <OFXMLElementBuilderDelegate>)delegate;
@end
