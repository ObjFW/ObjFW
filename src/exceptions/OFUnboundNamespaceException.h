/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

@class OFXMLElement;

/**
 * @class OFUnboundNamespaceException OFUnboundNamespaceException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating an attempt to use an unbound namespace.
 */
@interface OFUnboundNamespaceException: OFException
{
	OFString *_namespace;
	OFXMLElement *_element;
	OF_RESERVE_IVARS(OFUnboundNamespaceException, 4)
}

/**
 * @brief The unbound namespace.
 */
#ifndef __cplusplus
@property (readonly, nonatomic) OFString *namespace;
#else
@property (readonly, nonatomic, getter=namespace) OFString *nameSpace;
#endif

/**
 * @brief The element in which the namespace was not bound.
 */
@property (readonly, nonatomic) OFXMLElement *element;

/**
 * @brief Creates a new, autoreleased unbound namespace exception.
 *
 * @param nameSpace The namespace which is unbound
 * @param element The element in which the namespace was not bound
 * @return A new, autoreleased unbound namespace exception
 */
+ (instancetype)exceptionWithNamespace: (OFString *)nameSpace
			       element: (OFXMLElement *)element;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated unbound namespace exception.
 *
 * @param nameSpace The namespace which is unbound
 * @param element The element in which the namespace was not bound
 * @return An initialized unbound namespace exception
 */
- (instancetype)initWithNamespace: (OFString *)nameSpace
			  element: (OFXMLElement *)element
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
