//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  pinduoduoDylib.m
//  pinduoduoDylib
//
//  Created by Calvin on 2018/8/22.
//  Copyright (c) 2018年 Calvin. All rights reserved.
//

#import "pinduoduoDylib.h"
#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>
#import <Cycript/Cycript.h>
#import <MDCycriptManager.h>
#import "CTBlockDescription.h"

CHConstructor{
    NSLog(INSERT_SUCCESS_WELCOME);
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        
#ifndef __OPTIMIZE__
        CYListenServer(6666);

        MDCycriptManager* manager = [MDCycriptManager sharedInstance];
        [manager loadCycript:NO];

        NSError* error;
        NSString* result = [manager evaluateCycript:@"UIApp" error:&error];
        NSLog(@"result: %@", result);
        if(error.code != 0){
            NSLog(@"error: %@", error.localizedDescription);
        }
#endif
        
    }];
}


CHDeclareClass(CustomViewController)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

//add new method
CHDeclareMethod1(void, CustomViewController, newMethod, NSString*, output){
    NSLog(@"This is a new method : %@", output);
}

#pragma clang diagnostic pop

CHOptimizedClassMethod0(self, void, CustomViewController, classMethod){
    NSLog(@"hook class method");
    CHSuper0(CustomViewController, classMethod);
}

CHOptimizedMethod0(self, NSString*, CustomViewController, getMyName){
    //get origin value
    NSString* originName = CHSuper(0, CustomViewController, getMyName);
    
    NSLog(@"origin name is:%@",originName);
    
    //get property
    NSString* password = CHIvar(self,_password,__strong NSString*);
    
    NSLog(@"password is %@",password);
    
    [self newMethod:@"output"];
    
    //set new property
    self.newProperty = @"newProperty";
    
    NSLog(@"newProperty : %@", self.newProperty);
    
    //change the value
    return @"Calvin";
    
}

//add new property
CHPropertyRetainNonatomic(CustomViewController, NSString*, newProperty, setNewProperty);

CHConstructor{
    CHLoadLateClass(CustomViewController);
    CHClassHook0(CustomViewController, getMyName);
    CHClassHook0(CustomViewController, classMethod);
    
    CHHook0(CustomViewController, newProperty);
    CHHook1(CustomViewController, setNewProperty);
}

@interface PDDCategoryChildViewController : UIViewController

@property(copy, nonatomic) NSArray *goodsList; // 商品list

@property(nonatomic) long long currentPage; // 页码

@property(retain, nonatomic) UICollectionView *collectionView;

- (void)doRequest; // 请求数据方法

@end


CHDeclareClass(PDDCategoryChildViewController);

CHOptimizedMethod0(self, void, PDDCategoryChildViewController, viewDidLoad){
    
    CHSuper0(PDDCategoryChildViewController, viewDidLoad);
    
    [self doRequest]; // 开始就去请求数据
}

CHOptimizedMethod0(self, void, PDDCategoryChildViewController, doRequest){
    
    
    CHSuper0(PDDCategoryChildViewController, doRequest); // 原始方法去请求数据
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),  dispatch_get_main_queue(), ^{

        // 延迟三秒再次去请求
        [self doRequest];

    });
}


CHConstructor{
    
    CHLoadLateClass(PDDCategoryChildViewController);

    CHClassHook0(PDDCategoryChildViewController, viewDidLoad);
    
    CHClassHook0(PDDCategoryChildViewController, doRequest);
}


typedef void(^apiSuccessBlock)(NSError *error, id _Nullable responseObject); // block类型在ida中观察--难点

@interface HTTPBaseService : NSObject

- (void)get:(id)arg1 parameters:(id)arg2 onJsonResponse:(apiSuccessBlock)arg3;

- (void)httpMethod:(id)arg1 relativeUrl:(id)arg2 parameters:(id)arg3 onResponse:(id)arg4; // 此方法为底层网络请求的方法

/**
 
 AMHTTPResponse 类是 onResponse block 中的一个参数 可拿到更多数据 如下载速度 url 以及状态码等
 
 */

@property(retain, nonatomic) NSURL *baseURL;

@end

CHDeclareClass(HTTPBaseService);


CHOptimizedMethod3(self, void, HTTPBaseService, get, id, arg1, parameters, id, arg2, onJsonResponse,apiSuccessBlock,arg3){

    apiSuccessBlock block;

    block = ^(NSError *error, id  _Nullable responseObject) {
        
        NSString *jsonStr = responseObject;
        NSLog(@"error = %@",jsonStr); // 此处是json数据  根据需求做处理
        
        CHSuper3(HTTPBaseService, get, arg1, parameters, arg2, onJsonResponse, arg3); // 让页面显示出来
        
    };
    
    CHSuper3(HTTPBaseService, get, arg1, parameters, arg2, onJsonResponse, block); // 替换为自己的block
    
    /**
     
     很简单 基本都是IDA静态分析 动态调试都没用到 我万万没想到的是敢骗三亿人的App居然用的是HTTP ROTFL
     
     */
}

CHConstructor{
    CHLoadLateClass(HTTPBaseService);
    
    CHClassHook3(HTTPBaseService, get, parameters, onJsonResponse);
}
