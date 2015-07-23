//
//  ViewController.m
//  XWCycleScrollView
//
//  Created by Zhang Xiaowei on 15/7/23.
//  Copyright (c) 2015年 Zhang Xiaowei. All rights reserved.
//

#import "ViewController.h"
#import "XWCycleScrollView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSMutableArray *views = [NSMutableArray array];
    for (NSUInteger i = 0; i < 10; i++) {
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
        view.backgroundColor = [UIColor XW_RANDOM_COLOR];
        [views addObject:view];
    }
    XWCycleScrollView *xwCycleView = [[XWCycleScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)
                                                             xwCycleDirection:XWCycleDirectionVertical
                                                                     withView:views];
    xwCycleView.backgroundColor = [UIColor XW_RANDOM_COLOR];
    [self.view addSubview:xwCycleView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
