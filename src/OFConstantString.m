/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#define OF_CONSTANT_STRING_M

#include <stdlib.h>
#include <string.h>

#import "OFConstantString.h"
#import "OFString_UTF8.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidEncodingException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"

#if defined(OF_APPLE_RUNTIME) && !defined(__OBJC2__)
# import <objc/runtime.h>

struct {
	struct class *isa, *super_class;
	const char *name;
	long version, info, instance_size;
	struct ivar_list *ivars;
	struct method_list **methodLists;
	struct cache *cache;
	struct protocol_list *protocols;
	const char *ivar_layout;
	struct class_ext *ext;
} _OFConstantStringClassReference;
#endif

@interface OFString_const: OFString_UTF8
@end

@implementation OFString_const
+ alloc
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}


- (void*)allocMemoryWithSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void*)allocMemoryWithSize: (size_t)itemSize
		       count: (size_t)count
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void*)resizeMemory: (void*)ptr
		 size: (size_t)size
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
@end

@implementation OFConstantString
+ (void)load
{
#if defined(OF_APPLE_RUNTIME) && !defined(__OBJC2__)
	/*
	 * objc_setFutureClass suddenly stopped working as OFConstantString
	 * became more complex. So the only solution is to make
	 * _OFConstantStringClassRerence the actual class, but there is no
	 * objc_initializeClassPair in 10.5.  However, objc_allocateClassPair
	 * does not register the new class with the subclass in the ObjC1
	 * runtime like the ObjC2 runtime does, so this workaround should be
	 * fine.
	 */
	Class class;

	if ((class = objc_allocateClassPair(self, "OFConstantString_hack",
	    0)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	memcpy(&_OFConstantStringClassReference, class,
	    sizeof(_OFConstantStringClassReference));
	free(class);
	objc_registerClassPair((Class)&_OFConstantStringClassReference);
#endif
}

- (void)finishInitialization
{
	struct of_string_utf8_ivars *ivars;

	if ((ivars = malloc(sizeof(*ivars))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithClass: isa
			 requestedSize: sizeof(*ivars)];
	memset(ivars, 0, sizeof(*ivars));

	ivars->cString = cString;
	ivars->cStringLength = cStringLength;

	switch (of_string_check_utf8(ivars->cString, ivars->cStringLength,
	    &ivars->length)) {
	case 1:
		ivars->UTF8 = YES;
		break;
	case -1:
		free(ivars);
		@throw [OFInvalidEncodingException exceptionWithClass: isa];
	}

	cString = (char*)ivars;
	isa = [OFString_const class];
}

+ alloc
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

- (void*)allocMemoryWithSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void*)allocMemoryWithSize: (size_t)size
		       count: (size_t)count
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void*)resizeMemory: (void*)ptr
		 size: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void*)resizeMemory: (void*)ptr
		 size: (size_t)size
		count: (size_t)count
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)freeMemory: (void*)ptr
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

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
 * In all following methods, the constant string is converted to an
 * OFString_UTF8 and the message sent again.
 */

/* From protocol OFCopying */
- copy
{
	[self finishInitialization];

	return [self copy];
}

/* From protocol OFMutableCopying */
- mutableCopy
{
	[self finishInitialization];

	return [self mutableCopy];
}

/* From protocol OFComparing */
- (of_comparison_result_t)compare: (id)object
{
	[self finishInitialization];

	return [self compare: object];
}

/* From OFObject, but reimplemented in OFString */
- (BOOL)isEqual: (id)object
{
	[self finishInitialization];

	return [self isEqual: object];
}

- (uint32_t)hash
{
	[self finishInitialization];

	return [self hash];
}

- (OFString*)description
{
	[self finishInitialization];

	return [self description];
}

/* From OFString */
- (const char*)UTF8String
{
	[self finishInitialization];

	return [self UTF8String];
}

- (const char*)cStringWithEncoding: (of_string_encoding_t)encoding
{
	[self finishInitialization];

	return [self cStringWithEncoding: encoding];
}

- (size_t)length
{
	[self finishInitialization];

	return [self length];
}

- (size_t)UTF8StringLength
{
	[self finishInitialization];

	return [self UTF8StringLength];
}

- (size_t)cStringLengthWithEncoding: (of_string_encoding_t)encoding
{
	[self finishInitialization];

	return [self cStringLengthWithEncoding: encoding];
}

- (of_comparison_result_t)caseInsensitiveCompare: (OFString*)otherString
{
	[self finishInitialization];

	return [self caseInsensitiveCompare: otherString];
}

- (of_unichar_t)characterAtIndex: (size_t)index
{
	[self finishInitialization];

	return [self characterAtIndex: index];
}

- (void)getCharacters: (of_unichar_t*)buffer
	      inRange: (of_range_t)range
{
	[self finishInitialization];

	return [self getCharacters: buffer
			   inRange: range];
}

- (size_t)indexOfFirstOccurrenceOfString: (OFString*)string
{
	[self finishInitialization];

	return [self indexOfFirstOccurrenceOfString: string];
}

- (size_t)indexOfLastOccurrenceOfString: (OFString*)string
{
	[self finishInitialization];

	return [self indexOfLastOccurrenceOfString: string];
}

- (BOOL)containsString: (OFString*)string
{
	[self finishInitialization];

	return [self containsString: string];
}

- (OFString*)substringWithRange: (of_range_t)range
{
	[self finishInitialization];

	return [self substringWithRange: range];
}

- (OFString*)stringByAppendingString: (OFString*)string
{
	[self finishInitialization];

	return [self stringByAppendingString: string];
}

- (OFString*)stringByPrependingString: (OFString*)string
{
	[self finishInitialization];

	return [self stringByPrependingString: string];
}

- (OFString*)uppercaseString
{
	[self finishInitialization];

	return [self uppercaseString];
}

- (OFString*)lowercaseString
{
	[self finishInitialization];

	return [self lowercaseString];
}

- (OFString*)stringByDeletingLeadingWhitespaces
{
	[self finishInitialization];

	return [self stringByDeletingLeadingWhitespaces];
}

- (OFString*)stringByDeletingTrailingWhitespaces
{
	[self finishInitialization];

	return [self stringByDeletingTrailingWhitespaces];
}

- (OFString*)stringByDeletingEnclosingWhitespaces
{
	[self finishInitialization];

	return [self stringByDeletingEnclosingWhitespaces];
}

- (BOOL)hasPrefix: (OFString*)prefix
{
	[self finishInitialization];

	return [self hasPrefix: prefix];
}

- (BOOL)hasSuffix: (OFString*)suffix
{
	[self finishInitialization];

	return [self hasSuffix: suffix];
}

- (OFArray*)componentsSeparatedByString: (OFString*)delimiter
{
	[self finishInitialization];

	return [self componentsSeparatedByString: delimiter];
}

- (OFArray*)pathComponents
{
	[self finishInitialization];

	return [self pathComponents];
}

- (OFString*)lastPathComponent
{
	[self finishInitialization];

	return [self lastPathComponent];
}

- (OFString*)stringByDeletingLastPathComponent
{
	[self finishInitialization];

	return [self stringByDeletingLastPathComponent];
}

- (intmax_t)decimalValue
{
	[self finishInitialization];

	return [self decimalValue];
}

- (uintmax_t)hexadecimalValue
{
	[self finishInitialization];

	return [self hexadecimalValue];
}

- (float)floatValue
{
	[self finishInitialization];

	return [self floatValue];
}

- (double)doubleValue
{
	[self finishInitialization];

	return [self doubleValue];
}

- (const of_unichar_t*)unicodeString
{
	[self finishInitialization];

	return [self unicodeString];
}

- (const uint16_t*)UTF16String
{
	[self finishInitialization];

	return [self UTF16String];
}

- (void)writeToFile: (OFString*)path
{
	[self finishInitialization];

	return [self writeToFile: path];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateLinesUsingBlock: (of_string_line_enumeration_block_t)block
{
	[self finishInitialization];

	return [self enumerateLinesUsingBlock: block];
}
#endif
@end
