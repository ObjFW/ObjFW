/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#define OFDNSResolverBufferLength 512

@class OFArray OF_GENERIC(ObjectType);
@class OFDNSResolver;
@class OFDNSResolverContext;
@class OFDNSResolverSettings;
@class OFDate;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
@class OFNumber;
@class OFPair OF_GENERIC(FirstType, SecondType);
@class OFTCPSocket;
@class OFUDPSocket;

/**
 * @enum OFDNSResolverErrorCode OFDNSResolver.h ObjFW/OFDNSResolver.h
 *
 * @brief An enum describing why resolving a host failed.
 */
typedef enum {
	/** An unknown error */
	OFDNSResolverErrorCodeUnknown,
	/** The query timed out */
	OFDNSResolverErrorCodeTimeout,
	/** The query was canceled */
	OFDNSResolverErrorCodeCanceled,
	/**
	 * No result for the specified host with the specified type and class.
	 *
	 * This is only used in situations where this is an error, e.g. when
	 * trying to connect to a host.
	 */
	OFDNSResolverErrorCodeNoResult,
	/** The server considered the query to be malformed */
	OFDNSResolverErrorCodeServerInvalidFormat,
	/** The server was unable to process due to an internal error */
	OFDNSResolverErrorCodeServerFailure,
	/** The server returned an error that the domain does not exist */
	OFDNSResolverErrorCodeServerNameError,
	/** The server does not have support for the requested query */
	OFDNSResolverErrorCodeServerNotImplemented,
	/** The server refused the query */
	OFDNSResolverErrorCodeServerRefused,
	/** There was no name server to query */
	OFDNSResolverErrorCodeNoNameServer
} OFDNSResolverErrorCode;

/**
 * @protocol OFDNSResolverQueryDelegate OFDNSResolver.h ObjFW/OFDNSResolver.h
 *
 * @brief A delegate for performed DNS queries.
 */
@protocol OFDNSResolverQueryDelegate <OFObject>
/**
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

/**
 * @protocol OFDNSResolverQueryDelegate OFDNSResolver.h ObjFW/OFDNSResolver.h
 *
 * @brief A delegate for resolved hosts.
 */
@protocol OFDNSResolverHostDelegate <OFObject>
/**
 * @brief This method is called when a DNS resolver resolved a host to
 *	  addresses.
 *
 * @param resolver The acting resolver
 * @param host The host the resolver resolved
 * @param addresses OFData containing several OFSocketAddress
 * @param exception The exception that occurred during resolving, or nil on
 *		    success
 */
- (void)resolver: (OFDNSResolver *)resolver
  didResolveHost: (OFString *)host
       addresses: (nullable OFData *)addresses
       exception: (nullable id)exception;
@end

/**
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
	char _buffer[OFDNSResolverBufferLength];
	OFMutableDictionary OF_GENERIC(OFNumber *, OFDNSResolverContext *)
	    *_queries;
	OFMutableDictionary OF_GENERIC(OFTCPSocket *, OFDNSResolverContext *)
	    *_TCPQueries;
	OFMutableDictionary OF_GENERIC(OFDNSQuery *,
	    OFPair OF_GENERIC(OFDate *, OFDNSResponse *) *) *_cache;
	OFTimeInterval _lastCacheCleanup;
}

/**
 * @brief A dictionary of static hosts.
 *
 * This dictionary is checked before actually looking up a host.
 */
@property (copy, nonatomic) OFDictionary OF_GENERIC(OFString *,
    OFArray OF_GENERIC(OFString *) *) *staticHosts;

/**
 * @brief An array of name servers to use.
 *
 * The name servers are tried in order.
 */
@property (copy, nonatomic) OFArray OF_GENERIC(OFString *) *nameServers;

/**
 * @brief The local domain.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *localDomain;

/**
 * @brief The domains to search for queries for short names.
 */
@property (copy, nonatomic) OFArray OF_GENERIC(OFString *) *searchDomains;

/**
 * @brief The timeout, in seconds, after which the next name server should be
 *	  tried.
 */
@property (nonatomic) OFTimeInterval timeout;

/**
 * @brief The number of attempts before giving up to resolve a host.
 *
 * Trying all name servers once is considered a single attempt.
 */
@property (nonatomic) unsigned int maxAttempts;

/**
 * @brief The minimum number of dots for a name to be considered absolute.
 */
@property (nonatomic) unsigned int minNumberOfDotsInAbsoluteName;

/**
 * @brief Whether the resolver forces TCP to talk to a name server.
 */
@property (nonatomic) bool forcesTCP;

/**
 * @brief The interval in seconds in which the config should be reloaded.
 *
 * Setting this to 0 disables config reloading.
 */
@property (nonatomic) OFTimeInterval configReloadInterval;

/**
 * @brief Creates a new, autoreleased OFDNSResolver.
 */
+ (instancetype)resolver;

/**
 * @brief Initializes an already allocated OFDNSResolver.
 */
- (instancetype)init;

/**
 * @brief Asynchronously performs the specified query.
 *
 * @param query The query to perform
 * @param delegate The delegate to use for callbacks
 */
- (void)asyncPerformQuery: (OFDNSQuery *)query
		 delegate: (id <OFDNSResolverQueryDelegate>)delegate;

/**
 * @brief Asynchronously performs the specified query.
 *
 * @param query The query to perform
 * @param runLoopMode The run loop mode in which to resolve
 * @param delegate The delegate to use for callbacks
 */
- (void)asyncPerformQuery: (OFDNSQuery *)query
	      runLoopMode: (OFRunLoopMode)runLoopMode
		 delegate: (id <OFDNSResolverQueryDelegate>)delegate;

/**
 * @brief Asynchronously resolves the specified host to socket addresses.
 *
 * @param host The host to resolve
 * @param delegate The delegate to use for callbacks
 */
- (void)asyncResolveAddressesForHost: (OFString *)host
			    delegate: (id <OFDNSResolverHostDelegate>)delegate;

/**
 * @brief Asynchronously resolves the specified host to socket addresses.
 *
 * @param host The host to resolve
 * @param addressFamily The desired socket address family
 * @param delegate The delegate to use for callbacks
 */
- (void)asyncResolveAddressesForHost: (OFString *)host
		       addressFamily: (OFSocketAddressFamily)addressFamily
			    delegate: (id <OFDNSResolverHostDelegate>)delegate;

/**
 * @brief Asynchronously resolves the specified host to socket addresses.
 *
 * @param host The host to resolve
 * @param addressFamily The desired socket address family
 * @param runLoopMode The run loop mode in which to resolve
 * @param delegate The delegate to use for callbacks
 */
- (void)asyncResolveAddressesForHost: (OFString *)host
		       addressFamily: (OFSocketAddressFamily)addressFamily
			 runLoopMode: (OFRunLoopMode)runLoopMode
			    delegate: (id <OFDNSResolverHostDelegate>)delegate;

/**
 * @brief Synchronously resolves the specified host to socket addresses.
 *
 * @param host The host to resolve
 * @param addressFamily The desired socket address family
 * @return OFData containing several OFSocketAddress
 * @throw OFInvalidServerResponseException The received response was invalid
 * @throw OFTruncatedDataException The received response was truncated
 */
- (OFData *)resolveAddressesForHost: (OFString *)host
		      addressFamily: (OFSocketAddressFamily)addressFamily;

/**
 * @brief Closes all sockets and cancels all ongoing queries.
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
