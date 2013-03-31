/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "objfw-defs.h"

@class OFString;
@class OFArray;
@protocol OFTLSSocket;

/*!
 * @brief A delegate for classes implementing the OFTLSSocket protocol.
 */
@protocol OFTLSSocketDelegate
/*!
 * @brief This callback is called when the TLS socket wants to know if it
 *	  should accept the received keychain.
 *
 * @param socket The socket which wants to know if it should accept the received
 *		 keychain
 * @param keychain An array of objects implementing the OFX509Certificate
 *		   protocol
 * @return Whether the TLS socket should accept the received keychain
 */
-	  (bool)socket: (id <OFTLSSocket>)socket
  shouldAcceptKeychain: (OFArray*)keychain;
@end

/*!
 * @brief A protocol that should be implemented by 3rd-party libraries
 *	  implementing TLS.
 */
@protocol OFTLSSocket
#ifdef OF_HAVE_PROPERTIES
@property (assign) id <OFTLSSocketDelegate> delegate;
@property (copy) OFString *certificateFile, *privateKeyFile;
@property const char *privateKeyPassphrase;
#endif

/*!
 * @brief Initializes the TLS socket with the specified TCP socket as its
 *	  underlying socket.
 *
 * @param socket The TCP socket to use as underlying socket
 */
- initWithSocket: (OFTCPSocket*)socket;

/*!
 * @brief Initiates the TLS handshake.
 *
 * @note This is only useful if you used @ref initWithSocket: to start TLS on
 *	 a TCP socket which is already connected!
 */
- (void)startTLS;

/*!
 * @brief Sets a delegate for the TLS socket.
 *
 * @param delegate The delegate to use
 */
- (void)setDelegate: (id <OFTLSSocketDelegate>)delegate;

/*!
 * @brief Returns the delegate used by the TLS socket.
 *
 * @return The delegate used by the TLS socket
 */
- (id <OFTLSSocketDelegate>)delegate;

/*!
 * @brief Sets the path to the X.509 certificate file to use.
 *
 * @param certificateFile The path to the X.509 certificate file
 */
- (void)setCertificateFile: (OFString*)certificateFile;

/*!
 * @brief Sets the path to the X.509 certificate file to use for the specified
 *	  SNI host.
 *
 * @param SNIHost The SNI host for which the path of the X.509 certificate file
 *		  should be set
 *
 * @param certificateFile The path to the X.509 certificate file
 */
- (void)setCertificateFile: (OFString*)certificateFile
		forSNIHost: (OFString*)SNIHost;

/*!
 * @brief Returns the path of the X.509 certificate file used by the TLS socket.
 *
 * @return The path of the X.509 certificate file used by the TLS socket
 */
- (OFString*)certificateFile;

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
- (OFString*)certificateFileForSNIHost: (OFString*)SNIHost;

/*!
 * @brief Sets the path to the PKCS#8 private key file to use.
 *
 * @param privateKeyFile The path to the PKCS#8 private key file
 */
- (void)setPrivateKeyFile: (OFString*)privateKeyFile;

/*!
 * @brief Sets the path to the PKCS#8 private key file to use for the specified
 *	  SNI host.
 *
 * @param privateKeyFile The path to the PKCS#8 private key file
 * @param SNIHost The SNI host for which the path to the PKCS#8 private key
 *		  file should be set
 */
- (void)setPrivateKeyFile: (OFString*)privateKeyFile
	       forSNIHost: (OFString*)SNIHost;

/*!
 * @brief Returns the path of the PKCS#8 private key file used by the TLS
 *	  socket.
 *
 * @return The path of the PKCS#8 private key file used by the TLS socket
 */
- (OFString*)privateKeyFile;

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
- (OFString*)privateKeyFileForSNIHost: (OFString*)SNIHost;

/*!
 * @brief Sets the passphrase to decrypt the PKCS#8 private key file.
 *
 * @warning You have to ensure that this is in secure memory protected from
 *	    swapping! This is also the reason why this is not an OFString.
 *
 * @param privateKeyPassphrase The passphrase to decrypt the PKCS#8 private
 *			       key file
 */
- (void)setPrivateKeyPassphrase: (const char*)privateKeyPassphrase;

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
- (void)setPrivateKeyPassphrase: (const char*)privateKeyPassphrase
		     forSNIHost: (OFString*)SNIHost;

/*!
 * @brief Returns the passphrase to decrypt the PKCS#8 private key file.
 *
 * @warning You should not copy this to insecure memory which is swappable!
 *
 * @return The passphrase to decrypt the PKCS#8 private key file
 */
- (const char*)privateKeyPassphrase;

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
- (const char*)privateKeyPassphraseForSNIHost: (OFString*)SNIHost;
@end
