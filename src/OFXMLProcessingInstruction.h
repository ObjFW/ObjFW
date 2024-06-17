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

#import "OFXMLNode.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFXMLProcessingInstruction OFXMLProcessingInstruction.h ObjFW/ObjFW.h
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
