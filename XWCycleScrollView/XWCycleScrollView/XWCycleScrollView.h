//
//  XWCycleScrollView.h
//  XWCycleScrollView
//
//  Created by Zhang Xiaowei on 15/7/23.
//  Copyright (c) 2015年 Zhang Xiaowei. All rights reserved.
//

#import <UIKit/UIKit.h>
#define XW_RANDOM_COLOR  colorWithRed:(arc4random()%225)/225.0 green:(arc4random()%225)/225.0 blue:(arc4random()%225)/225.0 alpha:(arc4random()%225)/225.0

typedef NS_ENUM(NSInteger, XWCycleDirection) {
    XWCycleDirectionVertical     = 0,          // 垂直滚动
    XWCycleDirectionHorizontal   = 1           // 水平滚动
};

typedef NS_ENUM(NSInteger, XWHandleRollingDirection) {
    XWHandeleRollingDirectionLeft    = -1,
    XWHandleRollingDirectionRight    = 1,
    XWHandleRollingDirectionUp       = -2,
    XWHandleRollingDirectionDown     = 2
};

@protocol XWCycleScrollViewDelegate;

@interface XWCycleScrollView : UIView <UIScrollViewDelegate>

// 设置imgsUrl时，不可为空
@property (nonatomic, strong) NSMutableArray * viewsArray;  // view数据源
@property (nonatomic, assign) NSInteger currentPage;        // 当前页

@property (nonatomic, strong) id<XWCycleScrollViewDelegate> delegate;



#pragma mark - 初始化方法
- (XWCycleScrollView *)initWithFrame:(CGRect)frame
                    xwCycleDirection:(XWCycleDirection)direction
                            withView:(NSArray *)viewsArray;

- (XWCycleScrollView *)initWithFrame:(CGRect)frame
                    xwCycleDirection:(XWCycleDirection)direction
                            withView:(NSArray *)viewsArray
                       withStartPage:(NSUInteger)startPage;

- (XWCycleScrollView *)initWithFrame:(CGRect)frame
                    xwCycleDirection:(XWCycleDirection)direction
                            withView:(NSArray *)viewsArray
                       withStartPage:(NSUInteger)startPage
                   isShowPageControl:(BOOL)isShowPageControl;

#pragma mark - 插入UIView

- (BOOL)insertView:(UIView*)willInsertedView
           atIndex:(NSUInteger)atIndex
         isRefresh:(BOOL) isRefresh;

- (BOOL)insertViews:(NSArray*)willInsertedViews
            atIndex:(NSUInteger)atIndex
          isRefresh:(BOOL) isRefresh;

#pragma mark - 删除UIView

- (BOOL)removeObjectWithIndex:(NSUInteger)index;  // 删除指定索引的对象

- (BOOL)removeObjectWithView:(UIView *)willRemovedView;  // 删除指定对象

- (BOOL)removeObjectsWithViews:(NSArray*)willRemovedViews; // 删除多个对象


#pragma mark - 定时器相关
- (void)setTimerInterval:(CGFloat)timerInterval;  // 设置定时器时间间隔

- (void)startAutoScrolling:(CGFloat)animationDuration;  // 开启自动滚动
- (void)startAutoScroll;  // 启动自动滚动

- (void)stopAutoScroll;  // 停止自动滚动
- (void)stopAutoScrolling;  // 停止自动滚动

#pragma mark - 刷新视图
- (void)refreshView;  // 刷新视图
- (void)refreshViewWithPage:(NSUInteger)page;

@end




#pragma mark - XWCycleScrollViewDelegate

@protocol XWCycleScrollViewDelegate <NSObject>

@optional

// 保留原来的两个协议方法
- (void)xwCycleScrollViewDelegate:(XWCycleScrollView *)xwCycleScrollView
                 didSelectedIndex:(NSUInteger)currentIndex;

- (void)xwCycleScrollViewDelegate:(XWCycleScrollView *)xwCycleScrollView
                 didScrollToIndex:(NSUInteger)currentIndex;

// 新增两个协议方法
- (void)xwCycleScrollViewDelegate:(XWCycleScrollView *)xwCycleScrollView
                didSelectdIndex:(NSUInteger)currentIndex
                   selectedView:(UIView*)selectedView;

- (void)xwCycleScrollViewDelegate:(XWCycleScrollView *)xwCycleScrollView
                 didScrollToIndex:(NSUInteger)currentIndex
                      currentView:(UIView*)currentView;

@end
