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

#import "OFTLSStream.h"

#include <openssl/bio.h>
#include <openssl/ssl.h>

OF_ASSUME_NONNULL_BEGIN

/*
 * According to RFC 8449, the maximum record size for TLS 1.2 is 16384 +
 * expansion up to 2048, while TLS 1.3 reduces this to 16384 + 256.
 */
#define OFOpenSSLTLSStreamBufferSize (16384 + 2048)

OF_SUBCLASSING_RESTRICTED
@interface OFOpenSSLTLSStream: OFTLSStream <OFStreamDelegate>
{
	BIO *_readBIO, *_writeBIO;
	SSL *_SSL;
	bool _server, _handshakeDone;
	OFString *_host;
	char _buffer[OFOpenSSLTLSStreamBufferSize];
}
@end

OF_ASSUME_NONNULL_END
