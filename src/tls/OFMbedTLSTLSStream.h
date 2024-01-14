/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFTLSStream.h"

#include <mbedtls/ssl.h>

OF_ASSUME_NONNULL_BEGIN

@interface OFMbedTLSTLSStream: OFTLSStream <OFStreamDelegate>
{
	bool _initialized, _handshakeDone;
	mbedtls_ssl_config _config;
	mbedtls_ssl_context _SSL;
	mbedtls_x509_crt _CAChain;
	OFString *_host;
}
@end

OF_ASSUME_NONNULL_END
