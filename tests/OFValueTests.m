//
//  TestsAppDelegate+OFValueTests.m
//  ObjFW
//
//  Created by Yury Vovk on 03.11.2017.
//
//

#include "config.h"

#import "OFValue.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFMemoryNotPartOfObjectException.h"
#import "OFOutOfMemoryException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFValue";

struct _OFValueStruct {
    int a;
    char b;
    struct {
        float x;
        float y;
    };
    double z[10];
};

@implementation TestsAppDelegate (OFValueTests)
- (void)ValueTest
{
    OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
    
    OFValue *v1, *v2, *v3, *v4;
    int i1 = 5;
    float f2 = 23.9;
    short sh3 = 1024;
    const char *str4 = "str4";
    
    TEST(@"+[OFValue value:withObjCType:]",
         R(v1 = [OFValue value:&i1 withObjCType:@encode(int)]) &&
         R(v2 = [OFValue value:&f2 withObjCType:@encode(float)]) &&
         R(v3 = [OFValue value:&sh3 withObjCType:@encode(short)]) &&
         R(v4 = [OFValue value:&str4 withObjCType:@encode(const char *)]));
    
    TEST(@"+[OFValue valueWithBytes:objCType:]",
         R(v1 = [OFValue valueWithBytes:&i1 objCType:@encode(int)]) &&
         R(v2 = [OFValue valueWithBytes:&f2 objCType:@encode(float)]) &&
         R(v3 = [OFValue valueWithBytes:&sh3 objCType:@encode(short)]) &&
         R(v4 = [OFValue valueWithBytes:&str4 objCType:@encode(const char *)]))
    
    of_range_t range = of_range(0, 100);
    of_point_t point = of_point(10.0, 25.5);
    of_dimension_t size = of_dimension(100.0, 57.1);
    of_rectangle_t rect = of_rectangle(1.0, 0.0, 250.0, 125.0);
    
    TEST(@"+[OFValue valueWithRange:]",
         R(v1 = [OFValue valueWithRange:range]));
    TEST(@"-[OFValue rangeValue]",
         ([v1 rangeValue].location == range.location) &&
         ([v1 rangeValue].length == range.length));
    
    TEST(@"+[OFValue valueWithPoint:]",
         R(v2 = [OFValue valueWithPoint:point]));
    TEST(@"-[OFValue pointValue]",
         ([v2 pointValue].x == point.x) &&
         ([v2 pointValue].y == point.y));
    
    TEST(@"+[OFValue valueWithSize:]",
         R(v3 = [OFValue valueWithSize:size]));
    TEST(@"-[OFValue sizeValue]",
         ([v3 sizeValue].width == size.width) &&
         ([v3 sizeValue].height == size.height));
    
    of_point_t rect_origin;
    of_dimension_t rect_size;
    TEST(@"+[OFValue valueWithRect:]",
         R(v4 = [OFValue valueWithRect:rect]));
    TEST(@"-[OFValue rectValue]",
         R(rect_origin = [v4 rectValue].origin) &&
         R(rect_size = [v4 rectValue].size) &&
         (rect_origin.x == 1.0) &&
         (rect_origin.y == 0.0) &&
         (rect_size.width == 250.0) &&
         (rect_size.height == 125.0));
    
    memset(&rect_origin, 0, sizeof(of_point_t));
    [v4 getValue:&rect_origin size:of_sizeof_type_encoding(@encode(of_point_t))];
    
    TEST(@"-[OFValue getValue:size:]",
         memcmp(&rect_origin, &(rect.origin), sizeof(of_point_t)) == 0);
    
    
    TEST(@"+[OFValue valueWithPointer:]",
         R(v1 = [OFValue valueWithPointer:str4]));
    TEST(@"-[OFValue pointerValue]",
         (strcmp((const char *)[v1 pointerValue], str4)) == 0);
    
    OFString *obj = [OFString stringWithUTF8String:"OFValue"];
    TEST(@"+[OFValue valueWithNonretainedObject:]",
         R(v2 = [OFValue valueWithNonretainedObject:obj]));
    TEST(@"-[OFValue nonretainedObjectValue]",
         ([obj isEqual:[v2 nonretainedObjectValue]]));
    
    struct _OFValueStruct OFValueStruct = {
        25,
        'z',
        {
            22.0,
            10.9
        },
        {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 9.0, 10.0}
    };
    
    struct _OFValueStruct OFValueStruct2 = {0};
    
    TEST(@"OFValue with custom structure",
         R(v3 = [OFValue valueWithBytes:&OFValueStruct objCType:@encode(struct _OFValueStruct)]));
    [v3 getValue:&OFValueStruct2];
    TEST(@"OFValue get custom structure",
         ((memcmp(&OFValueStruct, &OFValueStruct2, sizeof(struct _OFValueStruct))) == 0) &&
         (sizeof(struct _OFValueStruct) != 0));
    
    [pool drain];
}
@end
