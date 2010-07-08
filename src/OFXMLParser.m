/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>
#include <unistd.h>

#import "OFXMLParser.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFXMLAttribute.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "macros.h"

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

@implementation OFXMLParser
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
		[pool release];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[delegate release];

	[cache release];
	[name release];
	[prefix release];
	[namespaces release];
	[attrs release];
	[attrName release];
	[attrPrefix release];
	[previous release];

	[super dealloc];
}

- (OFObject <OFXMLParserDelegate>*)delegate
{
	return [[delegate retain] autorelease];
}

- (void)setDelegate: (OFObject <OFXMLParserDelegate>*)delegate_
{
	[delegate_ retain];
	[delegate release];
	delegate = delegate_;
}

- (void)parseBuffer: (const char*)buf
	   withSize: (size_t)size
{
	OFAutoreleasePool *pool;
	size_t i, last, len;

	last = 0;

	for (i = 0; i < size; i++) {
		switch (state) {
		/* Not in a tag */
		case OF_XMLPARSER_OUTSIDE_TAG:
			if (buf[i] == '<') {
				len = i - last;

				if (len > 0)
					[cache appendCStringWithoutUTF8Checking:
					    buf + last
					    length: len];

				if ([cache cStringLength] > 0) {
					OFString *str;

					pool = [[OFAutoreleasePool alloc] init];
					str = transform_string(cache, self);
					[delegate parser: self
					 foundCharacters: str];
					[pool release];
				}

				[cache setToCString: ""];

				last = i + 1;
				state = OF_XMLPARSER_TAG_OPENED;
			}
			break;

		/* Tag was just opened */
		case OF_XMLPARSER_TAG_OPENED:
			switch (buf[i]) {
			case '?':
				last = i + 1;
				state = OF_XMLPARSER_IN_PROLOG;
				break;
			case '/':
				last = i + 1;
				state = OF_XMLPARSER_IN_CLOSE_TAG_NAME;
				break;
			case '!':
				last = i + 1;
				state = OF_XMLPARSER_IN_CDATA_OR_COMMENT;
				break;
			default:
				state = OF_XMLPARSER_IN_TAG_NAME;
				i--;
				break;
			}
			break;

		/* Inside prolog */
		case OF_XMLPARSER_IN_PROLOG:
			last = i + 1;
			if (buf[i] == '?')
				state = OF_XMLPARSER_EXPECT_CLOSE;
			break;

		/* Inside a tag, no name yet */
		case OF_XMLPARSER_IN_TAG_NAME:
			if (buf[i] == ' ' || buf[i] == '\n' || buf[i] == '\r' ||
			    buf[i] == '>' || buf[i] == '/') {
				const char *cache_c, *tmp;
				size_t cache_len;

				len = i - last;
				if (len > 0)
					[cache appendCStringWithoutUTF8Checking:
					    buf + last
					    length: len];
				cache_c = [cache cString];
				cache_len = [cache cStringLength];

				if ((tmp = memchr(cache_c, ':',
				    cache_len)) != NULL) {
					name = [[OFString alloc]
					    initWithCString: tmp + 1
						     length: cache_len - (tmp -
							     cache_c) - 1];
					prefix = [[OFString alloc]
					    initWithCString: cache_c
						     length: tmp - cache_c];
				} else {
					name = [cache copy];
					prefix = nil;
				}

				if (buf[i] == '>' || buf[i] == '/') {
					OFString *ns;

					ns = namespace_for_prefix(prefix,
					    namespaces);

					if (prefix != nil && ns == nil)
						@throw
						    [OFUnboundNamespaceException
						    newWithClass: isa
							  prefix: prefix];

					pool = [[OFAutoreleasePool alloc] init];

					[delegate parser: self
					 didStartElement: name
					      withPrefix: prefix
					       namespace: ns
					      attributes: nil];

					if (buf[i] == '/')
						[delegate parser: self
						   didEndElement: name
						      withPrefix: prefix
						       namespace: ns];
					else
						[previous addObject:
						    [[cache copy] autorelease]];

					[pool release];

					[name release];
					[prefix release];
					name = prefix = nil;

					state = (buf[i] == '/'
					    ? OF_XMLPARSER_EXPECT_CLOSE
					    : OF_XMLPARSER_OUTSIDE_TAG);
				} else
					state = OF_XMLPARSER_IN_TAG;

				if (buf[i] != '/') {
					pool = [[OFAutoreleasePool alloc] init];
					[namespaces addObject:
					    [OFMutableDictionary dictionary]];
					[pool release];
				}

				[cache setToCString: ""];
				last = i + 1;
			}
			break;

		/* Inside a close tag, no name yet */
		case OF_XMLPARSER_IN_CLOSE_TAG_NAME:
			if (buf[i] == ' ' || buf[i] == '\n' || buf[i] == '\r' ||
			    buf[i] == '>') {
				const char *cache_c, *tmp;
				size_t cache_len;
				OFString *ns;

				len = i - last;
				if (len > 0)
					[cache appendCStringWithoutUTF8Checking:
					    buf + last
					    length: len];
				cache_c = [cache cString];
				cache_len = [cache cStringLength];

				if ((tmp = memchr(cache_c, ':',
				    cache_len)) != NULL) {
					name = [[OFString alloc]
					    initWithCString: tmp + 1
						     length: cache_len - (tmp -
							     cache_c) - 1];
					prefix = [[OFString alloc]
					    initWithCString: cache_c
						     length: tmp - cache_c];
				} else {
					name = [cache copy];
					prefix = nil;
				}

				if (![[previous lastObject] isEqual: cache])
					@throw [OFMalformedXMLException
					    newWithClass: isa];
				[previous removeNObjects: 1];

				[cache setToCString: ""];

				ns = namespace_for_prefix(prefix, namespaces);
				if (prefix != nil && ns == nil)
					@throw [OFUnboundNamespaceException
					    newWithClass: isa
						  prefix: prefix];

				pool = [[OFAutoreleasePool alloc] init];

				[delegate parser: self
				   didEndElement: name
				      withPrefix: prefix
				       namespace: ns];

				[pool release];

				[namespaces removeNObjects: 1];
				[name release];
				[prefix release];
				name = prefix = nil;

				last = i + 1;
				state = (buf[i] == '>'
				    ? OF_XMLPARSER_OUTSIDE_TAG
				    : OF_XMLPARSER_EXPECT_SPACE_OR_CLOSE);
			}
			break;

		/* Inside a tag, name found */
		case OF_XMLPARSER_IN_TAG:
			if (buf[i] == '>' || buf[i] == '/') {
				OFString *ns;

				ns = namespace_for_prefix(prefix, namespaces);

				if (prefix != nil && ns == nil)
					@throw [OFUnboundNamespaceException
					    newWithClass: isa
						  prefix: prefix];

				pool = [[OFAutoreleasePool alloc] init];

				[delegate parser: self
				 didStartElement: name
				      withPrefix: prefix
				       namespace: ns
				      attributes: attrs];

				if (buf[i] == '/') {
					[delegate parser: self
					   didEndElement: name
					      withPrefix: prefix
					       namespace: ns];
					[namespaces removeNObjects: 1];
				} else if (prefix != nil) {
					OFString *str = [OFString
					    stringWithFormat: @"%s:%s",
							      [prefix cString],
							      [name cString]];
					[previous addObject: str];
				} else
					[previous addObject: name];

				[pool release];

				[name release];
				[prefix release];
				[attrs release];
				name = prefix = nil;
				attrs = nil;

				last = i + 1;
				state = (buf[i] == '/'
				    ? OF_XMLPARSER_EXPECT_CLOSE
				    : OF_XMLPARSER_OUTSIDE_TAG);
			} else if (buf[i] != ' ' && buf[i] != '\n' &&
			    buf[i] != '\r') {
				last = i;
				state = OF_XMLPARSER_IN_ATTR_NAME;
				i--;
			}
			break;

		/* Looking for attribute name */
		case OF_XMLPARSER_IN_ATTR_NAME:
			if (buf[i] == '=') {
				const char *cache_c, *tmp;
				size_t cache_len;

				len = i - last;
				if (len > 0)
					[cache appendCStringWithoutUTF8Checking:
					    buf + last
					    length: len];

				cache_c = [cache cString];
				cache_len = [cache cStringLength];

				if ((tmp = memchr(cache_c, ':',
				    cache_len)) != NULL ) {
					attrName = [[OFString alloc]
					    initWithCString: tmp + 1
						     length: cache_len - (tmp -
							     cache_c) - 1];
					attrPrefix = [[OFString alloc]
					    initWithCString: cache_c
						     length: tmp - cache_c];
				} else {
					attrName = [cache copy];
					attrPrefix = nil;
				}

				[cache setToCString: ""];

				last = i + 1;
				state = OF_XMLPARSER_EXPECT_DELIM;
			}
			break;

		/* Expecting delimiter */
		case OF_XMLPARSER_EXPECT_DELIM:
			if (buf[i] != '\'' && buf[i] != '"')
				@throw [OFMalformedXMLException
				    newWithClass: isa];

			delim = buf[i];
			last = i + 1;
			state = OF_XMLPARSER_IN_ATTR_VALUE;
			break;

		/* Looking for attribute value */
		case OF_XMLPARSER_IN_ATTR_VALUE:
			if (buf[i] == delim) {
				OFString *attr_ns;
				OFString *attr_val;

				len = i - last;
				if (len > 0)
					[cache appendCStringWithoutUTF8Checking:
					    buf + last
					    length: len];

				pool = [[OFAutoreleasePool alloc] init];
				attr_ns = namespace_for_prefix(
				    (attrPrefix != nil ? attrPrefix : prefix),
				    namespaces);
				attr_val = transform_string(cache, self);

				if (attrPrefix == nil &&
				    [attrName isEqual: @"xmlns"]) {
					[[namespaces lastObject]
					    setObject: attr_val
					       forKey: @""];
					attr_ns = nil;
				}
				if ([attrPrefix isEqual: @"xmlns"])
					[[namespaces lastObject]
					    setObject: attr_val
					       forKey: attrName];

				if (attrs == nil)
					attrs = [[OFMutableArray alloc] init];

				[attrs addObject: [OFXMLAttribute
				    attributeWithName: attrName
					    namespace: attr_ns
					  stringValue: attr_val]];

				[pool release];

				[cache setToCString: ""];
				[attrName release];
				[attrPrefix release];
				attrName = attrPrefix = nil;

				last = i + 1;
				state = OF_XMLPARSER_IN_TAG;
			}
			break;

		/* Expecting closing '>' */
		case OF_XMLPARSER_EXPECT_CLOSE:
			if (buf[i] == '>') {
				last = i + 1;
				state = OF_XMLPARSER_OUTSIDE_TAG;
			} else
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			break;

		/* Expecting closing '>' or space */
		case OF_XMLPARSER_EXPECT_SPACE_OR_CLOSE:
			if (buf[i] == '>') {
				last = i + 1;
				state = OF_XMLPARSER_OUTSIDE_TAG;
			} else if (buf[i] != ' ' && buf[i] != '\n' &&
			    buf[i] != '\r')
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			break;

		/* CDATA or comment */
		case OF_XMLPARSER_IN_CDATA_OR_COMMENT:
			if (buf[i] == '-')
				state = OF_XMLPARSER_IN_COMMENT_OPENING;
			else if (buf[i] == '[')
				state = OF_XMLPARSER_IN_CDATA_OPENING_1;
			else
				@throw [OFMalformedXMLException
				    newWithClass: isa];

			last = i + 1;
			break;

		/* CDATA */
		case OF_XMLPARSER_IN_CDATA_OPENING_1:
			if (buf[i] == 'C')
				state = OF_XMLPARSER_IN_CDATA_OPENING_2;
			else
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			last = i + 1;
			break;
		case OF_XMLPARSER_IN_CDATA_OPENING_2:
			if (buf[i] == 'D')
				state = OF_XMLPARSER_IN_CDATA_OPENING_3;
			else
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			last = i + 1;
			break;
		case OF_XMLPARSER_IN_CDATA_OPENING_3:
			if (buf[i] == 'A')
				state = OF_XMLPARSER_IN_CDATA_OPENING_4;
			else
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			last = i + 1;
			break;
		case OF_XMLPARSER_IN_CDATA_OPENING_4:
			if (buf[i] == 'T')
				state = OF_XMLPARSER_IN_CDATA_OPENING_5;
			else
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			last = i + 1;
			break;
		case OF_XMLPARSER_IN_CDATA_OPENING_5:
			if (buf[i] == 'A')
				state = OF_XMLPARSER_IN_CDATA_OPENING_6;
			else
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			last = i + 1;
			break;
		case OF_XMLPARSER_IN_CDATA_OPENING_6:
			if (buf[i] == '[')
				state = OF_XMLPARSER_IN_CDATA_1;
			else
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			last = i + 1;
			break;
		case OF_XMLPARSER_IN_CDATA_1:
			if (buf[i] == ']')
				state = OF_XMLPARSER_IN_CDATA_2;
			break;
		case OF_XMLPARSER_IN_CDATA_2:
			if (buf[i] == ']')
				state = OF_XMLPARSER_IN_CDATA_3;
			else
				state = OF_XMLPARSER_IN_CDATA_1;
			break;
		case OF_XMLPARSER_IN_CDATA_3:
			if (buf[i] == '>') {
				OFMutableString *cdata;
				size_t len;

				pool = [[OFAutoreleasePool alloc] init];

				[cache
				    appendCStringWithoutUTF8Checking: buf + last
							      length: i - last];
				cdata = [[cache mutableCopy] autorelease];
				len = [cdata length];

				[cdata removeCharactersFromIndex: len - 2
							 toIndex: len];
				[delegate parser: self
				      foundCDATA: cdata];
				[pool release];

				[cache setToCString: ""];

				last = i + 1;
				state = OF_XMLPARSER_OUTSIDE_TAG;
			} else if (buf[i] != ']')
				state = OF_XMLPARSER_IN_CDATA_1;
			break;

		/* Comment */
		case OF_XMLPARSER_IN_COMMENT_OPENING:
			if (buf[i] != '-')
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			last = i + 1;
			state = OF_XMLPARSER_IN_COMMENT_1;
			break;
		case OF_XMLPARSER_IN_COMMENT_1:
			if (buf[i] == '-')
				state = OF_XMLPARSER_IN_COMMENT_2;
			break;
		case OF_XMLPARSER_IN_COMMENT_2:
			state = (buf[i] == '-' ? OF_XMLPARSER_IN_COMMENT_3 :
			    OF_XMLPARSER_IN_COMMENT_1);
			break;
		case OF_XMLPARSER_IN_COMMENT_3:
			if (buf[i] == '>') {
				OFMutableString *comment;
				size_t len;

				pool = [[OFAutoreleasePool alloc] init];

				[cache
				    appendCStringWithoutUTF8Checking: buf + last
							      length: i - last];
				comment = [[cache mutableCopy] autorelease];
				len = [comment length];

				[comment removeCharactersFromIndex: len - 2
							   toIndex: len];
				[delegate parser: self
				    foundComment: comment];
				[pool release];

				[cache setToCString: ""];

				last = i + 1;
				state = OF_XMLPARSER_OUTSIDE_TAG;
			} else
				@throw [OFMalformedXMLException
				    newWithClass: isa];

			break;
		}
	}

	len = size - last;
	/* In OF_XMLPARSER_IN_TAG, there can be only spaces */
	if (len > 0 && state != OF_XMLPARSER_IN_TAG)
		[cache appendCStringWithoutUTF8Checking: buf + last
						 length: len];
}

-	   (OFString*)string: (OFString*)string
  containsUnknownEntityNamed: (OFString*)entity
{
	return [delegate parser: self
	foundUnknownEntityNamed: entity];
}
@end

@implementation OFObject (OFXMLParserDelegate)
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
