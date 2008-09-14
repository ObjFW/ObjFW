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

#import <stdlib.h>
#import <string.h>
#import <wchar.h>
#import "OFWideString.h"
#import "OFExceptions.h"

@implementation OFWideString
+ new: (const wchar_t*)wstr
{
	return [[OFWideString alloc] init: wstr];
}

- init
{
	return [self init: NULL];
}

- init: (const wchar_t*)wstr
{
	if ((self = [super init])) {
		if (wstr == NULL) {
			length = 0;
			wstring = NULL;
		} else {
			length = wcslen(wstr);
			wstring = [self getMem: (length + 1) * sizeof(wchar_t)];
			memcpy(wstring, wstr, (length + 1) * sizeof(wchar_t));
		}
	}
	return self;
}

- (wchar_t*)wcString
{
	return wstring;
}

- (size_t)length
{
	return length;
}

- (OFWideString*)setTo: (const wchar_t*)wstr
{
	wchar_t *newstr;
	size_t  newlen;
	
	if (wstr == NULL) {
		[self freeMem:wstring];

		length = 0;
		wstring = NULL;

		return self;
	}

	newlen = wcslen(wstr);
	newstr = [self getMem: (newlen + 1) * sizeof(wchar_t)];
	memcpy(newstr, wstr, (newlen + 1) * sizeof(wchar_t));

	if (wstring != NULL)
		[self freeMem: wstring];

	length = newlen;
	wstring = newstr;

	return self;
}

- (OFWideString*)clone
{
	return [OFWideString new: wstring];
}

- (OFWideString*)append: (const wchar_t*)wstr
{
	wchar_t	*newstr;
	size_t	newlen, strlength;

	if (wstr == NULL)
		return [self setTo: wstr];

	strlength = wcslen(wstr);
	newlen = length + strlength;

	newstr = [self resizeMem: wstring
			  toSize: (newlen + 1) * sizeof(wchar_t)];

	memcpy(newstr + length, wstr, (strlength + 1) * sizeof(wchar_t));

	length = newlen;
	wstring = newstr;

	return self;
}
@end
