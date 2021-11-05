/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

/**
 * @protocol OFTLSSocket OFTLSSocket.h ObjFW/OFTLSSocket.h
 *
 * @brief A protocol that should be implemented by 3rd-party libraries
 *	  implementing TLS.
 */
@protocol OFTLSSocket
/**
 * @brief Whether certificates are verified.
 *
 * The default is enabled.
 */
@property (nonatomic) bool verifiesCertificates;

/**
 * @brief Initializes the TLS socket with the specified TCP socket as its
 *	  underlying socket.
 *
 * @param socket The TCP socket to use as underlying socket
 */
- (instancetype)initWithSocket: (OFTCPSocket *)socket;
@end

OF_ASSUME_NONNULL_END
