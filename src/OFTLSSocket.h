/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

OF_ASSUME_NONNULL_BEGIN

@class OFString;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@protocol OFTLSSocket;

/*!
 * @protocol OFTLSSocketDelegate OFTLSSocket.h ObjFW/OFTLSSocket.h
 *
 * @brief A delegate for classes implementing the OFTLSSocket protocol.
 */
@protocol OFTLSSocketDelegate
@optional
/*!
 * @brief This callback is called when the TLS socket wants to know if it
 *	  should accept the received certificate.
 *
 * @note This is only used to verify certain fields of a certificate to allow
 *	 for protocol specific verification. The certificate chain is verified
 *	 using the specified CAs, or the system's CAs if no CAs have been
 *	 specified.
 *
 * @param socket The socket which wants to know if it should accept the received
 *		 certificate
 * @param certificate A dictionary with the fields of the received certificate
 * @return Whether the TLS socket should accept the received certificate chain
 */
-	     (bool)socket: (id <OFTLSSocket>)socket
  shouldAcceptCertificate: (OFDictionary *)certificate;
@end

/*!
 * @protocol OFTLSSocket OFTLSSocket.h ObjFW/OFTLSSocket.h
 *
 * @brief A protocol that should be implemented by 3rd-party libraries
 *	  implementing TLS.
 */
@protocol OFTLSSocket
/*!
 * The delegate for the TLS socket.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, assign)
    id <OFTLSSocketDelegate> delegate;

/*!
 * The path to the X.509 certificate file to use.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *certificateFile;

/*!
 * The path to the PKCS#8 private key file to use.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *privateKeyFile;

/*!
 * The passphrase to decrypt the PKCS#8 private key file.
 *
 * @warning You have to ensure that this is in secure memory protected from
 *	    swapping! This is also the reason why this is not an OFString.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, assign)
    const char *privateKeyPassphrase;

/**
 * Whether certificate verification is enabled.
 *
 * The default is enabled.
 */
@property (nonatomic, getter=isCertificateVerificationEnabled)
    bool certificateVerificationEnabled;

/*!
 * @brief Initializes the TLS socket with the specified TCP socket as its
 *	  underlying socket.
 *
 * @param socket The TCP socket to use as underlying socket
 */
- initWithSocket: (OFTCPSocket *)socket;

/*!
 * @brief Initiates the TLS handshake.
 *
 * @note This is only useful if you used @ref initWithSocket: to start TLS on
 *	 a TCP socket which is already connected!
 *
 * @param host The host to expect for certificate verification.
 *	       May be `nil` if certificate verification is disabled.
 */
- (void)startTLSWithExpectedHost: (nullable OFString *)host;

/*!
 * @brief Sets the path to the X.509 certificate file to use for the specified
 *	  SNI host.
 *
 * @param SNIHost The SNI host for which the path of the X.509 certificate file
 *		  should be set
 *
 * @param certificateFile The path to the X.509 certificate file
 */
- (void)setCertificateFile: (OFString *)certificateFile
		forSNIHost: (OFString *)SNIHost;

/*!
 * @brief Returns the path of the X.509 certificate file used by the TLS socket
 *	  for the specified SNI host.
 *
 * @param SNIHost The SNI host for which the path of the X.509 certificate file
 *		  should be returned
 *
 * @return The path of the X.509 certificate file used by the TLS socket for
 *	   the specified SNI host
 */
- (nullable OFString *)certificateFileForSNIHost: (OFString *)SNIHost;

/*!
 * @brief Sets the path to the PKCS#8 private key file to use for the specified
 *	  SNI host.
 *
 * @param privateKeyFile The path to the PKCS#8 private key file
 * @param SNIHost The SNI host for which the path to the PKCS#8 private key
 *		  file should be set
 */
- (void)setPrivateKeyFile: (OFString *)privateKeyFile
	       forSNIHost: (OFString *)SNIHost;

/*!
 * @brief Returns the path of the PKCS#8 private key file used by the TLS
 *	  socket for the specified SNI host.
 *
 * @param SNIHost The SNI host for which the path of the PKCS#8 private key
 *		  file should be returned
 *
 * @return The path of the PKCS#8 private key file used by the TLS socket for
 *	   the specified SNI host
 */
- (nullable OFString *)privateKeyFileForSNIHost: (OFString *)SNIHost;

/*!
 * @brief Sets the passphrase to decrypt the PKCS#8 private key file for the
 *	  specified SNI host.
 *
 * @warning You have to ensure that this is in secure memory protected from
 *	    swapping! This is also the reason why this is not an OFString.
 *
 * @param privateKeyPassphrase The passphrase to decrypt the PKCS#8 private
 *			       key file for the specified SNI host
 * @param SNIHost The SNI host for which the passphrase to decrypt the PKCS#8
 *		  private key file should be set
 */
- (void)setPrivateKeyPassphrase: (const char *)privateKeyPassphrase
		     forSNIHost: (OFString *)SNIHost;

/*!
 * @brief Returns the passphrase to decrypt the PKCS#8 private key file for the
 *	  specified SNI host.
 *
 * @warning You should not copy this to insecure memory which is swappable!
 *
 * @param SNIHost The SNI host for which the passphrase to decrypt the PKCS#8
 *		  private key file should be returned
 *
 * @return The passphrase to decrypt the PKCS#8 private key file for the
 *	   specified SNI host
 */
- (nullable const char *)privateKeyPassphraseForSNIHost: (OFString *)SNIHost;
@end

OF_ASSUME_NONNULL_END
