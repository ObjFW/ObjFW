/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#include <string.h>
#include <unistd.h>

#import "OFXMLParser.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFXMLAttribute.h"
#import "OFStream.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "macros.h"

typedef void (*state_function)(id, SEL, const char*, size_t*, size_t*);
static SEL selectors[OF_XMLPARSER_NUM_STATES];
static state_function lookup_table[OF_XMLPARSER_NUM_STATES];

static OF_INLINE OFString*
transform_string(OFMutableString *cache,
    OFObject <OFStringXMLUnescapingDelegate> *delegate)
{
	[cache replaceOccurrencesOfString: @"\r\n"
			       withString: @"\n"];
	[cache replaceOccurrencesOfString: @"\r"
			       withString: @"\n"];
	return [cache stringByXMLUnescapingWithDelegate: delegate];
}

static OF_INLINE OFString*
namespace_for_prefix(OFString *prefix, OFArray *namespaces)
{
	OFDictionary **carray = [namespaces cArray];
	ssize_t i;

	if (prefix == nil)
		prefix = @"";

	for (i = [namespaces count] - 1; i >= 0; i--) {
		OFString *tmp;

		if ((tmp = [carray[i] objectForKey: prefix]) != nil)
			return tmp;
	}

	return nil;
}

static OF_INLINE void
resolve_attr_namespace(OFXMLAttribute *attr, OFString *prefix, OFString *ns,
    OFArray *namespaces, Class isa)
{
	OFString *attr_ns;
	OFString *attr_prefix = attr->ns;

	if (attr_prefix == nil)
		return;

	attr_ns = namespace_for_prefix(attr_prefix, namespaces);

	if ((attr_prefix != nil && attr_ns == nil))
		@throw [OFUnboundNamespaceException newWithClass: isa
							  prefix: attr_prefix];

	[attr->ns release];
	attr->ns = [attr_ns retain];
}

@implementation OFXMLParser
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
@synthesize processingInstructionsHandler, elementStartHandler;
@synthesize elementEndHandler, charactersHandler, CDATAHandler, commentHandler;
@synthesize unknownEntityHandler;
#endif

+ (void)initialize
{
	size_t i;

	const SEL sels[] = {
		@selector(_parseOutsideTagWithBuffer:i:last:),
		@selector(_parseTagOpenedWithBuffer:i:last:),
		@selector(_parseInProcessingInstructionsWithBuffer:i:last:),
		@selector(_parseInTagNameWithBuffer:i:last:),
		@selector(_parseInCloseTagNameWithBuffer:i:last:),
		@selector(_parseInTagWithBuffer:i:last:),
		@selector(_parseInAttributeNameWithBuffer:i:last:),
		@selector(_parseExpectDelimiterWithBuffer:i:last:),
		@selector(_parseInAttributeValueWithBuffer:i:last:),
		@selector(_parseExpectCloseWithBuffer:i:last:),
		@selector(_parseExpectSpaceOrCloseWithBuffer:i:last:),
		@selector(_parseInExclamationMarkWithBuffer:i:last:),
		@selector(_parseInCDATAOpeningWithBuffer:i:last:),
		@selector(_parseInCDATA1WithBuffer:i:last:),
		@selector(_parseInCDATA2WithBuffer:i:last:),
		@selector(_parseInCommentOpeningWithBuffer:i:last:),
		@selector(_parseInComment1WithBuffer:i:last:),
		@selector(_parseInComment2WithBuffer:i:last:),
		@selector(_parseInDoctypeWithBuffer:i:last:),
	};
	memcpy(selectors, sels, sizeof(sels));

	for (i = 0; i < OF_XMLPARSER_NUM_STATES; i++) {
		if (![self instancesRespondToSelector: selectors[i]])
			@throw [OFInitializationFailedException
			    newWithClass: self];

		lookup_table[i] = (state_function)
		    [self instanceMethodForSelector: selectors[i]];
	}
}

+ parser
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		OFAutoreleasePool *pool;
		OFMutableDictionary *dict;

		cache = [[OFMutableString alloc] init];
		previous = [[OFMutableArray alloc] init];
		namespaces = [[OFMutableArray alloc] init];

		pool = [[OFAutoreleasePool alloc] init];
		dict = [OFMutableDictionary dictionaryWithKeysAndObjects:
		    @"xml", @"http://www.w3.org/XML/1998/namespace",
		    @"xmlns", @"http://www.w3.org/2000/xmlns/", nil];
		[namespaces addObject: dict];

		lineNumber = 1;

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[(id)delegate release];

	[cache release];
	[name release];
	[prefix release];
	[namespaces release];
	[attrs release];
	[attrName release];
	[attrPrefix release];
	[previous release];
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	[elementStartHandler release];
	[elementEndHandler release];
	[charactersHandler release];
	[CDATAHandler release];
	[commentHandler release];
	[unknownEntityHandler release];
#endif

	[super dealloc];
}

- (id <OFXMLParserDelegate>)delegate
{
	return [[(id)delegate retain] autorelease];
}

- (void)setDelegate: (id <OFXMLParserDelegate>)delegate_
{
	[(id)delegate_ retain];
	[(id)delegate release];
	delegate = delegate_;
}

- (void)parseBuffer: (const char*)buf
	   withSize: (size_t)size
{
	size_t i, last = 0;

	for (i = 0; i < size; i++) {
		size_t j = i;

		lookup_table[state](self, selectors[state], buf, &i, &last);

		/* Ensure we don't count this character twice */
		if (i != j)
			continue;

		if (buf[i] == '\r' || (buf[i] == '\n' && !lastCarriageReturn))
			lineNumber++;

		lastCarriageReturn = (buf[i] == '\r' ? YES : NO);
	}

	/* In OF_XMLPARSER_IN_TAG, there can be only spaces */
	if (size - last > 0 && state != OF_XMLPARSER_IN_TAG)
		[cache appendCStringWithoutUTF8Checking: buf + last
						 length: size - last];
}

- (void)parseString: (OFString*)str
{
	[self parseBuffer: [str cString]
		 withSize: [str cStringLength]];
}

- (void)parseStream: (OFStream*)stream
{
	char *buf = [self allocMemoryWithSize: of_pagesize];

	@try {
		while (![stream isAtEndOfStream]) {
			size_t len = [stream readNBytes: of_pagesize
					     intoBuffer: buf];

			[self parseBuffer: buf
				 withSize: len];
		}
	} @finally {
		[self freeMemory: buf];
	}
}

- (void)parseFile: (OFString*)path
{
	OFFile *file = [[OFFile alloc] initWithPath: path
					       mode: @"rb"];

	@try {
		[self parseStream: file];
	} @finally {
		[file release];
	}
}

/*
 * The following methods handle the different states of the parser. They are
 * lookup up in +[initialize] and put in a lookup table to speed things up.
 * One dispatch for every character would be way too slow!
 */

/* Not in a tag */
- (void)_parseOutsideTagWithBuffer: (const char*)buf
				 i: (size_t*)i
			      last: (size_t*)last
{
	size_t len;

	if (finishedParsing && buf[*i] != ' ' && buf[*i] != '\t' &&
	    buf[*i] != '\n' && buf[*i] != '\r' && buf[*i] != '<')
		@throw [OFMalformedXMLException newWithClass: isa];

	if (buf[*i] != '<')
		return;

	if ((len = *i - *last) > 0)
		[cache appendCStringWithoutUTF8Checking: buf + *last
						 length: len];

	if ([cache cStringLength] > 0) {
		OFString *str;
		OFAutoreleasePool *pool;

		pool = [[OFAutoreleasePool alloc] init];
		str = transform_string(cache, self);

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
		if (charactersHandler != NULL)
			charactersHandler(self, str);
		else
#endif
			[delegate parser: self
			 foundCharacters: str];

		[pool release];
	}

	[cache setToCString: ""];

	*last = *i + 1;
	state = OF_XMLPARSER_TAG_OPENED;
}

/* Tag was just opened */
- (void)_parseTagOpenedWithBuffer: (const char*)buf
				i: (size_t*)i
			     last: (size_t*)last
{
	if (finishedParsing && buf[*i] != '!')
		@throw [OFMalformedXMLException newWithClass: isa];

	switch (buf[*i]) {
		case '?':
			*last = *i + 1;
			state = OF_XMLPARSER_IN_PROCESSING_INSTRUCTIONS;
			level = 0;
			break;
		case '/':
			*last = *i + 1;
			state = OF_XMLPARSER_IN_CLOSE_TAG_NAME;
			break;
		case '!':
			*last = *i + 1;
			state = OF_XMLPARSER_IN_EXCLAMATIONMARK;
			break;
		default:
			state = OF_XMLPARSER_IN_TAG_NAME;
			(*i)--;
			break;
	}
}

/* Inside prolog */
- (void)_parseInProcessingInstructionsWithBuffer: (const char*)buf
					       i: (size_t*)i
					    last: (size_t*)last
{
	if (buf[*i] == '?')
		level = 1;
	else if (level == 1 && buf[*i] == '>') {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		OFMutableString *pi;
		size_t len;

		[cache appendCStringWithoutUTF8Checking: buf + *last
						 length: *i - *last];
		pi = [[cache mutableCopy] autorelease];
		len = [pi length];

		[pi removeCharactersFromIndex: len - 1
				      toIndex: len];

		/*
		 * Class swizzle the string to be immutable. We pass it as
		 * OFString*, so it can't be modified anyway. But not swizzling
		 * it would create a real copy each time -[copy] is called.
		 */
		pi->isa = [OFString class];

		[delegate parser: self
		    foundProcessingInstructions: pi];

		[pool release];

		[cache setToCString: ""];

		*last = *i + 1;
		state = OF_XMLPARSER_OUTSIDE_TAG;
	} else
		level = 0;
}

/* Inside a tag, no name yet */
- (void)_parseInTagNameWithBuffer: (const char*)buf
				i: (size_t*)i
			     last: (size_t*)last
{
	const char *cache_c, *tmp;
	size_t len, cache_len;

	if (buf[*i] != ' ' && buf[*i] != '\t' && buf[*i] != '\n' &&
	    buf[*i] != '\r' && buf[*i] != '>' && buf[*i] != '/')
		return;

	if ((len = *i - *last) > 0)
		[cache appendCStringWithoutUTF8Checking: buf + *last
						 length: len];

	cache_c = [cache cString];
	cache_len = [cache cStringLength];

	if ((tmp = memchr(cache_c, ':', cache_len)) != NULL) {
		name = [[OFString alloc] initWithCString: tmp + 1
						  length: cache_len -
							  (tmp - cache_c) - 1];
		prefix = [[OFString alloc] initWithCString: cache_c
						    length: tmp - cache_c];
	} else {
		name = [cache copy];
		prefix = nil;
	}

	if (buf[*i] == '>' || buf[*i] == '/') {
		OFAutoreleasePool *pool;
		OFString *ns;

		ns = namespace_for_prefix(prefix, namespaces);

		if (prefix != nil && ns == nil)
			@throw
			    [OFUnboundNamespaceException newWithClass: isa
							       prefix: prefix];

		pool = [[OFAutoreleasePool alloc] init];

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
		if (elementStartHandler != NULL)
			elementStartHandler(self, name, prefix, ns, nil);
		else
#endif
			[delegate parser: self
			 didStartElement: name
			      withPrefix: prefix
			       namespace: ns
			      attributes: nil];

		if (buf[*i] == '/') {
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
			if (elementEndHandler != NULL)
				elementEndHandler(self, name, prefix, ns);
			else
#endif
				[delegate parser: self
				   didEndElement: name
				      withPrefix: prefix
				       namespace: ns];
		} else
			[previous addObject: [[cache copy] autorelease]];

			[pool release];

			[name release];
			[prefix release];
			name = prefix = nil;

			state = (buf[*i] == '/'
			    ? OF_XMLPARSER_EXPECT_CLOSE
			    : OF_XMLPARSER_OUTSIDE_TAG);
	} else
		state = OF_XMLPARSER_IN_TAG;

	if (buf[*i] != '/') {
		OFAutoreleasePool *pool;

		pool = [[OFAutoreleasePool alloc] init];
		[namespaces addObject: [OFMutableDictionary dictionary]];
		[pool release];
	}

	[cache setToCString: ""];
	*last = *i + 1;
}

/* Inside a close tag, no name yet */
- (void)_parseInCloseTagNameWithBuffer: (const char*)buf
				     i: (size_t*)i
				  last: (size_t*)last
{
	OFAutoreleasePool *pool;
	const char *cache_c, *tmp;
	size_t len, cache_len;
	OFString *ns;

	if (buf[*i] != ' ' && buf[*i] != '\t' && buf[*i] != '\n' &&
	    buf[*i] != '\r' && buf[*i] != '>')
		return;

	if ((len = *i - *last) > 0)
		[cache appendCStringWithoutUTF8Checking: buf + *last
						 length: len];
	cache_c = [cache cString];
	cache_len = [cache cStringLength];

	if ((tmp = memchr(cache_c, ':', cache_len)) != NULL) {
		name = [[OFString alloc] initWithCString: tmp + 1
						  length: cache_len -
							  (tmp - cache_c) - 1];
		prefix = [[OFString alloc] initWithCString: cache_c
						    length: tmp - cache_c];
	} else {
		name = [cache copy];
		prefix = nil;
	}

	if (![[previous lastObject] isEqual: cache])
		@throw [OFMalformedXMLException newWithClass: isa];

	[previous removeNObjects: 1];

	[cache setToCString: ""];

	ns = namespace_for_prefix(prefix, namespaces);
	if (prefix != nil && ns == nil)
		@throw [OFUnboundNamespaceException newWithClass: isa
							  prefix: prefix];

	pool = [[OFAutoreleasePool alloc] init];

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	if (elementEndHandler != NULL)
		elementEndHandler(self, name, prefix, ns);
	else
#endif
		[delegate parser: self
		   didEndElement: name
		      withPrefix: prefix
		       namespace: ns];

	[pool release];

	[namespaces removeNObjects: 1];
	[name release];
	[prefix release];
	name = prefix = nil;

	*last = *i + 1;
	state = (buf[*i] == '>'
	    ? OF_XMLPARSER_OUTSIDE_TAG
	    : OF_XMLPARSER_EXPECT_SPACE_OR_CLOSE);

	if ([previous count] == 0)
		finishedParsing = YES;
}

/* Inside a tag, name found */
- (void)_parseInTagWithBuffer: (const char*)buf
			    i: (size_t*)i
			 last: (size_t*)last
{
	OFAutoreleasePool *pool;
	OFString *ns;
	OFXMLAttribute **attrs_c;
	size_t j, attrs_cnt;

	if (buf[*i] != '>' && buf[*i] != '/') {
		if (buf[*i] != ' ' && buf[*i] != '\t' && buf[*i] != '\n' &&
		    buf[*i] != '\r') {
			*last = *i;
			state = OF_XMLPARSER_IN_ATTR_NAME;
			(*i)--;
		}

		return;
	}

	attrs_c = [attrs cArray];
	attrs_cnt = [attrs count];

	ns = namespace_for_prefix(prefix, namespaces);

	if (prefix != nil && ns == nil)
		@throw [OFUnboundNamespaceException newWithClass: isa
							  prefix: prefix];

	for (j = 0; j < attrs_cnt; j++)
		resolve_attr_namespace(attrs_c[j], prefix, ns, namespaces, isa);

	pool = [[OFAutoreleasePool alloc] init];

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	if (elementStartHandler != NULL)
		elementStartHandler(self, name, prefix, ns, attrs);
	else
#endif
		[delegate parser: self
		 didStartElement: name
		      withPrefix: prefix
		       namespace: ns
		      attributes: attrs];

	if (buf[*i] == '/') {
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
		if (elementEndHandler != NULL)
			elementEndHandler(self, name, prefix, ns);
		else
#endif
			[delegate parser: self
			   didEndElement: name
			      withPrefix: prefix
			       namespace: ns];

		[namespaces removeNObjects: 1];
	} else if (prefix != nil) {
		OFString *str = [OFString stringWithFormat: @"%@:%@",
							    prefix, name];
		[previous addObject: str];
	} else
		[previous addObject: name];

	[pool release];

	[name release];
	[prefix release];
	[attrs release];
	name = prefix = nil;
	attrs = nil;

	*last = *i + 1;
	state = (buf[*i] == '/'
	    ? OF_XMLPARSER_EXPECT_CLOSE
	    : OF_XMLPARSER_OUTSIDE_TAG);
}

/* Looking for attribute name */
- (void)_parseInAttributeNameWithBuffer: (const char*)buf
				      i: (size_t*)i
				   last: (size_t*)last
{
	const char *cache_c, *tmp;
	size_t len, cache_len;

	if (buf[*i] != '=')
		return;

	if ((len = *i - *last) > 0)
		[cache appendCStringWithoutUTF8Checking: buf + *last
						 length: len];

	[cache removeLeadingAndTrailingWhitespaces];
	cache_c = [cache cString];
	cache_len = [cache cStringLength];

	if ((tmp = memchr(cache_c, ':', cache_len)) != NULL) {
		attrName = [[OFString alloc] initWithCString: tmp + 1
						      length: cache_len -
							      (tmp - cache_c) -
							      1];
		attrPrefix = [[OFString alloc] initWithCString: cache_c
							length: tmp - cache_c];
	} else {
		attrName = [cache copy];
		attrPrefix = nil;
	}

	[cache setToCString: ""];

	*last = *i + 1;
	state = OF_XMLPARSER_EXPECT_DELIM;
}

/* Expecting delimiter */
- (void)_parseExpectDelimiterWithBuffer: (const char*)buf
				      i: (size_t*)i
				   last: (size_t*)last
{
	*last = *i + 1;

	if (buf[*i] == ' ' || buf[*i] == '\t' || buf[*i] == '\n' ||
	    buf[*i] == '\r')
		return;

	if (buf[*i] != '\'' && buf[*i] != '"')
		@throw [OFMalformedXMLException newWithClass: isa];

	delim = buf[*i];
	state = OF_XMLPARSER_IN_ATTR_VALUE;
}

/* Looking for attribute value */
- (void)_parseInAttributeValueWithBuffer: (const char*)buf
				       i: (size_t*)i
				    last: (size_t*)last
{
	OFAutoreleasePool *pool;
	OFString *attr_val;
	size_t len;

	if (buf[*i] != delim)
		return;

	if ((len = *i - *last) > 0)
		[cache appendCStringWithoutUTF8Checking: buf + *last
						 length: len];

	pool = [[OFAutoreleasePool alloc] init];
	attr_val = transform_string(cache, self);

	if (attrPrefix == nil && [attrName isEqual: @"xmlns"])
		[[namespaces lastObject] setObject: attr_val
					    forKey: @""];
	if ([attrPrefix isEqual: @"xmlns"])
		[[namespaces lastObject] setObject: attr_val
					    forKey: attrName];

	if (attrs == nil)
		attrs = [[OFMutableArray alloc] init];

	[attrs addObject: [OFXMLAttribute attributeWithName: attrName
						  namespace: attrPrefix
						stringValue: attr_val]];

	[pool release];

	[cache setToCString: ""];
	[attrName release];
	[attrPrefix release];
	attrName = attrPrefix = nil;

	*last = *i + 1;
	state = OF_XMLPARSER_IN_TAG;
}

/* Expecting closing '>' */
- (void)_parseExpectCloseWithBuffer: (const char*)buf
				  i: (size_t*)i
			       last: (size_t*)last
{
	if (buf[*i] == '>') {
		*last = *i + 1;
		state = OF_XMLPARSER_OUTSIDE_TAG;
	} else
		@throw [OFMalformedXMLException newWithClass: isa];
}

/* Expecting closing '>' or space */
- (void)_parseExpectSpaceOrCloseWithBuffer: (const char*)buf
					 i: (size_t*)i
				      last: (size_t*)last
{
	if (buf[*i] == '>') {
		*last = *i + 1;
		state = OF_XMLPARSER_OUTSIDE_TAG;
	} else if (buf[*i] != ' ' && buf[*i] != '\t' && buf[*i] != '\n' &&
	    buf[*i] != '\r')
		@throw [OFMalformedXMLException newWithClass: isa];
}

/* In <! */
- (void)_parseInExclamationMarkWithBuffer: (const char*)buf
					i: (size_t*)i
				     last: (size_t*)last
{
	if (finishedParsing && buf[*i] != '-')
		@throw [OFMalformedXMLException newWithClass: isa];

	if (buf[*i] == '-')
		state = OF_XMLPARSER_IN_COMMENT_OPENING;
	else if (buf[*i] == '[') {
		state = OF_XMLPARSER_IN_CDATA_OPENING;
		level = 0;
	} else if (buf[*i] == 'D') {
		state = OF_XMLPARSER_IN_DOCTYPE;
		level = 0;
	} else
		@throw [OFMalformedXMLException newWithClass: isa];

	*last = *i + 1;
}

/* CDATA */
- (void)_parseInCDATAOpeningWithBuffer: (const char*)buf
				     i: (size_t*)i
				  last: (size_t*)last
{
	if (buf[*i] != "CDATA["[level])
		@throw [OFMalformedXMLException newWithClass: isa];

	if (++level == 6) {
		state = OF_XMLPARSER_IN_CDATA_1;
		level = 0;
	}

	*last = *i + 1;
}

- (void)_parseInCDATA1WithBuffer: (const char*)buf
			       i: (size_t*)i
			    last: (size_t*)last
{
	if (buf[*i] == ']')
		level++;
	else
		level = 0;

	if (level == 2)
		state = OF_XMLPARSER_IN_CDATA_2;
}

- (void)_parseInCDATA2WithBuffer: (const char*)buf
			       i: (size_t*)i
			    last: (size_t*)last
{
	OFAutoreleasePool *pool;
	OFMutableString *cdata;
	size_t len;

	if (buf[*i] != '>') {
		state = OF_XMLPARSER_IN_CDATA_1;
		level = (buf[*i] == ']' ? 1 : 0);

		return;
	}

	pool = [[OFAutoreleasePool alloc] init];

	[cache appendCStringWithoutUTF8Checking: buf + *last
					 length: *i - *last];
	cdata = [[cache mutableCopy] autorelease];
	len = [cdata length];

	[cdata removeCharactersFromIndex: len - 2
				 toIndex: len];

	/*
	 * Class swizzle the string to be immutable. We pass it as OFString*, so
	 * it can't be modified anyway. But not swizzling it would create a
	 * real copy each time -[copy] is called.
	 */
	cdata->isa = [OFString class];

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	if (CDATAHandler != NULL)
		CDATAHandler(self, cdata);
	else
#endif
		[delegate parser: self
		      foundCDATA: cdata];

	[pool release];

	[cache setToCString: ""];

	*last = *i + 1;
	state = OF_XMLPARSER_OUTSIDE_TAG;
}

/* Comment */
- (void)_parseInCommentOpeningWithBuffer: (const char*)buf
				       i: (size_t*)i
				    last: (size_t*)last
{
	if (buf[*i] != '-')
		@throw [OFMalformedXMLException newWithClass: isa];

	*last = *i + 1;
	state = OF_XMLPARSER_IN_COMMENT_1;
	level = 0;
}

- (void)_parseInComment1WithBuffer: (const char*)buf
				 i: (size_t*)i
			      last: (size_t*)last
{
	if (buf[*i] == '-')
		level++;
	else
		level = 0;

	if (level == 2)
		state = OF_XMLPARSER_IN_COMMENT_2;
}

- (void)_parseInComment2WithBuffer: (const char*)buf
				 i: (size_t*)i
			      last: (size_t*)last
{
	OFAutoreleasePool *pool;
	OFMutableString *comment;
	size_t len;

	if (buf[*i] != '>')
		@throw [OFMalformedXMLException newWithClass: isa];

	pool = [[OFAutoreleasePool alloc] init];

	[cache appendCStringWithoutUTF8Checking: buf + *last
					 length: *i - *last];
	comment = [[cache mutableCopy] autorelease];
	len = [comment length];

	[comment removeCharactersFromIndex: len - 2
				   toIndex: len];

	/*
	 * Class swizzle the string to be immutable. We pass it as OFString*, so
	 * it can't be modified anyway. But not swizzling it would create a
	 * real copy each time -[copy] is called.
	 */
	comment->isa = [OFString class];

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	if (commentHandler != NULL)
		commentHandler(self, comment);
	else
#endif
		[delegate parser: self
		    foundComment: comment];

	[pool release];

	[cache setToCString: ""];

	*last = *i + 1;
	state = OF_XMLPARSER_OUTSIDE_TAG;
}

/* In <!DOCTYPE ...> */
- (void)_parseInDoctypeWithBuffer: (const char*)buf
				i: (size_t*)i
			     last: (size_t*)last
{
	if ((level < 6 && buf[*i] != "OCTYPE"[level]) ||
	    (level == 6 && buf[*i] != ' ' && buf[*i] != '\t' &&
	    buf[*i] != '\n' && buf[*i] != '\r'))
		@throw [OFMalformedXMLException newWithClass: isa];

	if (level < 7 || buf[*i] == '<')
		level++;

	if (buf[*i] == '>') {
		if (level == 7)
			state = OF_XMLPARSER_OUTSIDE_TAG;
		else
			level--;
	}

	*last = *i + 1;
}

- (size_t)lineNumber
{
	return lineNumber;
}

- (BOOL)finishedParsing
{
	return finishedParsing;
}

-	   (OFString*)string: (OFString*)string
  containsUnknownEntityNamed: (OFString*)entity
{
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	if (unknownEntityHandler != NULL)
		return unknownEntityHandler(self, entity);
#endif

	return [delegate parser: self
	foundUnknownEntityNamed: entity];
}
@end

@implementation OFObject (OFXMLParserDelegate)
-		 (void)parser: (OFXMLParser*)parser
  foundProcessingInstructions: (OFString*)pi
{
}

-    (void)parser: (OFXMLParser*)parser
  didStartElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attrs
{
}

-  (void)parser: (OFXMLParser*)parser
  didEndElement: (OFString*)name
     withPrefix: (OFString*)prefix
      namespace: (OFString*)ns
{
}

-    (void)parser: (OFXMLParser*)parser
  foundCharacters: (OFString*)string
{
}

- (void)parser: (OFXMLParser*)parser
    foundCDATA: (OFString*)cdata
{
}

- (void)parser: (OFXMLParser*)parser
  foundComment: (OFString*)comment
{
}

-	(OFString*)parser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity
{
	return nil;
}
@end
