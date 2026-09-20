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

#import "OFPEMParser.h"
#import "OFData.h"
#import "OFStream.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

void
OFParsePEM(OFStream *stream, void (*callback)(OFString *, OFData *, void *ctx),
    void *ctx)
{
	OFString *section = nil;
	OFMutableString *string = nil;

	OFString *line;
	while ((line = [stream readLine]) != nil) {
		if (section != nil) {
			if ([line hasPrefix: @"-----END "]) {
				if (![line hasSuffix: @"-----"])
					@throw [OFInvalidFormatException
					    exception];

				if (![[line substringWithRange:
				    OFMakeRange(9, line.length - 9 - 5)]
				    isEqual: section])
					@throw [OFInvalidFormatException
					    exception];

				OFData *data = [OFData
				    dataWithBase64EncodedString: string];
				callback(section, data, ctx);

				section = nil;
				string = nil;

				continue;
			}

			[string appendString: line];
		} else {
			if ([line hasPrefix: @"-----BEGIN "]) {
				if (![line hasSuffix: @"-----"])
					@throw [OFInvalidFormatException
					    exception];

				section = [line substringWithRange:
				    OFMakeRange(11, line.length - 11 - 5)];
				string = [OFMutableString string];
			}
		}
	}

	if (section != nil)
		@throw [OFInvalidFormatException exception];
}
