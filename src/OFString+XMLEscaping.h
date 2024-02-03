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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_XMLEscaping_reference;
#ifdef __cplusplus
}
#endif

@interface OFString (XMLEscaping)
/**
 * @brief The string in a form escaped for use in an XML document.
 */
@property (readonly, nonatomic) OFString *stringByXMLEscaping;
@end

OF_ASSUME_NONNULL_END
