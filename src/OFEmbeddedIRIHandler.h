/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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
