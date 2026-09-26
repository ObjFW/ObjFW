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

#import "OFX509Validity.h"
#import "OFASN1GeneralizedTime.h"
#import "OFASN1UTCTime.h"
#import "OFArray.h"
#import "OFDate.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

static OFDate *
X509UTCTimeToDate(OFASN1UTCTime *time)
{
	struct tm tm = {
		.tm_year = time.yearOfCentury +
		    (time.yearOfCentury < 50 ? 100 : 0),
		.tm_mon = time.month - 1,
		.tm_mday = time.dayOfMonth,
		.tm_hour = time.hour,
		.tm_min = time.minute,
		.tm_sec = time.second
	};

	return [OFDate dateWithStructTm: &tm];
}

@implementation OFX509Validity: OFASN1Sequence
@synthesize notBefore = _notBefore, notAfter = _notAfter;

- (instancetype)initWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					OFASN1Value *)) *)components
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithComponents: components
				tagClass: tagClass
			       tagNumber: tagNumber];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (components.count != 2)
			@throw [OFInvalidFormatException exception];

		OFEnumerator *enumerator = [components objectEnumerator];

		OF_KINDOF(OFASN1Value *) value = [enumerator nextObject];
		if ([value isKindOfClass: [OFASN1UTCTime class]])
			_notBefore = objc_retain(X509UTCTimeToDate(value));
		else if ([value isKindOfClass: [OFASN1GeneralizedTime class]]) {
			if ([value millisecond] > 0)
				@throw [OFInvalidFormatException exception];

			_notBefore = objc_retain([value dateValue]);
		} else
			@throw [OFInvalidFormatException exception];

		value = [enumerator nextObject];
		if ([value isKindOfClass: [OFASN1UTCTime class]])
			_notAfter = objc_retain(X509UTCTimeToDate(value));
		else if ([value isKindOfClass: [OFASN1GeneralizedTime class]]) {
			if ([value millisecond] > 0)
				@throw [OFInvalidFormatException exception];

			_notAfter = objc_retain([value dateValue]);
		} else
			@throw [OFInvalidFormatException exception];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_notBefore);
	objc_release(_notAfter);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]:\n"
	    @"\tNot before = %@\n"
	    @"\tNot after = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), _notBefore,
	    _notAfter];
}
@end
