/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDate;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

@interface OFDNSResolverSettings: OFObject <OFCopying>
{
@public
	OFDictionary OF_GENERIC(OFString *, OFArray OF_GENERIC(OFString *) *)
	    *_staticHosts;
	OFArray OF_GENERIC(OFString *) *_nameServers;
	OFString *_Nullable _localDomain;
	OFArray OF_GENERIC(OFString *) *_searchDomains;
	OFTimeInterval _timeout;
	unsigned int _maxAttempts, _minNumberOfDotsInAbsoluteName;
	bool _forcesTCP;
	OFTimeInterval _configReloadInterval;
@protected
	OFDate *_lastConfigReload;
}

- (void)reload;
@end

OF_ASSUME_NONNULL_END
