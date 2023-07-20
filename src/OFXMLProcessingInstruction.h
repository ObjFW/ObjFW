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

#import "OFXMLNode.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFXMLProcessingInstruction \
 *	  OFXMLProcessingInstruction.h ObjFW/OFXMLProcessingInstruction.h
 *
 * @brief A class for representing an XML processing instruction.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFXMLProcessingInstruction: OFXMLNode
{
	OFString *_target, *_Nullable _text;
}

/**
 * @brief The target of the processing instruction.
 */
@property (readonly, nonatomic) OFString *target;

/**
 * @brief The text of the processing instruction.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *text;

/**
 * @brief Creates a new OFXMLProcessingInstruction with the specified target
 *	  and text.
 *
 * @param target The target for the processing instruction
 * @param text The text for the processing instruction
 * @return A new OFXMLProcessingInstruction
 */
+ (instancetype)processingInstructionWithTarget: (OFString *)target
					   text: (OFString *)text;

/**
 * @brief Initializes an already allocated OFXMLProcessingInstruction with the
 *	  specified target and text.
 *
 * @param target The target for the processing instruction
 * @param text The text for the processing instruction
 * @return An initialized OFXMLProcessingInstruction
 */
- (instancetype)initWithTarget: (OFString *)target
			  text: (OFString *)text OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
