//
//  AMHTTPResponse.h
//  pinduoduo
//
//  Created by Calvin on 2018/8/22.
//  Copyright © 2018年 Calvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMHttpResponseExtraInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMHTTPResponse : NSObject


@property(retain, nonatomic) AMHttpResponseExtraInfo *extraInfo; // @synthesize extraInfo=_extraInfo;
@property(strong, nonatomic) NSData *responseData; // @synthesize responseData=_responseData;

@property(strong, nonatomic) NSDictionary *headers; // @synthesize headers=_headers;

@property(nonatomic,assign) int statusCode; // @synthesize statusCode=_statusCode;

@end

NS_ASSUME_NONNULL_END
