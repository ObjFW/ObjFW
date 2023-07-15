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

#import "OFIRIHandler.h"

OF_ASSUME_NONNULL_BEGIN

@interface OFEmbeddedIRIHandler: OFIRIHandler
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Register a file for the `embedded:` IRI scheme.
 *
 * Usually, you should not use the directly, but rather generate a source file
 * for a file to be embedded using the `objfw-embed` tool.
 *
 * @param path The path to the file under the `embedded:` scheme. This is not
 *	       retained, so you must either pass a constant string or pass a
 *	       string that is already retained!
 * @param bytes The raw bytes for the file
 * @param size The size of the file
 */
extern void OFRegisterEmbeddedFile(OFString *path, const uint8_t *bytes,
    size_t size);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
