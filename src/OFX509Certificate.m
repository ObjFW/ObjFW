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

#include "config.h"

#import "OFX509Certificate.h"

#import "OFNotImplementedException.h"

#ifdef OF_AMIGAOS
# undef OFX509CertificateImplementation
#endif

Class OFX509CertificateImplementation = Nil;

#ifdef OF_AMIGAOS
Class *
OFX509CertificateImplementationRef(void)
{
	return &OFX509CertificateImplementation;
}
#endif

@implementation OFX509Certificate
+ (instancetype)alloc
{
	if (self == [OFX509Certificate class]) {
		if (OFX509CertificateImplementation != Nil)
			return [OFX509CertificateImplementation alloc];

		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
	}

	return [super alloc];
}

+ (bool)supportsPEMFiles
{
	return [OFX509CertificateImplementation supportsPEMFiles];
}

+ (bool)supportsPKCS12Files
{
	return [OFX509CertificateImplementation supportsPKCS12Files];
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)certificatesIRI
		       privateKeyIRI: (OFIRI *)privateKeyIRI
{
	if ([OFX509CertificateImplementation supportsPEMFiles])
		return [OFX509CertificateImplementation
		    certificateChainFromPEMFileAtIRI: certificatesIRI
				       privateKeyIRI: privateKeyIRI];

	OF_UNRECOGNIZED_SELECTOR
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPKCS12FileAtIRI: (OFIRI *)IRI
			     passphrase: (OFString *)passphrase
{
	if ([OFX509CertificateImplementation supportsPKCS12Files])
		return [OFX509CertificateImplementation
		    certificateChainFromPKCS12FileAtIRI: IRI
					     passphrase: passphrase];

	OF_UNRECOGNIZED_SELECTOR
}
@end
