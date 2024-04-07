//
//  SecondViewController.m
//  LFLiveKitFrameworkDemo
//
//  Created by admin on 2016/10/20.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "PushViewController.h"
#import "LFLivePreview.h"

@interface PushViewController ()

@property(nonatomic,strong) LFLivePreview *liveView;

@end

@implementation PushViewController {
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
}


- (void)dealloc
{
    [_liveView stopLive];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _liveView = [[LFLivePreview alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_liveView];
    _liveView.pushURL = self.server;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}


@end
