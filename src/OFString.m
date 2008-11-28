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

#import "config.h"

#import <stdlib.h>
#import <string.h>

#import <wchar.h>
#import <wctype.h>

#import "OFString.h"
#import "OFExceptions.h"

@implementation OFString
+ new
{
	return [[OFString alloc] init];
}

+ newFromCString: (const char*)str
{
	return [[OFString alloc] initFromCString: str];
}

+ newFromWideCString: (const wchar_t*)str
{
	return [[OFString alloc] initFromWideCString: str];
}

- init
{
	if ((self = [super init])) {
		length = 0;
		string = NULL;
	}

	return self;
}

- initFromCString: (const char*)str
{
	if ((self = [super init])) {
		if (str == NULL) {
			length = 0;
			string = NULL;
		} else {
			if ((length = mbstowcs(NULL, str, 0)) == (size_t)-1) {
				/* FIXME: Throw exception */
				[super free];
				return nil;
			}

			string = [self getMemForNItems: length + 1
						ofSize: sizeof(wchar_t)];

			if (mbstowcs(string, str, length + 1) != length) {
				[super free];
				return nil;
			}
		}
	}

	return self;
}

- initFromWideCString: (const wchar_t*)str
{
	if ((self = [super init])) {
		if (str == NULL) {
			length = 0;
			string = NULL;
		} else {
			length = wcslen(str);
			string = [self getMemForNItems: length + 1
						ofSize: sizeof(wchar_t)];
			wmemcpy(string, str, length + 1);
		}
	}

	return self;
}

- (char*)cString
{
	char *str;
	size_t len;

	if ((len = wcstombs(NULL, string, 0)) == (size_t)-1) {
		/* FIXME: Throw exception */
		return NULL;
	}

	str = [self getMemWithSize: len + 1];

	if (wcstombs(str, string, len + 1) != len) {
		/* FIXME: Throw exception */
		[self freeMem: str];
		return NULL;
	}

	return str;
}

- (wchar_t*)wideCString
{
	return string;
}

- (size_t)length
{
	return length;
}

- (OFString*)clone
{
	return [OFString newFromWideCString: string];
}

- (OFString*)setTo: (OFString*)str
{
	[self free];
	return (self = [str clone]);
}

- (int)compare: (OFString*)str
{
	return wcscmp(string, [str wideCString]);
}

- append: (OFString*)str
{
	return [self appendWideCString: [str wideCString]];
}

- appendCString: (const char*)str
{
	wchar_t	*newstr, *tmpstr;
	size_t	newlen, strlength;

	if (string == NULL) 
		return [self setTo: [OFString newFromCString: str]];

	if ((strlength = mbstowcs(NULL, str, 0)) == (size_t)-1) {
		/* FIXME: Throw exception */
		return nil;
	} 

	tmpstr = [self getMemForNItems: strlength + 1
				ofSize: sizeof(wchar_t)];

	if (mbstowcs(tmpstr, str, strlength) != strlength) {
		/* FIXME: Throw exception */
		[self freeMem: tmpstr];
		return nil;
	}

	newlen = length + strlength;
	newstr = [self resizeMem: string
			toNItems: newlen + 1
			  ofSize: sizeof(wchar_t)];

	wmemcpy(newstr + length, tmpstr, strlength + 1);

	length = newlen;
	string = newstr;

	[self freeMem: tmpstr];

	return self;
}

- appendWideCString: (const wchar_t*)str
{
	wchar_t	*newstr;
	size_t	newlen, strlength;

	if (string == NULL) 
		return [self setTo: [OFString newFromWideCString: str]];

	strlength = wcslen(str);
	newlen = length + strlength;

	newstr = [self resizeMem: string
			toNItems: newlen + 1
			  ofSize: sizeof(wchar_t)];

	wmemcpy(newstr + length, str, strlength + 1);

	length = newlen;
	string = newstr;

	return self;
}

- reverse
{
	size_t i, j, len = length / 2;

	for (i = 0, j = length - 1; i < len; i++, j--) {
		string[i] ^= string[j];
		string[j] ^= string[i];
		string[i] ^= string[j];
	}

	return self;
}

- upper
{
	size_t i = length;

	while (i--) 
		string[i] = towupper(string[i]);

	return self;
}

- lower
{
	size_t i = length;

	while (i--) 
		string[i] = towlower(string[i]);

	return self;
}
@end
