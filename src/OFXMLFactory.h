/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <stdio.h>
#include <stdarg.h>

#import "OFObject.h"

/**
 * The OFXMLFactory class provides an easy way to create XML stanzas.
 */
@interface OFXMLFactory: OFObject {}
/**
 * XML-escapes a C string.
 *
 * \param s The C string to escape
 * \return The escaped C string.
 *	   You need to free it manually!
 */
+ (char*)escapeCString: (const char*)s;

/**
 * Creates an XML stanza.
 *
 * \param name The name of the tag as a C string
 * \param close A boolean whether the tag should be closed
 * \param data Data that should be inside the tag as a C string.
 *	  It will NOT be escaped, so you can also include other stanzas.
 * \param ... Field / value pairs for the tag in the form "field", "value" as
 *	  C strings.
 *	  Last element must be NULL.
 *	  Example: "field1", "value1", "field2", "value2", NULL
 * \return The created XML stanza as a C string.
 *	   You need to free it manually!
 */
+ (char*)createStanza: (const char*)name
	 withCloseTag: (BOOL)close
	      andData: (const char*)data, ...;

/**
 * Concats an array of C strings into one C string and frees the array of C
 * strings.
 *
 * \param strs An array of C strings
 * \return The concatenated C strings.
 *	   You need to free it manually!
 */
+ (char*)concatAndFreeCStrings: (char**)strs;
@end
