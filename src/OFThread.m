/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#import "OFThread.h"
#import "OFExceptions.h"

#ifndef _WIN32
static void*
call_main(void *obj)
{
	return [(OFThread*)obj main];
}
#else
static DWORD WINAPI
call_main(LPVOID obj)
{
	/* Windows does not support returning a pointer. Nasty workaround. */
	((OFThread*)obj)->retval = [(OFThread*)obj main];

	return 0;
}
#endif

@implementation OFThread
+ threadWithObject: (id)obj
{
	/*
	 * This is one of the rare cases where the convenience method should
	 * use self instead of the class.
	 *
	 * The reason is that you derive from OFThread and reimplement main.
	 * If OFThread instead of self would be used here, the reimplemented
	 * main would never be called.
	 */
	return [[[self alloc] initWithObject: obj] autorelease];
}

+ setObject: (id)obj
  forTLSKey: (OFTLSKey*)key
{
	id old;

	@try {
		old = [self objectForTLSKey: key];
	} @catch (OFNotInSetException *e) {
		[e free];
		old = nil;
	}

#ifndef _WIN32
	if (pthread_setspecific(key->key, obj))
#else
	if (!TlsSetValue(key->key, obj))
#endif
		/* FIXME: Maybe another exception would be better */
		@throw [OFNotInSetException newWithClass: self];

	if (obj != nil)
		[obj retain];
	if (old != nil)
		[old release];

	return self;
}

+ (id)objectForTLSKey: (OFTLSKey*)key
{
	void *ret;

#ifndef _WIN32
	ret = pthread_getspecific(key->key);
#else
	ret = TlsGetValue(key->key);
#endif

	/*
	 * NULL and nil might be different on some platforms. NULL is returned
	 * if the key is missing, nil can be returned if it was explicitly set
	 * to nil to release the old object.
	 */
	if (ret == NULL || (id)ret == nil)
		@throw [OFNotInSetException newWithClass: self];

	return (id)ret;
}

- initWithObject: (id)obj
{
	Class c;

	self = [super init];
	object = obj;

#ifndef _WIN32
	if (pthread_create(&thread, NULL, call_main, self)) {
#else
	if ((thread =
	    CreateThread(NULL, 0, call_main, self, 0, NULL)) == NULL) {
#endif
		c = isa;
		[super free];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	return self;
}

- main
{
	return nil;
}

- join
{
#ifndef _WIN32
	void *ret;

	if (pthread_join(thread, &ret))
		@throw [OFThreadJoinFailedException newWithClass: isa];

	if (ret == PTHREAD_CANCELED)
		@throw [OFThreadCanceledException newWithClass: isa];

	return (id)ret;
#else
	if (WaitForSingleObject(thread, INFINITE))
		@throw [OFThreadJoinFailedException newWithClass: isa];

	CloseHandle(thread);
	thread = INVALID_HANDLE_VALUE;

	return retval;
#endif
}

- free
{
	/*
	 * No need to handle errors - if canceling the thread fails, we can't
	 * do anything anyway. Most likely, it finished already or was already
	 * canceled.
	 */
#ifndef _WIN32
	pthread_cancel(thread);
#else
	if (thread != INVALID_HANDLE_VALUE) {
		TerminateThread(thread, 1);
		CloseHandle(thread);
	}
#endif

	return [super free];
}
@end

@implementation OFTLSKey
+ tlsKeyWithDestructor: (void(*)(void*))destructor
{
	return [[[OFTLSKey alloc] initWithDestructor: destructor] autorelease];
}

- initWithDestructor: (void(*)(void*))destructor
{
	Class c;

	self = [super init];

	/* FIXME: Call destructor on Win32 */
#ifndef _WIN32
	if (pthread_key_create(&key, destructor)) {
#else
	if ((key = TlsAlloc()) == TLS_OUT_OF_INDEXES) {
#endif
		c = isa;
		[super free];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	return self;
}
@end
