//
//  AMHttpResponseExtraInfo.h
//  pinduoduo
//
//  Created by Calvin on 2018/8/22.
//  Copyright © 2018年 Calvin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMHttpResponseExtraInfo : NSObject

@property(strong, nonatomic) NSNumber *speedDownload; // @synthesize speedDownload=_speedDownload;
@property(strong, nonatomic) NSNumber *speedUpload; // @synthesize speedUpload=_speedUpload;
@property(strong, nonatomic) NSNumber *sizeDownload; // @synthesize sizeDownload=_sizeDownload;
@property(strong, nonatomic) NSNumber *sizeUpload; // @synthesize sizeUpload=_sizeUpload;
@property(strong, nonatomic) NSNumber *connectTime; // @synthesize connectTime=_connectTime;
@property(assign, nonatomic) NSNumber *nameLookUpTime; // @synthesize nameLookUpTime=_nameLookUpTime;
@property(copy, nonatomic) NSString *primaryIP; // @synthesize primaryIP=_primaryIP;
@property(copy, nonatomic) NSString *localIP; // @synthesize localIP=_localIP;
@property(strong, nonatomic) NSNumber *totalTime; // @synthesize totalTime=_totalTime;
@property(copy, nonatomic) NSString *effectiveURL; // @synthesize effectiveURL=_effectiveURL;

@end

NS_ASSUME_NONNULL_END
