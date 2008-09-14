/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import <stddef.h>
#import "OFObject.h"

@interface OFException: OFObject
+ new: (id)obj;
- init: (id)obj;
@end

@interface OFNoMemException: OFException
+      new: (id)obj
  withSize: (size_t)size;
-     init: (id)obj
  withSize: (size_t)size;
@end

@interface OFMemNotPartOfObjException: OFException
+     new: (id)obj
  withPtr: (void*)ptr;
-    init: (id)obj
  withPtr: (void*)ptr;
@end
