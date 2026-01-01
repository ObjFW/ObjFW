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

#import "OFData.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFData_MessagePackParsing_reference OF_VISIBILITY_INTERNAL;
#ifdef __cplusplus
}
#endif

@interface OFData (MessagePackParsing)
/**
 * @brief The data interpreted as MessagePack representation and parsed as an
 *	  object.
 *
 * @throw OFInvalidFormatException The MessagePack representation contained in
 *				   the data contained an invalid format
 * @throw OFTruncatedDataException The MessagePack representation contained in
 *				   the data is truncated
 * @throw OFOutOfRangeException The depth limit has been exceeded
 */
@property (readonly, nonatomic) id objectByParsingMessagePack;

/**
 * @brief Parses the MessagePack representation and returns it as an object.
 *
 * @param depthLimit The maximum depth the parser should accept (defaults to 32
 *		     if not specified, 0 means no limit (insecure!))
 * @return The MessagePack representation as an object
 * @throw OFInvalidFormatException The MessagePack representation contained in
 *				   the data contained an invalid format
 * @throw OFTruncatedDataException The MessagePack representation contained in
 *				   the data is truncated
 * @throw OFOutOfRangeException The depth limit has been exceeded
 */
- (id)objectByParsingMessagePackWithDepthLimit: (size_t)depthLimit;
@end

OF_ASSUME_NONNULL_END
