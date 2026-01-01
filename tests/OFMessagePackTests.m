/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <string.h>

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFMessagePackTests: OTTestCase
@end

const char *smallDictionaryRepresentation =
    "\xDE\x00\x10\x00\x01\x01\x02\x02\x03\x03\x04\x04\x05\x05\x06\x06"
    "\x07\x07\x08\x08\x09\x09\x0A\x0A\x0B\x0B\x0C\x0C\x0D\x0D\x0E\x0E"
    "\x0F\x0F\x10";

@implementation OFMessagePackTests
- (void)testMessagePackRepresentationForNull
{
	OTAssertEqualObjects([[OFNull null] messagePackRepresentation],
	    [OFData dataWithItems: "\xC0" count: 1]);
}

- (void)testObjectByParsingMessagePackForNull
{
	OTAssertEqualObjects([[OFData dataWithItems: "\xC0" count: 1]
	    objectByParsingMessagePack], [OFNull null]);
}

- (void)testMessagePackRepresentationForNumber
{
	OTAssertEqualObjects([[OFNumber numberWithChar: -30]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xE2" count: 1]);

	OTAssertEqualObjects([[OFNumber numberWithChar: -33]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xD0\xDF" count: 2]);

	OTAssertEqualObjects([[OFNumber numberWithUnsignedChar: 127]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\x7F" count: 1]);

	OTAssertEqualObjects([[OFNumber numberWithUnsignedChar: 128]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCC\x80" count: 2]);

	OTAssertEqualObjects([[OFNumber numberWithShort: -129]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xD1\xFF\x7F" count: 3]);

	OTAssertEqualObjects([[OFNumber numberWithUnsignedShort: 256]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCD\x01\x00" count: 3]);

	OTAssertEqualObjects([[OFNumber numberWithLong: -32769]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xD2\xFF\xFF\x7F\xFF" count: 5]);

	OTAssertEqualObjects([[OFNumber numberWithUnsignedLong: 65536]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCE\x00\x01\x00\x00" count: 5]);

	OTAssertEqualObjects([[OFNumber numberWithLongLong: -2147483649]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xD3\xFF\xFF\xFF\xFF\x7F\xFF\xFF\xFF"
			    count: 9]);

	OTAssertEqualObjects([[OFNumber numberWithUnsignedLongLong: 4294967296]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCF\x00\x00\x00\x01\x00\x00\x00\x00"
			    count: 9]);

	OTAssertEqualObjects([[OFNumber numberWithFloat: 1.25f]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCA\x3F\xA0\x00\x00" count: 5]);

	OTAssertEqualObjects([[OFNumber numberWithDouble: 1.25]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCB\x3F\xF4\x00\x00\x00\x00\x00\x00"
			    count: 9]);

	OTAssertEqualObjects(
	    [[OFNumber numberWithBool: true] messagePackRepresentation],
	    [OFData dataWithItems: "\xC3" count: 1]);

	OTAssertEqualObjects(
	    [[OFNumber numberWithBool: false] messagePackRepresentation],
	    [OFData dataWithItems: "\xC2" count: 1]);
}

- (void)testObjectByParsingMessagePackForNumber
{
	OTAssertEqualObjects([[OFData dataWithItems: "\xE2" count: 1]
	    objectByParsingMessagePack],
	    [OFNumber numberWithChar: -30]);

	OTAssertEqualObjects([[OFData dataWithItems: "\xD0\xDF" count: 2]
	    objectByParsingMessagePack],
	    [OFNumber numberWithChar: -33]);

	OTAssertEqualObjects([[OFData dataWithItems: "\x7F" count: 1]
	    objectByParsingMessagePack],
	    [OFNumber numberWithUnsignedChar: 127]);

	OTAssertEqualObjects([[OFData dataWithItems: "\xCC\x80" count: 2]
	    objectByParsingMessagePack],
	    [OFNumber numberWithUnsignedChar: 128]);

	OTAssertEqualObjects([[OFData dataWithItems: "\xD1\xFF\x7F" count: 3]
	    objectByParsingMessagePack],
	    [OFNumber numberWithShort: -129]);

	OTAssertEqualObjects([[OFData dataWithItems: "\xCD\x01\x00" count: 3]
	    objectByParsingMessagePack],
	    [OFNumber numberWithUnsignedShort: 256]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xD2\xFF\xFF\x7F\xFF"
			     count: 5] objectByParsingMessagePack],
	    [OFNumber numberWithLong: -32769]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xCE\x00\x01\x00\x00"
			     count: 5] objectByParsingMessagePack],
	    [OFNumber numberWithUnsignedLong: 65536]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xD3\xFF\xFF\xFF\xFF\x7F\xFF\xFF\xFF"
			     count: 9] objectByParsingMessagePack],
	    [OFNumber numberWithLongLong: -2147483649]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xCF\x00\x00\x00\x01\x00\x00\x00\x00"
			     count: 9] objectByParsingMessagePack],
	    [OFNumber numberWithUnsignedLongLong: 4294967296]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xCA\x3F\xA0\x00\x00"
			     count: 5] objectByParsingMessagePack],
	    [OFNumber numberWithFloat: 1.25f]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xCB\x3F\xF4\x00\x00\x00\x00\x00\x00"
			     count: 9] objectByParsingMessagePack],
	    [OFNumber numberWithDouble: 1.25]);

	OTAssertEqualObjects([[OFData dataWithItems: "\xC3" count: 1]
	    objectByParsingMessagePack],
	    [OFNumber numberWithBool: true]);

	OTAssertEqualObjects([[OFData dataWithItems: "\xC2" count: 1]
	    objectByParsingMessagePack],
	    [OFNumber numberWithBool: false]);
}

static void
generateStringAndData(OFString **string, OFMutableData **data, size_t length,
    const char *dataPrefix, size_t dataPrefixLength)
{
	*data = [OFMutableData dataWithCapacity: length + dataPrefixLength];
	[*data addItems: dataPrefix count: dataPrefixLength];
	[*data increaseCountBy: length];
	memset([*data mutableItemAtIndex: dataPrefixLength], 'x', length);

	*string = [OFString
	    stringWithUTF8String: [*data itemAtIndex: dataPrefixLength]
			  length: length];
}

- (void)testMessagePackRepresentationForString
{
	OFString *string;
	OFMutableData *data;

	OTAssertEqualObjects(@"x".messagePackRepresentation,
	    [OFData dataWithItems: "\xA1x" count: 2]);

	generateStringAndData(&string, &data, 32, "\xD9\x20", 2);
	OTAssertEqualObjects(string.messagePackRepresentation, data);

	generateStringAndData(&string, &data, 256, "\xDA\x01\x00", 3);
	OTAssertEqualObjects(string.messagePackRepresentation, data);

	generateStringAndData(&string, &data, 65536, "\xDB\x00\x01\x00\x00", 5);
	OTAssertEqualObjects(string.messagePackRepresentation, data);
}

- (void)testObjectByParsingMessagePackForString
{
	OFString *string;
	OFMutableData *data;

	OTAssertEqualObjects([[OFData dataWithItems: "\xA1x" count: 2]
	    objectByParsingMessagePack], @"x");

	generateStringAndData(&string, &data, 32, "\xD9\x20", 2);
	OTAssertEqualObjects(data.objectByParsingMessagePack, string);

	generateStringAndData(&string, &data, 256, "\xDA\x01\x00", 3);
	OTAssertEqualObjects(data.objectByParsingMessagePack, string);

	generateStringAndData(&string, &data, 65536, "\xDB\x00\x01\x00\x00", 5);
	OTAssertEqualObjects(data.objectByParsingMessagePack, string);
}

- (void)testMessagePackRepresentationForData
{
	OFMutableData *data;

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "x" count: 1] messagePackRepresentation],
	    [OFData dataWithItems: "\xC4\x01x" count: 3]);

	data = [OFMutableData data];
	[data addItems: "\xC5\x01\x00" count: 3];
	[data increaseCountBy: 256];
	memset([data mutableItemAtIndex: 3], 'x', 256);
	OTAssertEqualObjects([[data subdataWithRange: OFMakeRange(3, 256)]
	    messagePackRepresentation], data);

	data = [OFMutableData data];
	[data addItems: "\xC6\x00\x01\x00\x00" count: 5];
	[data increaseCountBy: 65536];
	memset([data mutableItemAtIndex: 5], 'x', 65536);
	OTAssertEqualObjects([[data subdataWithRange: OFMakeRange(5, 65536)]
	    messagePackRepresentation], data);
}

- (void)testObjectByParsingMessagePackForData
{
	OFMutableData *data;

	OTAssertEqualObjects([[OFData dataWithItems: "\xC4\x01x" count: 3]
	    objectByParsingMessagePack],
	    [OFData dataWithItems: "x" count: 1]);

	data = [OFMutableData data];
	[data addItems: "\xC5\x01\x00" count: 3];
	[data increaseCountBy: 256];
	memset([data mutableItemAtIndex: 3], 'x', 256);
	OTAssertEqualObjects(data.objectByParsingMessagePack,
	    [data subdataWithRange: OFMakeRange(3, 256)]);

	data = [OFMutableData data];
	[data addItems: "\xC6\x00\x01\x00\x00" count: 5];
	[data increaseCountBy: 65536];
	memset([data mutableItemAtIndex: 5], 'x', 65536);
	OTAssertEqualObjects(data.objectByParsingMessagePack,
	    [data subdataWithRange: OFMakeRange(5, 65536)]);
}

- (void)testMessagePackRepresentationForArray
{
	OFMutableArray *array = [OFMutableArray arrayWithCapacity: 65536];
	OFNumber *number = [OFNumber numberWithUnsignedInt: 1];
	OFMutableData *data;

	OTAssertEqualObjects([[OFArray array] messagePackRepresentation],
	    [OFData dataWithItems: "\x90" count: 1]);

	OTAssertEqualObjects(
	    [[OFArray arrayWithObject: number] messagePackRepresentation],
	    [OFData dataWithItems: "\x91\x01" count: 2]);

	data = [OFMutableData dataWithCapacity: 19];
	[data addItems: "\xDC\x00\x10" count: 3];
	[data increaseCountBy: 16];
	memset([data mutableItemAtIndex: 3], '\x01', 16);
	for (size_t i = 0; i < 16; i++)
		[array addObject: number];
	OTAssertEqualObjects(array.messagePackRepresentation, data);

	data = [OFMutableData dataWithCapacity: 65541];
	[data addItems: "\xDD\x00\x01\x00\x00" count: 5];
	[data increaseCountBy: 65536];
	memset([data mutableItemAtIndex: 5], '\x01', 65536);
	for (size_t i = 16; i < 65536; i++)
		[array addObject: number];
	OTAssertEqualObjects(array.messagePackRepresentation, data);
}

- (void)testObjectByParsingMessagePackForArray
{
	OFMutableArray *array = [OFMutableArray arrayWithCapacity: 65536];
	OFNumber *number = [OFNumber numberWithUnsignedInt: 1];
	OFMutableData *data;

	OTAssertEqualObjects([[OFData dataWithItems: "\x90" count: 1]
	    objectByParsingMessagePack], [OFArray array]);

	OTAssertEqualObjects([[OFData dataWithItems: "\x91\x01" count: 2]
	    objectByParsingMessagePack],
	    [OFArray arrayWithObject: number]);

	data = [OFMutableData dataWithCapacity: 19];
	[data addItems: "\xDC\x00\x10" count: 3];
	[data increaseCountBy: 16];
	memset([data mutableItemAtIndex: 3], '\x01', 16);
	for (size_t i = 0; i < 16; i++)
		[array addObject: number];
	OTAssertEqualObjects(data.objectByParsingMessagePack, array);

	data = [OFMutableData dataWithCapacity: 65541];
	[data addItems: "\xDD\x00\x01\x00\x00" count: 5];
	[data increaseCountBy: 65536];
	memset([data mutableItemAtIndex: 5], '\x01', 65536);
	for (size_t i = 16; i < 65536; i++)
		[array addObject: number];
	OTAssertEqualObjects(data.objectByParsingMessagePack, array);
}

- (void)testMessagePackRepresentationForDictionary
{
	OFMutableArray *keys = [OFMutableArray arrayWithCapacity: 65536];
	OFMutableArray *objects = [OFMutableArray arrayWithCapacity: 65536];

	OTAssertEqualObjects([[OFDictionary dictionary]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\x80" count: 1]);

	OTAssertEqualObjects([[OFDictionary
	    dictionaryWithObject: [OFNumber numberWithUnsignedInt: 2]
			  forKey: [OFNumber numberWithUnsignedInt: 1]]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\x81\x01\x02" count: 3]);

	for (unsigned int i = 0; i < 16; i++) {
		[keys addObject: [OFNumber numberWithUnsignedInt: i]];
		[objects addObject: [OFNumber numberWithUnsignedInt: i + 1]];
	}
	OTAssertEqualObjects([[OTOrderedDictionary
	    dictionaryWithObjects: objects.objects
			  forKeys: keys.objects
			    count: 16] messagePackRepresentation],
	    [OFData dataWithItems: smallDictionaryRepresentation count: 35]);

	for (unsigned int i = 16; i < 65536; i++) {
		[keys addObject: [OFNumber numberWithUnsignedInt: i]];
		[objects addObject: [OFNumber numberWithUnsignedInt: i + 1]];
	}
	OTAssertEqualObjects([[OTOrderedDictionary
	    dictionaryWithObjects: objects.objects
			  forKeys: keys.objects
			    count: 65536] messagePackRepresentation],
	    [OFData dataWithContentsOfIRI:
	    [OFIRI IRIWithString: @"gzip:embedded:big_dictionary.msgpack.gz"]]);
}

- (void)testObjectByParsingMessagePackForDictionary
{
	OFMutableDictionary *dictionary =
	    [OFMutableDictionary dictionaryWithCapacity: 65536];

	OTAssertEqualObjects([[OFData dataWithItems: "\x80" count: 1]
	    objectByParsingMessagePack], [OFDictionary dictionary]);

	OTAssertEqualObjects([[OFData dataWithItems: "\x81\x01\x02" count: 3]
	    objectByParsingMessagePack],
	    [OFDictionary
	    dictionaryWithObject: [OFNumber numberWithUnsignedInt: 2]
			  forKey: [OFNumber numberWithUnsignedInt: 1]]);

	for (unsigned int i = 0; i < 16; i++)
		[dictionary setObject: [OFNumber numberWithUnsignedInt: i + 1]
			       forKey: [OFNumber numberWithUnsignedInt: i]];
	OTAssertEqualObjects(
	    [[OFData dataWithItems: smallDictionaryRepresentation
			     count: 35] objectByParsingMessagePack],
	    dictionary);

	for (unsigned int i = 16; i < 65536; i++)
		[dictionary setObject: [OFNumber numberWithUnsignedInt: i + 1]
			       forKey: [OFNumber numberWithUnsignedInt: i]];
	OTAssertEqualObjects(dictionary,
	    [[OFData dataWithContentsOfIRI:
	    [OFIRI IRIWithString: @"gzip:embedded:big_dictionary.msgpack.gz"]]
	    objectByParsingMessagePack]);
}

- (void)testMessagePackRepresentationForExtension
{
	OFMessagePackExtension *extension;
	OFMutableData *data;

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "x" count: 1]];
	OTAssertEqualObjects(extension.messagePackRepresentation,
	    [OFData dataWithItems: "\xD4\x01x" count: 3]);

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "xy" count: 2]];
	OTAssertEqualObjects(extension.messagePackRepresentation,
	    [OFData dataWithItems: "\xD5\x01xy" count: 4]);

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "abcd" count: 4]];
	OTAssertEqualObjects(extension.messagePackRepresentation,
	    [OFData dataWithItems: "\xD6\x01" "abcd" count: 6]);

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "12345678" count: 8]];
	OTAssertEqualObjects(extension.messagePackRepresentation,
	    [OFData dataWithItems: "\xD7\x01" "12345678" count: 10]);

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "12345678ABCDEFGH"
					       count: 16]];
	OTAssertEqualObjects(extension.messagePackRepresentation,
	    [OFData dataWithItems: "\xD8\x01" "12345678ABCDEFGH" count: 18]);

	extension = [OFMessagePackExtension extensionWithType: 1
							 data: [OFData data]];
	OTAssertEqualObjects(extension.messagePackRepresentation,
	    [OFData dataWithItems: "\xC7\x00\x01" count: 3]);

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "abc" count: 3]];
	OTAssertEqualObjects(extension.messagePackRepresentation,
	    [OFData dataWithItems: "\xC7\x03\x01" "abc" count: 6]);

	data = [OFMutableData dataWithCapacity: 260];
	[data addItems: "\xC8\x01\x00\x01" count: 4];
	[data increaseCountBy: 256];
	memset([data mutableItemAtIndex: 4], 'x', 256);
	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [data subdataWithRange: OFMakeRange(4, 256)]];
	OTAssertEqualObjects(extension.messagePackRepresentation, data);

	data = [OFMutableData dataWithCapacity: 65542];
	[data addItems: "\xC9\x00\x01\x00\x00\x01" count: 6];
	[data increaseCountBy: 65536];
	memset([data mutableItemAtIndex: 6], 'x', 65536);
	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [data subdataWithRange: OFMakeRange(6, 65536)]];
	OTAssertEqualObjects(extension.messagePackRepresentation, data);
}

- (void)testObjectByParsingMessagePackForExtension
{
	OFMessagePackExtension *extension;
	OFMutableData *data;

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "x" count: 1]];
	OTAssertEqualObjects([[OFData dataWithItems: "\xD4\x01x" count: 3]
	    objectByParsingMessagePack], extension);

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "xy" count: 2]];
	OTAssertEqualObjects([[OFData dataWithItems: "\xD5\x01xy" count: 4]
	    objectByParsingMessagePack], extension);

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "abcd" count: 4]];
	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xD6\x01" "abcd"
			     count: 6] objectByParsingMessagePack],
	    extension);

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "12345678" count: 8]];
	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xD7\x01" "12345678"
			     count: 10] objectByParsingMessagePack],
	    extension);

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "12345678ABCDEFGH"
					       count: 16]];
	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xD8\x01" "12345678ABCDEFGH"
			     count: 18] objectByParsingMessagePack],
	    extension);

	extension = [OFMessagePackExtension extensionWithType: 1
							 data: [OFData data]];
	OTAssertEqualObjects([[OFData dataWithItems: "\xC7\x00\x01" count: 3]
	    objectByParsingMessagePack], extension);

	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [OFData dataWithItems: "abc" count: 3]];
	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xC7\x03\x01" "abc"
			     count: 6] objectByParsingMessagePack],
	    extension);

	data = [OFMutableData dataWithCapacity: 260];
	[data addItems: "\xC8\x01\x00\x01" count: 4];
	[data increaseCountBy: 256];
	memset([data mutableItemAtIndex: 4], 'x', 256);
	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [data subdataWithRange: OFMakeRange(4, 256)]];
	OTAssertEqualObjects(data.objectByParsingMessagePack, extension);

	data = [OFMutableData dataWithCapacity: 65542];
	[data addItems: "\xC9\x00\x01\x00\x00\x01" count: 6];
	[data increaseCountBy: 65536];
	memset([data mutableItemAtIndex: 6], 'x', 65536);
	extension = [OFMessagePackExtension
	    extensionWithType: 1
			 data: [data subdataWithRange: OFMakeRange(6, 65536)]];
	OTAssertEqualObjects(data.objectByParsingMessagePack, extension);
}

- (void)testMessagePackRepresentationForDate
{
	OTAssertEqualObjects([[OFDate dateWithTimeIntervalSince1970: 1]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xD6\xFF\x00\x00\x00\x01" count: 6]);

	OTAssertEqualObjects([[OFDate dateWithTimeIntervalSince1970: 1.25]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xD7\xFF\x3B\x9A\xCA\x00\x00\x00\x00\x01"
			    count: 10]);

	OTAssertEqualObjects(
	    [[OFDate dateWithTimeIntervalSince1970: 0x400000000 + 0.25]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xC7\x0C\xFF\x0E\xE6\xB2\x80\x00\x00\x00"
				   "\x04\x00\x00\x00\x00"
			    count: 15]);
}

- (void)testObjectByParsingMessagePackForDate
{
	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xD6\xFF\x00\x00\x00\x01"
			     count: 6] objectByParsingMessagePack],
	    [OFDate dateWithTimeIntervalSince1970: 1]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xD7\xFF\x3B\x9A\xCA\x00\x00\x00\x00\x01"
			     count: 10] objectByParsingMessagePack],
	    [OFDate dateWithTimeIntervalSince1970: 1.25]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xC7\x0C\xFF\x0E\xE6\xB2\x80\x00\x00\x00"
				    "\x04\x00\x00\x00\x00"
			     count: 15] objectByParsingMessagePack],
	    [OFDate dateWithTimeIntervalSince1970: 0x400000000 + 0.25]);
}
@end
