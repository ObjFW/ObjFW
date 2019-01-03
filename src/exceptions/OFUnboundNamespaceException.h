/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

@class OFXMLElement;

/*!
 * @class OFUnboundNamespaceException \
 *	  OFUnboundNamespaceException.h ObjFW/OFUnboundNamespaceException.h
 *
 * @brief An exception indicating an attempt to use an unbound namespace.
 */
@interface OFUnboundNamespaceException: OFException
{
	OFString *_namespace;
	OFXMLElement *_element;
}

/*!
 * @brief The unbound namespace.
 */
#ifndef __cplusplus
@property (readonly, nonatomic) OFString *namespace;
#else
@property (readonly, nonatomic, getter=namespace) OFString *namespace_;
#endif

/*!
 * @brief The element in which the namespace was not bound.
 */
@property (readonly, nonatomic) OFXMLElement *element;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased unbound namespace exception.
 *
 * @param namespace_ The namespace which is unbound
 * @param element The element in which the namespace was not bound
 * @return A new, autoreleased unbound namespace exception
 */
+ (instancetype)exceptionWithNamespace: (OFString *)namespace_
			       element: (OFXMLElement *)element;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated unbound namespace exception.
 *
 * @param namespace_ The namespace which is unbound
 * @param element The element in which the namespace was not bound
 * @return An initialized unbound namespace exception
 */
- (instancetype)initWithNamespace: (OFString *)namespace_
			  element: (OFXMLElement *)element
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
