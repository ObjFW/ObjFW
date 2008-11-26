/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "wchar.h"

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
 * XML-escapes a wide C string.
 *
 * \param s The wide C string to escape
 * \return The escaped wide C string.
 *	   You need to free it manually!
 */
+ (wchar_t*)escapeWideCString: (const wchar_t*)s;

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
 * Creates an XML stanza as a wide C string.
 *
 * \param name The name of the tag as a wide C string
 * \param close A boolean whether the tag should be closed
 * \param data Data that should be inside the tag as a wide C string.
 *	  It will NOT be escaped, so you can also include other stanzas.
 * \param ... Field / value pairs for the tag in the form "field", "value" as
 *	  wide C strings.
 *	  Last element must be NULL.
 *	  Example: L"field1", L"value1", L"field2", L"value2", NULL
 * \return The created XML stanza as a wide C string.
 *	   You need to free it manually!
 */
+ (wchar_t*)createWideStanza: (const wchar_t*)name
		withCloseTag: (BOOL)close
		     andData: (const wchar_t*)data, ...;

/**
 * Concats an array of C strings into one C string and frees the array of C
 * strings.
 *
 * \param strs An array of C strings
 * \return The concatenated C strings.
 *	   You need to free it manually!
 */
+ (char*)concatAndFreeCStrings: (char**)strs;

/**
 * Concats an array of wide C strings into one wide C string and frees the
 * array of wide C strings.
 *
 * \param strs An array of wide C strings
 * \return The concatenated wide C strings.
 *	   You need to free it manually!
 */
+ (wchar_t*)concatAndFreeWideCStrings: (wchar_t**)strs;
@end
