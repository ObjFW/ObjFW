/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "ObjFW.h"
#import "ObjFWTest.h"

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

@interface OFObjectTests: OTTestCase
{
	MyObject *_myObject;
}
@end

@implementation OFObjectTests
- (void)setUp
{
	[super setUp];

	_myObject = [[MyObject alloc] init];
}

- (void)dealloc
{
	[_myObject release];

	[super dealloc];
}

- (void)testClassDescription
{
	OTAssertEqualObjects([OFObject description], @"OFObject");
	OTAssertEqualObjects([MyObject description], @"MyObject");
}

- (void)testInstanceDescription
{
	OFObject *object = [[[OFObject alloc] init] autorelease];

	OTAssertEqualObjects(object.description, @"<OFObject>");
	OTAssertEqualObjects(_myObject.description, @"<MyObject>");
}

- (void)testValueForKey
{
	_myObject.objectValue = @"Hello";
	_myObject.classValue = _myObject.class;

	OTAssertEqualObjects([_myObject valueForKey: @"objectValue"], @"Hello");
	OTAssertEqualObjects([_myObject valueForKey: @"classValue"],
	    _myObject.class);
	OTAssertEqualObjects([_myObject valueForKey: @"class"],
	    _myObject.class);
}

- (void)testValueForKeyWithUndefinedKeyThrows
{
	OTAssertThrowsSpecific([_myObject valueForKey: @"undefined"],
	   OFUndefinedKeyException);
}

- (void)testSetValueForKey
{
	[_myObject setValue: @"World" forKey: @"objectValue"];
	[_myObject setValue: [OFObject class] forKey: @"classValue"];

	OTAssertEqualObjects(_myObject.objectValue, @"World");
	OTAssertEqualObjects(_myObject.classValue, [OFObject class]);
}

- (void)testSetValueWithUndefinedKeyThrows
{
	OTAssertThrowsSpecific([_myObject setValue: @"x" forKey: @"undefined"],
	    OFUndefinedKeyException);
}

- (void)testAutoWrappingOfValueForKey
{
	_myObject.boolValue = 1;
	_myObject.charValue = 2;
	_myObject.shortValue = 3;
	_myObject.intValue = 4;
	_myObject.longValue = 5;
	_myObject.longLongValue = 6;
	_myObject.unsignedCharValue = 7;
	_myObject.unsignedShortValue = 8;
	_myObject.unsignedIntValue = 9;
	_myObject.unsignedLongValue = 10;
	_myObject.unsignedLongLongValue = 11;
	_myObject.floatValue = 12;
	_myObject.doubleValue = 13;

	OTAssertEqualObjects([_myObject valueForKey: @"boolValue"],
	    [OFNumber numberWithBool: 1]);
	OTAssertEqualObjects([_myObject valueForKey: @"charValue"],
	    [OFNumber numberWithChar: 2]);
	OTAssertEqualObjects([_myObject valueForKey: @"shortValue"],
	    [OFNumber numberWithShort: 3]);
	OTAssertEqualObjects([_myObject valueForKey: @"intValue"],
	    [OFNumber numberWithInt: 4]);
	OTAssertEqualObjects([_myObject valueForKey: @"longValue"],
	    [OFNumber numberWithLong: 5]);
	OTAssertEqualObjects([_myObject valueForKey: @"longLongValue"],
	    [OFNumber numberWithLongLong: 6]);
	OTAssertEqualObjects([_myObject valueForKey: @"unsignedCharValue"],
	    [OFNumber numberWithUnsignedChar: 7]);
	OTAssertEqualObjects([_myObject valueForKey: @"unsignedShortValue"],
	    [OFNumber numberWithUnsignedShort: 8]);
	OTAssertEqualObjects([_myObject valueForKey: @"unsignedIntValue"],
	    [OFNumber numberWithUnsignedInt: 9]);
	OTAssertEqualObjects([_myObject valueForKey: @"unsignedLongValue"],
	    [OFNumber numberWithUnsignedLong: 10]);
	OTAssertEqualObjects([_myObject valueForKey: @"unsignedLongLongValue"],
	    [OFNumber numberWithUnsignedLongLong: 11]);
	OTAssertEqualObjects([_myObject valueForKey: @"floatValue"],
	    [OFNumber numberWithFloat: 12]);
	OTAssertEqualObjects([_myObject valueForKey: @"doubleValue"],
	    [OFNumber numberWithDouble: 13]);
}

- (void)testAutoWrappingOfSetValueForKey
{
	[_myObject setValue: [OFNumber numberWithBool: 0]
		     forKey: @"boolValue"];
	[_myObject setValue: [OFNumber numberWithChar: 10]
		     forKey: @"charValue"];
	[_myObject setValue: [OFNumber numberWithShort: 20]
		     forKey: @"shortValue"];
	[_myObject setValue: [OFNumber numberWithInt: 30]
		     forKey: @"intValue"];
	[_myObject setValue: [OFNumber numberWithLong: 40]
		     forKey: @"longValue"];
	[_myObject setValue: [OFNumber numberWithLongLong: 50]
		     forKey: @"longLongValue"];
	[_myObject setValue: [OFNumber numberWithUnsignedChar: 60]
		     forKey: @"unsignedCharValue"];
	[_myObject setValue: [OFNumber numberWithUnsignedShort: 70]
		     forKey: @"unsignedShortValue"];
	[_myObject setValue: [OFNumber numberWithUnsignedInt: 80]
		     forKey: @"unsignedIntValue"];
	[_myObject setValue: [OFNumber numberWithUnsignedLong: 90]
		     forKey: @"unsignedLongValue"];
	[_myObject setValue: [OFNumber numberWithUnsignedLongLong: 100]
		     forKey: @"unsignedLongLongValue"];
	[_myObject setValue: [OFNumber numberWithFloat: 110]
		     forKey: @"floatValue"];
	[_myObject setValue: [OFNumber numberWithDouble: 120]
		     forKey: @"doubleValue"];

	OTAssertEqual(_myObject.isBoolValue, 0);
	OTAssertEqual(_myObject.charValue, 10);
	OTAssertEqual(_myObject.shortValue, 20);
	OTAssertEqual(_myObject.intValue, 30);
	OTAssertEqual(_myObject.longValue, 40);
	OTAssertEqual(_myObject.longLongValue, 50);
	OTAssertEqual(_myObject.unsignedCharValue, 60);
	OTAssertEqual(_myObject.unsignedShortValue, 70);
	OTAssertEqual(_myObject.unsignedIntValue, 80);
	OTAssertEqual(_myObject.unsignedLongValue, 90);
	OTAssertEqual(_myObject.unsignedLongLongValue, 100);
	OTAssertEqual(_myObject.floatValue, 110);
	OTAssertEqual(_myObject.doubleValue, 120);
}

- (void)testSetValueForKeyWithNilThrows
{
	OTAssertThrowsSpecific(
	    [_myObject setValue: (id _Nonnull)nil forKey: @"intValue"],
	    OFInvalidArgumentException);
}

- (void)testValueForKeyPath
{
	_myObject.objectValue = [[[MyObject alloc] init] autorelease];
	[_myObject.objectValue setObjectValue:
	    [[[MyObject alloc] init] autorelease]];
	[[_myObject.objectValue objectValue] setDoubleValue: 0.5];

	OTAssertEqual([[_myObject valueForKeyPath:
	    @"objectValue.objectValue.doubleValue"] doubleValue], 0.5);
}

- (void)testSetValueForKeyPath
{
	_myObject.objectValue = [[[MyObject alloc] init] autorelease];
	[_myObject.objectValue setObjectValue:
	    [[[MyObject alloc] init] autorelease]];
	[_myObject setValue: [OFNumber numberWithDouble: 0.75]
		 forKeyPath: @"objectValue.objectValue.doubleValue"];

	OTAssertEqual([[_myObject.objectValue objectValue] doubleValue], 0.75);
}
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
