/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#include "config.h"

#import "OFCondition.h"

#import "OFConditionBroadcastFailedException.h"
#import "OFConditionSignalFailedException.h"
#import "OFConditionStillWaitingException.h"
#import "OFConditionWaitFailedException.h"
#import "OFInitializationFailedException.h"

@implementation OFCondition
+ (instancetype)condition
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	if (!of_condition_new(&condition)) {
		Class c = [self class];
		[self release];
		@throw [OFInitializationFailedException exceptionWithClass: c];
	}

	conditionInitialized = YES;

	return self;
}

- (void)wait
{
	if (!of_condition_wait(&condition, &mutex))
		@throw [OFConditionWaitFailedException
		    exceptionWithClass: [self class]
			     condition: self];
}

- (void)signal
{
	if (!of_condition_signal(&condition))
		@throw [OFConditionSignalFailedException
		    exceptionWithClass: [self class]
			     condition: self];
}

- (void)broadcast
{
	if (!of_condition_broadcast(&condition))
		@throw [OFConditionBroadcastFailedException
		    exceptionWithClass: [self class]
			     condition: self];
}

- (void)dealloc
{
	if (conditionInitialized)
		if (!of_condition_free(&condition))
			@throw [OFConditionStillWaitingException
			    exceptionWithClass: [self class]
				     condition: self];

	[super dealloc];
}
@end
