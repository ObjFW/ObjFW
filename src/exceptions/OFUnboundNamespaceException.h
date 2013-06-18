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

#import "OFException.h"

@class OFXMLElement;

/*!
 * @brief An exception indicating an attempt to use an unbound namespace.
 */
@interface OFUnboundNamespaceException: OFException
{
	OFString *_namespace;
	OFXMLElement *_element;
}

#ifdef OF_HAVE_PROPERTIES
# ifdef __cplusplus
@property (readonly, copy, nonatomic, getter=namespace) OFString *namespace_;
# else
@property (readonly, copy, nonatomic) OFString *namespace;
# endif
@property (readonly, retain, nonatomic) OFXMLElement *element;
#endif

/*!
 * @brief Creates a new, autoreleased unbound namespace exception.
 *
 * @param namespace_ The namespace which is unbound
 * @param element The element in which the namespace was not bound
 * @return A new, autoreleased unbound namespace exception
 */
+ (instancetype)exceptionWithNamespace: (OFString*)namespace_
			       element: (OFXMLElement*)element;

/*!
 * @brief Initializes an already allocated unbound namespace exception.
 *
 * @param namespace_ The namespace which is unbound
 * @param element The element in which the namespace was not bound
 * @return An initialized unbound namespace exception
 */
- initWithNamespace: (OFString*)namespace_
	    element: (OFXMLElement*)element;

/*!
 * @brief Returns the unbound namespace.
 *
 * @return The unbound namespace
 */
- (OFString*)namespace;

/*!
 * @brief Returns the element in which the namespace was not bound.
 *
 * @return The element in which the namespace was not bound
 */
- (OFXMLElement*)element;
@end
