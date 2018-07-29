/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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
#import "OFString.h"
#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
@class OFNumber;

/*!
 * @class OFDNSResolver OFDNSResolver.h ObjFW/OFDNSResolver.h
 *
 * @brief A class for resolving DNS names.
 */
@interface OFDNSResolver: OFObject
{
	OFDictionary OF_GENERIC(OFString *, OFArray OF_GENERIC(OFString *) *)
	    *_staticHosts;
	OFArray OF_GENERIC(OFString *) *_nameServers;
	OFString *_Nullable _localDomain;
	OFArray OF_GENERIC(OFString *) *_searchDomains;
	size_t _minNumberOfDotsInAbsoluteName;
	bool _usesTCP;
	OFMutableDictionary OF_GENERIC(OFNumber *, id) *_queries;
}

/*!
 * @brief A dictionary of static hosts.
 *
 * This dictionary is checked before actually looking up a host.
 */
@property (copy, nonatomic) OFDictionary OF_GENERIC(OFString *,
    OFArray OF_GENERIC(OFString *) *) *staticHosts;

/*!
 * @brief An array of name servers to use.
 *
 * The name servers are tried in order.
 */
@property (copy, nonatomic) OFArray OF_GENERIC(OFString *) *nameServers;

/*!
 * @brief The local domain.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *localDomain;

/*!
 * @brief The domains to search for queries for short names.
 */
@property (copy, nonatomic) OFArray OF_GENERIC(OFString *) *searchDomains;

/*!
 * @brief The minimum number of dots for a name to be considered absolute.
 */
@property (nonatomic) size_t minNumberOfDotsInAbsoluteName;

/*!
 * @brief Whether the resolver uses TCP to talk to a name server.
 */
@property (nonatomic) bool usesTCP;

/*!
 * @brief Creates a new, autoreleased OFDNSResolver.
 */
+ (instancetype)resolver;

/*!
 * @brief Initializes an already allocated OFDNSResolver.
 */
- (instancetype)init;

/*!
 * @brief Asynchronously resolves the specified host.
 *
 * @param host The host to resolve
 * @param target The target to call with the result once resolving is done
 * @param selector The selector to call on the target. The signature must be
 *		   `void (OFArray<OFDNSResourceRecord *> *response, id context,
 *		   id exception)`.
 * @param context A context object to pass along to the target
 */
- (void)asyncResolveHost: (OFString *)host
		  target: (id)target
		selector: (SEL)selector
		 context: (nullable id)context;
@end

OF_ASSUME_NONNULL_END
