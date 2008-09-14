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
			if ((wstring =
			    [self getMem: length * sizeof(wchar_t)]) == NULL)
				return NULL;
			memcpy(wstring, wstr, length * sizeof(wchar_t));
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
	if ((newstr = [self getMem: newlen * sizeof(wchar_t)]) == NULL)
		return nil;
	memcpy(newstr, wstr, newlen * sizeof(wchar_t));

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

	/* FIXME: Add error handling */
	if ((newstr = [self resizeMem: wstring
			       toSize: newlen  * sizeof(wchar_t) + 2]) == NULL)
		return nil;

	wstring = newstr;

	memcpy(wstring + length * sizeof(wchar_t), wstr,
	    strlength * sizeof(wchar_t));
	wstring[newlen] = '\0';

	length = newlen;

	return self;
}
@end
