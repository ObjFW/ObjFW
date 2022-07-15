/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
	bool _usesTCP;
	OFTimeInterval _configReloadInterval;
@protected
	OFDate *_lastConfigReload;
}

- (void)reload;
@end

OF_ASSUME_NONNULL_END
