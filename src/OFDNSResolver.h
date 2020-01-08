/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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
#import "OFDNSQuery.h"
#import "OFDNSResourceRecord.h"
#import "OFDNSResponse.h"
#import "OFRunLoop.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

#define OF_DNS_RESOLVER_BUFFER_LENGTH 512

@class OFArray OF_GENERIC(ObjectType);
@class OFDNSResolver;
@class OFDNSResolverContext;
@class OFDNSResolverSettings;
@class OFDate;
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
 * @protocol OFDNSResolverQueryDelegate OFDNSResolver.h ObjFW/OFDNSResolver.h
 *
 * @brief A delegate for performed DNS queries.
 */
@protocol OFDNSResolverQueryDelegate <OFObject>
/*!
 * @brief This method is called when a DNS resolver performed a query.
 *
 * @param resolver The acting resolver
 * @param query The query performed by the resolver
 * @param response The response from the DNS server, or nil on error
 * @param exception An exception that happened during resolving, or nil on
 *		    success
 */
-  (void)resolver: (OFDNSResolver *)resolver
  didPerformQuery: (OFDNSQuery *)query
	 response: (nullable OFDNSResponse *)response
	exception: (nullable id)exception;
@end

/*!
 * @protocol OFDNSResolverQueryDelegate OFDNSResolver.h ObjFW/OFDNSResolver.h
 *
 * @brief A delegate for resolved hosts.
 */
@protocol OFDNSResolverHostDelegate <OFObject>
/*!
 * @brief This method is called when a DNS resolver resolved a host to
 *	  addresses.
 *
 * @param resolver The acting resolver
 * @param host The host the resolver resolved
 * @param addresses OFData containing several of_socket_address_t
 * @param exception The exception that occurred during resolving, or nil on
 *		    success
 */
- (void)resolver: (OFDNSResolver *)resolver
  didResolveHost: (OFString *)host
       addresses: (nullable OFData *)addresses
       exception: (nullable id)exception;
@end

/*!
 * @class OFDNSResolver OFDNSResolver.h ObjFW/OFDNSResolver.h
 *
 * @brief A class for resolving DNS names.
 *
 * @note If you change any of the properties, make sure to set
 *	 @ref configReloadInterval to 0, as otherwise your changes will be
 *	 reverted back to the system configuration on the next periodic config
 *	 reload.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFDNSResolver: OFObject
{
	OFDNSResolverSettings *_settings;
	OFUDPSocket *_IPv4Socket;
#ifdef OF_HAVE_IPV6
	OFUDPSocket *_IPv6Socket;
#endif
	char _buffer[OF_DNS_RESOLVER_BUFFER_LENGTH];
	OFMutableDictionary OF_GENERIC(OFNumber *, OFDNSResolverContext *)
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
 * @brief The timeout, in seconds, after which the next name server should be
 *	  tried.
 */
@property (nonatomic) of_time_interval_t timeout;

/*!
 * @brief The number of attempts before giving up to resolve a host.
 *
 * Trying all name servers once is considered a single attempt.
 */
@property (nonatomic) unsigned int maxAttempts;

/*!
 * @brief The minimum number of dots for a name to be considered absolute.
 */
@property (nonatomic) unsigned int minNumberOfDotsInAbsoluteName;

/*!
 * @brief Whether the resolver uses TCP to talk to a name server.
 */
@property (nonatomic) bool usesTCP;

/*!
 * @brief The interval in seconds in which the config should be reloaded.
 *
 * Setting this to 0 disables config reloading.
 */
@property (nonatomic) of_time_interval_t configReloadInterval;

/*!
 * @brief Creates a new, autoreleased OFDNSResolver.
 */
+ (instancetype)resolver;

/*!
 * @brief Initializes an already allocated OFDNSResolver.
 */
- (instancetype)init;

/*!
 * @brief Asynchronously performs the specified query.
 *
 * @param query The query to perform
 * @param delegate The delegate to use for callbacks
 */
- (void)asyncPerformQuery: (OFDNSQuery *)query
		 delegate: (id <OFDNSResolverQueryDelegate>)delegate;

/*!
 * @brief Asynchronously performs the specified query.
 *
 * @param query The query to perform
 * @param runLoopMode The run loop mode in which to resolve
 * @param delegate The delegate to use for callbacks
 */
- (void)asyncPerformQuery: (OFDNSQuery *)query
	      runLoopMode: (of_run_loop_mode_t)runLoopMode
		 delegate: (id <OFDNSResolverQueryDelegate>)delegate;

/*!
 * @brief Asynchronously resolves the specified host to socket addresses.
 *
 * @param host The host to resolve
 * @param delegate The delegate to use for callbacks
 */
- (void)asyncResolveAddressesForHost: (OFString *)host
			    delegate: (id <OFDNSResolverHostDelegate>)delegate;

/*!
 * @brief Asynchronously resolves the specified host to socket addresses.
 *
 * @param host The host to resolve
 * @param addressFamily The desired socket address family
 * @param delegate The delegate to use for callbacks
 */
- (void)asyncResolveAddressesForHost: (OFString *)host
		       addressFamily: (of_socket_address_family_t)addressFamily
			    delegate: (id <OFDNSResolverHostDelegate>)delegate;

/*!
 * @brief Asynchronously resolves the specified host to socket addresses.
 *
 * @param host The host to resolve
 * @param addressFamily The desired socket address family
 * @param runLoopMode The run loop mode in which to resolve
 * @param delegate The delegate to use for callbacks
 */
- (void)asyncResolveAddressesForHost: (OFString *)host
		       addressFamily: (of_socket_address_family_t)addressFamily
			 runLoopMode: (of_run_loop_mode_t)runLoopMode
			    delegate: (id <OFDNSResolverHostDelegate>)delegate;

/*!
 * @brief Synchronously resolves the specified host to socket addresses.
 *
 * @param host The host to resolve
 * @param addressFamily The desired socket address family
 * @return OFData containing several of_socket_address_t
 */
- (OFData *)resolveAddressesForHost: (OFString *)host
		      addressFamily: (of_socket_address_family_t)addressFamily;

/*!
 * @brief Closes all sockets and cancels all ongoing queries.
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
