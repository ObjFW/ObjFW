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

#include "config.h"

#import "OFX509CertificatePrivateKey.h"

#import "OFNotImplementedException.h"

Class OFX509CertificatePrivateKeyImplementation = Nil;

@implementation OFX509CertificatePrivateKey
+ (instancetype)alloc
{
	if (self == [OFX509CertificatePrivateKey class]) {
		if (OFX509CertificatePrivateKeyImplementation != Nil)
			return
			    [OFX509CertificatePrivateKeyImplementation alloc];

		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
	}

	return [super alloc];
}

+ (instancetype)privateKeyFromPEMFileAtIRI: (OFIRI *)IRI
{
	if (OFX509CertificatePrivateKeyImplementation != Nil)
		return [OFX509CertificatePrivateKeyImplementation
		    privateKeyFromPEMFileAtIRI: IRI];

	OF_UNRECOGNIZED_SELECTOR
}
@end
