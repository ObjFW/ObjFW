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
@class OFDNSResolverQuery;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
@class OFNumber;
@class OFUDPSocket;

/*!
 * @enum of_dns_resolver_error_t OFDNSResolver.h ObjFW/OFDNSResolver.h
 *
 * @brief An enum describing why resolving a host failed.
 */
typedef enum of_dns_resolver_error_t {
	/*! An unknown error */
	OF_DNS_RESOLVER_ERROR_UNKNOWN,
	/*! The query timed out */
	OF_DNS_RESOLVER_ERROR_TIMEOUT,
	/*! The query was canceled */
	OF_DNS_RESOLVER_ERROR_CANCELED,
	/*!
	 * No result for the specified host with the specified type and class.
	 *
	 * This is only used in situations where this is an error, e.g. when
	 * trying to connect to a host.
	 */
	OF_DNS_RESOLVER_ERROR_NO_RESULT,
	/*! The server considered the query to be malformed */
	OF_DNS_RESOLVER_ERROR_SERVER_INVALID_FORMAT,
	/*! The server was unable to process due to an internal error */
	OF_DNS_RESOLVER_ERROR_SERVER_FAILURE,
	/*! The server returned an error that the domain does not exist */
	OF_DNS_RESOLVER_ERROR_SERVER_NAME_ERROR,
	/*! The server does not have support for the requested query */
	OF_DNS_RESOLVER_ERROR_SERVER_NOT_IMPLEMENTED,
	/*! The server refused the query */
	OF_DNS_RESOLVER_ERROR_SERVER_REFUSED
} of_dns_resolver_error_t;

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
	OFUDPSocket *_IPv4Socket;
#ifdef OF_HAVE_IPV6
	OFUDPSocket *_IPv6Socket;
#endif
	OFMutableDictionary OF_GENERIC(OFNumber *, OFDNSResolverQuery *)
	    *_queries;
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
 *		   `void (OFDNSResolver *resolver, OFString *domainName,
 *		   nullable OFArray<OFDNSResourceRecord *> *answerRecords,
 *		   nullable OFArray<OFDNSResourceRecord *> *authorityRecords,
 *		   nullable OFArray<OFDNSResourceRecord *> *additionalRecords,
 *		   nullable id context, nullable id exception)`.@n
 *		   `resolver` is the acting resolver.@n
 *		   `domainName` is the fully qualified domain name used to
 *		   resolve the host.@n
 *		   `answerRecords` are the answer records from the name server.
 *		   @n
 *		   `authorityRecords` are the authority records from the name
 *		   server.@n
 *		   `additionalRecords` are additional records sent by the name
 *		   server.
 *		   `context` is the context object originally passed.@n
 *		   `exception` is an exception that happened during resolving,
 *		   otherwise nil.
 * @param context A context object to pass along to the target
 */
- (void)asyncResolveHost: (OFString *)host
		  target: (id)target
		selector: (SEL)selector
		 context: (nullable id)context;

/*!
 * @brief Asynchronously resolves the specified host.
 *
 * @param host The host to resolve
 * @param recordClass The desired class of the records to query
 * @param recordType The desired type of the records to query
 * @param target The target to call with the result once resolving is done
 * @param selector The selector to call on the target. The signature must be
 *		   `void (OFDNSResolver *resolver, OFString *domainName,
 *		   nullable OFArray<OFDNSResourceRecord *> *answerRecords,
 *		   nullable OFArray<OFDNSResourceRecord *> *authorityRecords,
 *		   nullable OFArray<OFDNSResourceRecord *> *additionalRecords,
 *		   nullable id context, nullable id exception)`.@n
 *		   `resolver` is the acting resolver.@n
 *		   `domainName` is the fully qualified domain name used to
 *		   resolve the host.@n
 *		   `answerRecords` are the answer records from the name server.
 *		   @n
 *		   `authorityRecords` are the authority records from the name
 *		   server.@n
 *		   `additionalRecords` are additional records sent by the name
 *		   server.
 *		   `context` is the context object originally passed.@n
 *		   `exception` is an exception that happened during resolving,
 *		   otherwise nil.
 * @param context A context object to pass along to the target
 */
- (void)asyncResolveHost: (OFString *)host
	     recordClass: (of_dns_resource_record_class_t)recordClass
	      recordType: (of_dns_resource_record_type_t)recordType
		  target: (id)target
		selector: (SEL)selector
		 context: (nullable id)context;

/*!
 * @brief Closes all sockets and cancels all ongoing requests.
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
