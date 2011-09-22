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

#import "OFException.h"

/**
 * \brief An exception indicating an attempt to use an unbound namespace.
 */
@interface OFUnboundNamespaceException: OFException
{
	OFString *ns;
	OFString *prefix;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic, getter=namespace) OFString *ns;
@property (readonly, nonatomic) OFString *prefix;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param ns The namespace which is unbound
 * \return A new unbound namespace exception
 */
+ exceptionWithClass: (Class)class_
	   namespace: (OFString*)ns;

/**
 * \param class_ The class of the object which caused the exception
 * \param prefix The prefix which is unbound
 * \return A new unbound namespace exception
 */
+ exceptionWithClass: (Class)class_
	      prefix: (OFString*)prefix;

/**
 * Initializes an already allocated unbound namespace exception
 *
 * \param class_ The class of the object which caused the exception
 * \param ns The namespace which is unbound
 * \return An initialized unbound namespace exception
 */
- initWithClass: (Class)class_
      namespace: (OFString*)ns;

/**
 * Initializes an already allocated unbound namespace exception
 *
 * \param class_ The class of the object which caused the exception
 * \param prefix The prefix which is unbound
 * \return An initialized unbound namespace exception
 */
- initWithClass: (Class)class_
	 prefix: (OFString*)prefix;

/**
 * \return The unbound namespace
 */
- (OFString*)namespace;

/**
 * \return The unbound prefix
 */
- (OFString*)prefix;
@end
