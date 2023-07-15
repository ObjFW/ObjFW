/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

#if (defined(OF_DRAGONFLYBSD) && defined(__LP64__)) || defined(OF_NINTENDO_3DS)
# define TOO_BIG (SIZE_MAX / 3)
#else
# define TOO_BIG (SIZE_MAX - 128)
#endif

static OFString *const module = @"OFObject";

@interface MyObject: OFObject
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

@implementation MyObject
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
	void *pool = objc_autoreleasePoolPush();
	OFObject *object;
	MyObject *myObject;

	TEST(@"+[description]",
	    [[OFObject description] isEqual: @"OFObject"] &&
	    [[MyObject description] isEqual: @"MyObject"])

	object = [[[OFObject alloc] init] autorelease];
	myObject = [[[MyObject alloc] init] autorelease];

	TEST(@"-[description]",
	    [object.description isEqual: @"<OFObject>"] &&
	    [myObject.description isEqual: @"<MyObject>"])

	myObject.objectValue = @"Hello";
	myObject.classValue = myObject.class;
	TEST(@"-[valueForKey:]",
	    [[myObject valueForKey: @"objectValue"] isEqual: @"Hello"] &&
	    [[myObject valueForKey: @"classValue"] isEqual: myObject.class] &&
	    [[myObject valueForKey: @"class"] isEqual: myObject.class])

	EXPECT_EXCEPTION(@"-[valueForKey:] with undefined key",
	    OFUndefinedKeyException, [myObject valueForKey: @"undefined"])

	TEST(@"-[setValue:forKey:]",
	    R([myObject setValue: @"World" forKey: @"objectValue"]) &&
	    R([myObject setValue: [OFObject class] forKey: @"classValue"]) &&
	    [myObject.objectValue isEqual: @"World"] &&
	    [myObject.classValue isEqual: [OFObject class]])

	EXPECT_EXCEPTION(@"-[setValue:forKey:] with undefined key",
	    OFUndefinedKeyException,
	    [myObject setValue: @"x" forKey: @"undefined"])

	myObject.boolValue = 1;
	myObject.charValue = 2;
	myObject.shortValue = 3;
	myObject.intValue = 4;
	myObject.longValue = 5;
	myObject.longLongValue = 6;
	myObject.unsignedCharValue = 7;
	myObject.unsignedShortValue = 8;
	myObject.unsignedIntValue = 9;
	myObject.unsignedLongValue = 10;
	myObject.unsignedLongLongValue = 11;
	myObject.floatValue = 12;
	myObject.doubleValue = 13;
	TEST(@"Auto-wrapping of -[valueForKey:]",
	    [[myObject valueForKey: @"boolValue"] isEqual:
	    [OFNumber numberWithBool: 1]] &&
	    [[myObject valueForKey: @"charValue"] isEqual:
	    [OFNumber numberWithChar: 2]] &&
	    [[myObject valueForKey: @"shortValue"] isEqual:
	    [OFNumber numberWithShort: 3]] &&
	    [[myObject valueForKey: @"intValue"] isEqual:
	    [OFNumber numberWithInt: 4]] &&
	    [[myObject valueForKey: @"longValue"] isEqual:
	    [OFNumber numberWithLong: 5]] &&
	    [[myObject valueForKey: @"longLongValue"] isEqual:
	    [OFNumber numberWithLongLong: 6]] &&
	    [[myObject valueForKey: @"unsignedCharValue"] isEqual:
	    [OFNumber numberWithUnsignedChar: 7]] &&
	    [[myObject valueForKey: @"unsignedShortValue"] isEqual:
	    [OFNumber numberWithUnsignedShort: 8]] &&
	    [[myObject valueForKey: @"unsignedIntValue"] isEqual:
	    [OFNumber numberWithUnsignedInt: 9]] &&
	    [[myObject valueForKey: @"unsignedLongValue"] isEqual:
	    [OFNumber numberWithUnsignedLong: 10]] &&
	    [[myObject valueForKey: @"unsignedLongLongValue"] isEqual:
	    [OFNumber numberWithUnsignedLongLong: 11]] &&
	    [[myObject valueForKey: @"floatValue"] isEqual:
	    [OFNumber numberWithFloat: 12]] &&
	    [[myObject valueForKey: @"doubleValue"] isEqual:
	    [OFNumber numberWithDouble: 13]])

	TEST(@"Auto-wrapping of -[setValue:forKey:]",
	    R([myObject setValue: [OFNumber numberWithBool: 0]
			  forKey: @"boolValue"]) &&
	    R([myObject setValue: [OFNumber numberWithChar: 10]
			  forKey: @"charValue"]) &&
	    R([myObject setValue: [OFNumber numberWithShort: 20]
			  forKey: @"shortValue"]) &&
	    R([myObject setValue: [OFNumber numberWithInt: 30]
			  forKey: @"intValue"]) &&
	    R([myObject setValue: [OFNumber numberWithLong: 40]
			  forKey: @"longValue"]) &&
	    R([myObject setValue: [OFNumber numberWithLongLong: 50]
			  forKey: @"longLongValue"]) &&
	    R([myObject setValue: [OFNumber numberWithUnsignedChar: 60]
			  forKey: @"unsignedCharValue"]) &&
	    R([myObject setValue: [OFNumber numberWithUnsignedShort: 70]
			  forKey: @"unsignedShortValue"]) &&
	    R([myObject setValue: [OFNumber numberWithUnsignedInt: 80]
			  forKey: @"unsignedIntValue"]) &&
	    R([myObject setValue: [OFNumber numberWithUnsignedLong: 90]
			  forKey: @"unsignedLongValue"]) &&
	    R([myObject setValue: [OFNumber numberWithUnsignedLongLong: 100]
			  forKey: @"unsignedLongLongValue"]) &&
	    R([myObject setValue: [OFNumber numberWithFloat: 110]
			  forKey: @"floatValue"]) &&
	    R([myObject setValue: [OFNumber numberWithDouble: 120]
			  forKey: @"doubleValue"]) &&
	    myObject.isBoolValue == 0 && myObject.charValue == 10 &&
	    myObject.shortValue == 20 && myObject.intValue == 30 &&
	    myObject.longValue == 40 && myObject.longLongValue == 50 &&
	    myObject.unsignedCharValue == 60 &&
	    myObject.unsignedShortValue == 70 &&
	    myObject.unsignedIntValue == 80 &&
	    myObject.unsignedLongValue == 90 &&
	    myObject.unsignedLongLongValue == 100 &&
	    myObject.floatValue == 110 &&
	    myObject.doubleValue == 120)

	EXPECT_EXCEPTION(@"Catch -[setValue:forKey:] with nil key for scalar",
	    OFInvalidArgumentException,
	    [myObject setValue: (id _Nonnull)nil forKey: @"intValue"])

	TEST(@"-[valueForKeyPath:]",
	    (myObject = [[[MyObject alloc] init] autorelease]) &&
	    (myObject.objectValue = [[[MyObject alloc] init] autorelease]) &&
	    R([myObject.objectValue
	    setObjectValue: [[[MyObject alloc] init] autorelease]]) &&
	    R([[myObject.objectValue objectValue] setDoubleValue: 0.5]) &&
	    [[myObject valueForKeyPath: @"objectValue.objectValue.doubleValue"]
	    doubleValue] == 0.5)

	TEST(@"[-setValue:forKeyPath:]",
	    R([myObject setValue: [OFNumber numberWithDouble: 0.75]
		      forKeyPath: @"objectValue.objectValue.doubleValue"]) &&
	    [[myObject.objectValue objectValue] doubleValue] == 0.75)

	objc_autoreleasePoolPop(pool);
}
@end
