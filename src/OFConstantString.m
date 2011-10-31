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

#include "config.h"

#include <stdlib.h>
#include <string.h>

#import "OFConstantString.h"

#import "OFInvalidEncodingException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"

#ifdef OF_APPLE_RUNTIME
# import <objc/runtime.h>

void *_OFConstantStringClassReference;
#endif

@implementation OFConstantString
#ifdef OF_APPLE_RUNTIME
+ (void)load
{
	objc_setFutureClass((Class)&_OFConstantStringClassReference,
	    "OFConstantString");
}
#endif

- (void)finishInitialization
{
	struct of_string_ivars *ivars;

	if (initialized == SIZE_MAX)
		return;

	if ((ivars = malloc(sizeof(*ivars))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithClass: isa
			 requestedSize: sizeof(*ivars)];
	memset(ivars, 0, sizeof(*ivars));

	ivars->cString = (char*)s;
	ivars->cStringLength = initialized;

	switch (of_string_check_utf8(ivars->cString, ivars->cStringLength,
	    &ivars->length)) {
	case 1:
		ivars->UTF8 = YES;
		break;
	case -1:
		free(ivars);
		@throw [OFInvalidEncodingException exceptionWithClass: isa];
	}

	s = ivars;
	initialized = SIZE_MAX;
}

/*
 * The following methods are not available since it's a constant string, which
 * can't be allocated or initialized at runtime.
 */
+ alloc
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUTF8String: (const char*)UTF8String
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUTF8String: (const char*)UTF8String
	      length: (size_t)UTF8StringLength
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
	   length: (size_t)cStringLength
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithString: (OFString*)string
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUnicodeString: (const of_unichar_t*)string
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUnicodeString: (const of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUnicodeString: (const of_unichar_t*)string
		 length: (size_t)length
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUnicodeString: (const of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder
		 length: (size_t)length
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUTF16String: (const uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUTF16String: (const uint16_t*)string
	       length: (size_t)length
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUTF16String: (const uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder
	       length: (size_t)length
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithFormat: (OFConstantString*)format, ...
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithFormat: (OFConstantString*)format
       arguments: (va_list)args
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithPath: (OFString*)firstComponent, ...
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithPath: (OFString*)firstComponent
     arguments: (va_list)arguments
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithContentsOfFile: (OFString*)path
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithContentsOfFile: (OFString*)path
		encoding: (of_string_encoding_t)encoding
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithContentsOfURL: (OFURL*)URL
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithContentsOfURL: (OFURL*)URL
	       encoding: (of_string_encoding_t)encoding
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

/* From protocol OFSerializing */
- initWithSerialization: (OFXMLElement*)element
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

/*
 * The following methods are not available because constant strings are
 * preallocated by the compiler and thus don't have a memory pool.
 */
- (void)addMemoryToPool: (void*)ptr
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void*)allocMemoryWithSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void*)allocMemoryForNItems: (size_t)nitems
		     withSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void*)resizeMemory: (void*)ptr
	       toSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void*)resizeMemory: (void*)ptr
	     toNItems: (size_t)nitems
	     withSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)freeMemory: (void*)ptr
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

/*
 * The following methods are unnecessary because constant strings are
 * singletons.
 */
- retain
{
	return self;
}

- autorelease
{
	return self;
}

- (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
}

- (void)release
{
}

- (void)dealloc
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
}

/*
 * In all following methods, it is checked whether the constant string has been
 * initialized. If not, it will be initialized. Finally, the implementation of
 * the superclass will be called.
 */

/* From protocol OFCopying */
- copy
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super copy];
}

/* From protocol OFMutableCopying */
- mutableCopy
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super mutableCopy];
}

/* From protocol OFComparing */
- (of_comparison_result_t)compare: (id)object
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super compare: object];
}

/* From OFObject, but reimplemented in OFString */
- (BOOL)isEqual: (id)object
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super isEqual: object];
}

- (uint32_t)hash
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super hash];
}

- (OFString*)description
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super description];
}

/* From OFString */
- (const char*)UTF8String
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super UTF8String];
}

- (const char*)cStringWithEncoding: (of_string_encoding_t)encoding
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super cStringWithEncoding: encoding];
}

- (size_t)length
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super length];
}

- (size_t)UTF8StringLength
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super UTF8StringLength];
}

- (size_t)cStringLengthWithEncoding: (of_string_encoding_t)encoding
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super cStringLengthWithEncoding: encoding];
}

- (of_comparison_result_t)caseInsensitiveCompare: (OFString*)otherString
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super caseInsensitiveCompare: otherString];
}

- (of_unichar_t)characterAtIndex: (size_t)index
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super characterAtIndex: index];
}

- (size_t)indexOfFirstOccurrenceOfString: (OFString*)string
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super indexOfFirstOccurrenceOfString: string];
}

- (size_t)indexOfLastOccurrenceOfString: (OFString*)string
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super indexOfLastOccurrenceOfString: string];
}

- (BOOL)containsString: (OFString*)string
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super containsString: string];
}

- (OFString*)substringWithRange: (of_range_t)range
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super substringWithRange: range];
}

- (OFString*)stringByAppendingString: (OFString*)string
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super stringByAppendingString: string];
}

- (OFString*)stringByPrependingString: (OFString*)string
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super stringByPrependingString: string];
}

- (OFString*)uppercaseString
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super uppercaseString];
}

- (OFString*)lowercaseString
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super lowercaseString];
}

- (OFString*)stringByDeletingLeadingWhitespaces
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super stringByDeletingLeadingWhitespaces];
}

- (OFString*)stringByDeletingTrailingWhitespaces
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super stringByDeletingTrailingWhitespaces];
}

- (OFString*)stringByDeletingEnclosingWhitespaces
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super stringByDeletingEnclosingWhitespaces];
}

- (BOOL)hasPrefix: (OFString*)prefix
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super hasPrefix: prefix];
}

- (BOOL)hasSuffix: (OFString*)suffix
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super hasSuffix: suffix];
}

- (OFArray*)componentsSeparatedByString: (OFString*)delimiter
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super componentsSeparatedByString: delimiter];
}

- (OFArray*)pathComponents
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super pathComponents];
}

- (OFString*)lastPathComponent
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super lastPathComponent];
}

- (OFString*)stringByDeletingLastPathComponent
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super stringByDeletingLastPathComponent];
}

- (intmax_t)decimalValue
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super decimalValue];
}

- (uintmax_t)hexadecimalValue
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super hexadecimalValue];
}

- (float)floatValue
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super floatValue];
}

- (double)doubleValue
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super doubleValue];
}

- (const of_unichar_t*)unicodeString
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super unicodeString];
}

- (const uint16_t*)UTF16String
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super UTF16String];
}

- (void)writeToFile: (OFString*)path
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super writeToFile: path];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateLinesUsingBlock: (of_string_line_enumeration_block_t)block
{
	if (initialized != SIZE_MAX)
		[self finishInitialization];

	return [super enumerateLinesUsingBlock: block];
}
#endif
@end
