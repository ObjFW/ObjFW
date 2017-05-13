/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#include "config.h"

#import "OFString.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"
#import "OFMemoryNotPartOfObjectException.h"
#import "OFOutOfMemoryException.h"
#import "OFUndefinedKeyException.h"

#import "TestsAppDelegate.h"

#if (defined(OF_DRAGONFLYBSD) && defined(__LP64__)) || defined(OF_NINTENDO_3DS)
# define TOO_BIG (SIZE_MAX / 3)
#else
# define TOO_BIG (SIZE_MAX - 128)
#endif

static OFString *module = @"OFObject";

@interface MyObj: OFObject
{
	id _objectValue;
	Class _classValue;
	bool _boolValue;
	char _charValue;
	short _shortValue;
	int _intValue;
	long _longValue;
	long long _longLongValue;
	unsigned char _unsignedCharValue;
	unsigned short _unsignedShortValue;
	unsigned int _unsignedIntValue;
	unsigned long _unsignedLongValue;
	unsigned long long _unsignedLongLongValue;
	float _floatValue;
	double _doubleValue;
}

@property (nonatomic, retain) id objectValue;
@property (nonatomic) Class classValue;
@property (nonatomic, getter=isBoolValue) bool boolValue;
@property (nonatomic) char charValue;
@property (nonatomic) short shortValue;
@property (nonatomic) int intValue;
@property (nonatomic) long longValue;
@property (nonatomic) long long longLongValue;
@property (nonatomic) unsigned char unsignedCharValue;
@property (nonatomic) unsigned short unsignedShortValue;
@property (nonatomic) unsigned int unsignedIntValue;
@property (nonatomic) unsigned long unsignedLongValue;
@property (nonatomic) unsigned long long unsignedLongLongValue;
@property (nonatomic) float floatValue;
@property (nonatomic) double doubleValue;
@end

@implementation MyObj
@synthesize objectValue = _objectValue, classValue = _classValue;
@synthesize boolValue = _boolValue, charValue = _charValue;
@synthesize shortValue = _shortValue, intValue = _intValue;
@synthesize longValue = _longValue, longLongValue = _longLongValue;
@synthesize unsignedCharValue = _unsignedCharValue;
@synthesize unsignedShortValue = _unsignedShortValue;
@synthesize unsignedIntValue = _unsignedIntValue;
@synthesize unsignedLongValue = _unsignedLongValue;
@synthesize unsignedLongLongValue = _unsignedLongLongValue;
@synthesize floatValue = _floatValue, doubleValue = _doubleValue;

- (void)dealloc
{
	[_objectValue release];

	[super dealloc];
}
@end

@implementation TestsAppDelegate (OFObjectTests)
- (void)objectTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFObject *obj = [[[OFObject alloc] init] autorelease];
	void *p, *q, *r;
	OFObject *o;
	MyObj *m;
	char *tmp;

	TEST(@"Allocating 4096 bytes",
	    (p = [obj allocMemoryWithSize: 4096]) != NULL)

	TEST(@"Freeing memory", R([obj freeMemory: p]))

	TEST(@"Allocating and freeing 4096 bytes 3 times",
	    (p = [obj allocMemoryWithSize: 4096]) != NULL &&
	    (q = [obj allocMemoryWithSize: 4096]) != NULL &&
	    (r = [obj allocMemoryWithSize: 4096]) != NULL &&
	    R([obj freeMemory: p]) && R([obj freeMemory: q]) &&
	    R([obj freeMemory: r]))

	tmp = [self allocMemoryWithSize: 1024];
	EXPECT_EXCEPTION(@"Detect freeing of memory not allocated by object",
	    OFMemoryNotPartOfObjectException, [obj freeMemory: tmp])

	EXPECT_EXCEPTION(@"Detect out of memory on alloc",
	    OFOutOfMemoryException, [obj allocMemoryWithSize: TOO_BIG])

	EXPECT_EXCEPTION(@"Detect out of memory on resize",
	    OFOutOfMemoryException,
	    {
		p = [obj allocMemoryWithSize: 1];
		[obj resizeMemory: p
			     size: TOO_BIG];
	    })
	[obj freeMemory: p];

	TEST(@"Allocate when trying to resize NULL",
	    (p = [obj resizeMemory: NULL
			      size: 1024]) != NULL)
	[obj freeMemory: p];

	EXPECT_EXCEPTION(@"Detect resizing of memory not allocated by object",
	    OFMemoryNotPartOfObjectException, [obj resizeMemory: tmp
							   size: 2048])
	[self freeMemory: tmp];

	TEST(@"+[description]",
	    [[OFObject description] isEqual: @"OFObject"] &&
	    [[MyObj description] isEqual: @"MyObj"])

	o = [[[OFObject alloc] init] autorelease];
	m = [[[MyObj alloc] init] autorelease];

	TEST(@"-[description]",
	    [[o description] isEqual: @"<OFObject>"] &&
	    [[m description] isEqual: @"<MyObj>"])

	[m setObjectValue: @"Hello"];
	[m setClassValue: [m class]];
	TEST(@"-[valueForKey:]",
	    [[m valueForKey: @"objectValue"] isEqual: @"Hello"] &&
	    [[m valueForKey: @"classValue"] isEqual: [m class]] &&
	    [[m valueForKey: @"class"] isEqual: [m class]])

	EXPECT_EXCEPTION(@"-[valueForKey:] with undefined key",
	    OFUndefinedKeyException, [m valueForKey: @"undefined"])

	TEST(@"-[setValue:forKey:]",
	    R([m setValue: @"World"
		   forKey: @"objectValue"]) &&
	    R([m setValue: [OFObject class]
		   forKey: @"classValue"]) &&
	    [[m objectValue] isEqual: @"World"] &&
	    [[m classValue] isEqual: [OFObject class]])

	EXPECT_EXCEPTION(@"-[setValue:forKey:] with undefined key",
	    OFUndefinedKeyException, [m setValue: @"x"
					  forKey: @"undefined"])

	[m setBoolValue: 1];
	[m setCharValue: 2];
	[m setShortValue: 3];
	[m setIntValue: 4];
	[m setLongValue: 5 ];
	[m setLongLongValue: 6];
	[m setUnsignedCharValue: 7];
	[m setUnsignedShortValue: 8];
	[m setUnsignedIntValue: 9];
	[m setUnsignedLongValue: 10];
	[m setUnsignedLongLongValue: 11];
	[m setFloatValue: 12];
	[m setDoubleValue: 13];
	TEST(@"Auto-wrapping of -[valueForKey:]",
	    [[m valueForKey: @"boolValue"] isEqual:
	    [OFNumber numberWithBool: 1]] &&
	    [[m valueForKey: @"charValue"] isEqual:
	    [OFNumber numberWithChar: 2]] &&
	    [[m valueForKey: @"shortValue"] isEqual:
	    [OFNumber numberWithShort: 3]] &&
	    [[m valueForKey: @"intValue"] isEqual:
	    [OFNumber numberWithInt: 4]] &&
	    [[m valueForKey: @"longValue"] isEqual:
	    [OFNumber numberWithLong: 5]] &&
	    [[m valueForKey: @"longLongValue"] isEqual:
	    [OFNumber numberWithLongLong: 6]] &&
	    [[m valueForKey: @"unsignedCharValue"] isEqual:
	    [OFNumber numberWithUnsignedChar: 7]] &&
	    [[m valueForKey: @"unsignedShortValue"] isEqual:
	    [OFNumber numberWithUnsignedShort: 8]] &&
	    [[m valueForKey: @"unsignedIntValue"] isEqual:
	    [OFNumber numberWithUnsignedInt: 9]] &&
	    [[m valueForKey: @"unsignedLongValue"] isEqual:
	    [OFNumber numberWithUnsignedLong: 10]] &&
	    [[m valueForKey: @"unsignedLongLongValue"] isEqual:
	    [OFNumber numberWithUnsignedLongLong: 11]] &&
	    [[m valueForKey: @"floatValue"] isEqual:
	    [OFNumber numberWithFloat: 12]] &&
	    [[m valueForKey: @"doubleValue"] isEqual:
	    [OFNumber numberWithDouble: 13]])

	TEST(@"Auto-wrapping of -[setValue:forKey:]",
	    R([m setValue: [OFNumber numberWithBool: 0]
		   forKey: @"boolValue"]) &&
	    R([m setValue: [OFNumber numberWithChar: 10]
		   forKey: @"charValue"]) &&
	    R([m setValue: [OFNumber numberWithShort: 20]
		   forKey: @"shortValue"]) &&
	    R([m setValue: [OFNumber numberWithInt: 30]
		   forKey: @"intValue"]) &&
	    R([m setValue: [OFNumber numberWithLong: 40]
		   forKey: @"longValue"]) &&
	    R([m setValue: [OFNumber numberWithLongLong: 50]
		   forKey: @"longLongValue"]) &&
	    R([m setValue: [OFNumber numberWithUnsignedChar: 60]
		   forKey: @"unsignedCharValue"]) &&
	    R([m setValue: [OFNumber numberWithUnsignedShort: 70]
		   forKey: @"unsignedShortValue"]) &&
	    R([m setValue: [OFNumber numberWithUnsignedInt: 80]
		   forKey: @"unsignedIntValue"]) &&
	    R([m setValue: [OFNumber numberWithUnsignedLong: 90]
		   forKey: @"unsignedLongValue"]) &&
	    R([m setValue: [OFNumber numberWithUnsignedLongLong: 100]
		   forKey: @"unsignedLongLongValue"]) &&
	    R([m setValue: [OFNumber numberWithFloat: 110]
		   forKey: @"floatValue"]) &&
	    R([m setValue: [OFNumber numberWithDouble: 120]
		   forKey: @"doubleValue"]) &&
	    [m isBoolValue] == 0 &&
	    [m charValue] == 10 &&
	    [m shortValue] == 20 &&
	    [m intValue] == 30 &&
	    [m longValue] == 40 &&
	    [m longLongValue] == 50 &&
	    [m unsignedCharValue] == 60 &&
	    [m unsignedShortValue] == 70 &&
	    [m unsignedIntValue] == 80 &&
	    [m unsignedLongValue] == 90 &&
	    [m unsignedLongLongValue] == 100 &&
	    [m floatValue] == 110 &&
	    [m doubleValue] == 120)

	EXPECT_EXCEPTION(@"Catch -[setValue:forKey:] with nil key for scalar",
	    OFInvalidArgumentException, [m setValue: nil
					     forKey: @"intValue"])

	[pool drain];
}
@end
