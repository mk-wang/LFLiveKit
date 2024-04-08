//
//  SecondViewController.h
//  LFLiveKitFrameworkDemo
//
//  Created by admin on 2016/10/20.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LFLivePreview;
@interface PushViewController : UIViewController

@property (nonatomic, strong) NSString *server;

- (void)commonInit;

- (LFLivePreview *)liveView;

@end
