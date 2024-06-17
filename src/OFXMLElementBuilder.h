/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFObject.h"
#import "OFXMLParser.h"

OF_ASSUME_NONNULL_BEGIN

@class OFMutableArray OF_GENERIC(ObjectType);
@class OFXMLElement;
@class OFXMLElementBuilder;

/**
 * @protocol OFXMLElementBuilderDelegate OFXMLElementBuilder.h ObjFW/ObjFW.h
 *
 * @brief A protocol that needs to be implemented by delegates for
 * OFXMLElementBuilder.
 */
@protocol OFXMLElementBuilderDelegate <OFObject>
/**
 * @brief This callback is called when the OFXMLElementBuilder built an element.
 *
 * If the OFXMLElementBuilder was used as a delegate for the OFXMLParser since
 * parsing started, this will return the complete document as an OFXMLElement
 * with all children.
 *
 * @param builder The builder which built an OFXMLElement
 * @param element The OFXMLElement the OFXMLElementBuilder built
 */
- (void)elementBuilder: (OFXMLElementBuilder *)builder
       didBuildElement: (OFXMLElement *)element;

@optional
/**
 * @brief This callback is called when the OFXMLElementBuilder built an
 *	  OFXMLNode which is not inside an element.
 *
 * This is usually called for comments or whitespace character data before the
 * root element.
 *
 * @param builder The builder which built the OFXMLNode without parent
 * @param node The OFXMLNode the OFXMLElementBuilder built
 */
- (void)elementBuilder: (OFXMLElementBuilder *)builder
    didBuildOrphanNode: (OFXMLNode *)node;

/**
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
 * @param nameSpace The namespace of the close tag
 */
- (void)elementBuilder: (OFXMLElementBuilder *)builder
  didNotExpectCloseTag: (OFString *)name
		prefix: (nullable OFString *)prefix
	     namespace: (nullable OFString *)nameSpace;

/**
 * @brief This callback is called when the XML parser for the element builder
 *	  found an unknown entity.
 *
 * @param builder The element builder which found an unknown entity
 * @param entity The name of the entity
 * @return The substitution for the entity
 */
- (OFString *)elementBuilder: (OFXMLElementBuilder *)builder
     foundUnknownEntityNamed: (OFString *)entity;
@end

/**
 * @class OFXMLElementBuilder OFXMLElementBuilder.h ObjFW/ObjFW.h
 *
 * @brief A class implementing the OFXMLParserDelegate protocol that can build
 * OFXMLElements from the document parsed by the OFXMLParser.
 *
 * It can also be used to build OFXMLElements from parts of the document by
 * first parsing stuff using the OFXMLParser with another delegate and then
 * setting the OFXMLElementBuilder as delegate for the parser.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFXMLElementBuilder: OFObject <OFXMLParserDelegate>
{
	OFMutableArray OF_GENERIC(OFXMLElement *) *_stack;
	id <OFXMLElementBuilderDelegate> _Nullable _delegate;
}

/**
 * @brief The delegate for the OFXMLElementBuilder.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFXMLElementBuilderDelegate> delegate;

/**
 * @brief Creates a new element builder.
 *
 * @return A new, autoreleased OFXMLElementBuilder
 */
+ (instancetype)builder;
@end

OF_ASSUME_NONNULL_END
