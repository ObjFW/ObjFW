//
//  OFValue__adjacent.h
//
//  Created by Юрий Вовк on 02.11.2017.
//

#import "OFValue.h"

@interface OFValue_adjacent : OFValue
{
    const char *_objCType;
    void *_data;
    size_t _dataSize;
}

@end
