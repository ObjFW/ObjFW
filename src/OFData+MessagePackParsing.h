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

#import "OFData.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFData_MessagePackParsing_reference;
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
