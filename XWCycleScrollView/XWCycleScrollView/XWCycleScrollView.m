//
//  XWCycleScrollView.m
//  XWCycleScrollView
//
//  Created by Zhang Xiaowei on 15/7/23.
//  Copyright (c) 2015年 Zhang Xiaowei. All rights reserved.
//

#import "XWCycleScrollView.h"

#define WIDTH_TITLE_LABEL 20  // 广告页标题的高度

#define CURRENT_IMAGEVIEW_NUM 3  // 此处需要是奇数,一般为3个即可满足循环滚动需要

@interface XWCycleScrollView ()<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView             *scrollView;// Views的容器，滚动视图
@property (nonatomic, strong) NSMutableArray           *currentScrollViews;// 正在滚动的Views，三个
@property (nonatomic, strong) UIView                   *currentView; // 当前视图

@property (nonatomic, strong) UIPageControl            *pageControl;// 页面指示器
@property (nonatomic, assign) BOOL                     isShowPageControl;// 是否显示页面指示器

@property (nonatomic, assign) XWCycleDirection         scrollDirection; // 滚动方向，垂直或水平
@property (nonatomic, assign) XWHandleRollingDirection handleRollingDirection; // 手动滚动的方向

@property (nonatomic, assign) NSInteger                allPages; // 总页数

@property (nonatomic, strong) NSTimer                  *autoTimer; // 定时器
@property (nonatomic, assign) BOOL                     isAutoScrolling; // 是否正在滚动
@property (nonatomic, assign) CGFloat                  timerInterVal; // 自动滚动时间间隔
@property (nonatomic, assign) BOOL                     isDelayStartAutoTimerWithHandleScroll; // 控制scrollView手动滚动的定时器

@property (nonatomic, assign) CGFloat                  width;
@property (nonatomic, assign) CGFloat                  height;

@end


@implementation XWCycleScrollView

#pragma mark - 初始化方法
- (XWCycleScrollView *)initWithFrame:(CGRect)frame
                    xwCycleDirection:(XWCycleDirection)direction
                            withView:(NSArray *)viewsArray{
    return [self initWithFrame:frame xwCycleDirection:direction withView:viewsArray withStartPage:0];
}

- (XWCycleScrollView *)initWithFrame:(CGRect)frame
                    xwCycleDirection:(XWCycleDirection)direction
                            withView:(NSArray *)viewsArray
                       withStartPage:(NSUInteger)startPage{
    return [self initWithFrame:frame xwCycleDirection:direction withView:viewsArray withStartPage:startPage isShowPageControl:YES];
}

- (XWCycleScrollView *)initWithFrame:(CGRect)frame
                    xwCycleDirection:(XWCycleDirection)direction
                            withView:(NSArray *)viewsArray
                       withStartPage:(NSUInteger)startPage
                   isShowPageControl:(BOOL)isShowPageControl{
    self = [super initWithFrame:frame];
    if (self) {
        _currentScrollViews = [NSMutableArray array];
        
        _scrollDirection = direction;
        _viewsArray = [NSMutableArray arrayWithArray:viewsArray];
        _currentPage = startPage;
        _isShowPageControl = isShowPageControl;
        _allPages = _viewsArray.count;
        _width = CGRectGetWidth(frame);
        _height = CGRectGetHeight(frame);
        
        _timerInterVal = 4.0; // 默认4.0
        _isDelayStartAutoTimerWithHandleScroll = NO; // 默认NO
        
        [self scrollView];
        [self autoTimer];
        
        if (_isShowPageControl)  [self pageControl];
        
        [self refreshCurrentScrollViewsWithCurrentPage:_currentPage];
        [self refreshView];
        [self refreshScrollView];
        [self refreshViewWithPage:_currentPage];
        
        [self startAutoScroll];
    }
    return self;
}

#pragma mark - 添加UIView
- (BOOL)insertView:(UIView *)willInsertedView atIndex:(NSUInteger)atIndex isRefresh:(BOOL)isRefresh{
    // 要刷新, 先停止自动滚动
    if (isRefresh) {
        [self stopAutoScroll];
    }
    
    // 处理传入的atIndex参数, 防止数组越界
    NSInteger index = 0;
    if (atIndex >= (_allPages - 1)) {
        NSLog(@"index越界, 默认index=0");
    }else{
        index = atIndex;
    }
    
    // 重置willInsertedView的frame
    willInsertedView.frame = self.bounds;
    [_viewsArray insertObject:willInsertedView atIndex:atIndex];
    _allPages = _viewsArray.count;  // 更新总页数
    [self configPageControlPagesAndCenter:_allPages];  // 更新页面指示器数量
    
    // 滚动至指定位置
    if (isRefresh) {
        [self scrollViewJumpCustomPage:atIndex];
    }
    // 关闭自动滚动定时器
    [self stopAutoScroll];
    
    // 设置手动滑动时, 需要延时启动定时器
    _isDelayStartAutoTimerWithHandleScroll = YES;
    return YES;
}

- (BOOL)insertViews:(NSArray *)willInsertedViews atIndex:(NSUInteger)atIndex isRefresh:(BOOL)isRefresh{
    // 要刷新, 先停止自动滚动
    if (isRefresh) {
        [self stopAutoScroll];
    }
    
    // 处理传入的atIndex参数, 防止数组越界
    NSInteger index = 0;
    if (atIndex >= (_allPages - 1)) {
        NSLog(@"index越界, 默认index=0");
    }else{
        index = atIndex;
    }
    
    // 循环调用insertImageView:atIndex:isRefreshScorllView
    //    static NSInteger queueNum = -1;
    for (NSInteger i = 0; i < willInsertedViews.count; i++) {
        UIView * view = willInsertedViews[i];
        //            queueNum++;
        [self insertView:view atIndex:atIndex + 1 isRefresh:NO];
        
        // 设置手动滑动无需延时启动定时器
        _isDelayStartAutoTimerWithHandleScroll = NO;
    }
    
    // 滚动至指定位置
    if (isRefresh) {
        [self scrollViewJumpCustomPage:atIndex];
    }
    
    // 关闭自动滚动定时器
    [self stopAutoScroll];
    
    // 设置手动滑动时, 需要延时启动定时器
    _isDelayStartAutoTimerWithHandleScroll = YES;
    return YES;
}


#pragma mark - 删除UIView

- (BOOL)removeObjectWithIndex:(NSUInteger)index{
    // 如果index合法, 且指定元素是AD_Menu_UIImageView, 则删除, 并返回YES.
    // 否则返回NO
    if (index < _viewsArray.count) {
        if ([_viewsArray[index] isKindOfClass:[UIView class]]) {
            [_viewsArray removeObjectAtIndex:index];
            // 刷新
            [self refreshViewWithPage:0];
            return YES;
        }
    }
    return NO;
}

- (BOOL)removeObjectWithImageView:(UIView *)view{
    if ([view isKindOfClass:[UIView class]]) {
        // 如果传入参数是AD_Menu_UIImageView, 进入循环
        for (UIView * imgV in _viewsArray) {
            // 如果找到与传入参数相等的对象, 则删除对象,并返回YES
            // 否则返回NO
            if (imgV == view) {
                [_viewsArray removeObject:view];
                [self refreshViewWithPage:0];
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)removeObjectWithView:(UIView *)willRemovedView{
    return YES;
}

- (BOOL)removeObjectsWithViews:(NSArray *)willRemovedViews{
    return YES;
}

- (BOOL)removeObjectWithArray:(NSArray *)imgViewArray{
    NSMutableArray * tempArray = [NSMutableArray arrayWithArray:imgViewArray];
    for (id imgView in tempArray) {
        if ([imgView isKindOfClass:[UIView class]]) {
            UIView * adview = (UIView*)imgView;
            BOOL isSuccess = [self removeObjectWithView:adview];
            if (isSuccess) {
                [tempArray removeObject:imgView];
            }
        }
    }
    if (tempArray.count == 0) {
        NSLog(@"全部删除成功");
        return YES;
    }else if (tempArray.count >0 && tempArray.count < imgViewArray.count){
        NSLog(@"部分删除成功");
        return NO;
    }else if (tempArray.count == imgViewArray.count){
        NSLog(@"全部删除失败");
        return NO;
    }
    return NO;
}



#pragma mark - 跳转至指定页面

// scrollView滚动至指定页面
- (void)scrollViewJumpCustomPage:(NSInteger)page{
    NSInteger currPage = 0;
    // 传入参数非法时, 将默认调整值第一页, 即currPage=0
    if (page > (_viewsArray.count - 1) || page < 0) {
        currPage = 0;
    }else{
        currPage = page;
    }
    
    /**
     1. 停止自动滚动
     2. 清空_currImgViewsArray
     3. 更新_pageControl
     4. 刷新_currImgViewsArray和ScrollView
     5. 开启自动滚动
     */
    [self stopAutoScroll];
    [_currentScrollViews removeAllObjects];
    _pageControl.currentPage = currPage;
    [self refreshCurrentScrollViewsWithCurrentPage:currPage];
    [self refreshScrollView];
    [self startAutoScroll];
}

#pragma mark - 初始化控件

- (void)configPageControlPagesAndCenter:(NSInteger)num{
    _pageControl.numberOfPages = num;
    _pageControl.center = CGPointMake(_width / 2.0, _height - 10);
}

// 配置ScorllView中的Views
- (void)configImgViews{
    _currentScrollViews = [[NSMutableArray alloc] init];
    if (_viewsArray) {
        [self refreshCurrentScrollViewsWithCurrentPage:_currentPage];
    }
}

- (void)refreshCurrentScrollViewsWithCurrentPage:(NSUInteger)currentPage{
    _currentPage = currentPage;
    _pageControl.currentPage = _currentPage;  // 更新页面指示器

    for (UIView *view in _currentScrollViews) {
        [view removeFromSuperview];
    }
    [_currentScrollViews removeAllObjects];
    
    for (NSInteger i = 0;  i < CURRENT_IMAGEVIEW_NUM; i++) {
        UIView * view = nil;
        if (_currentPage == 0) {
            view = (UIView*)_viewsArray[(_allPages - 1 + i)%_allPages];
        }else if (_currentPage == _allPages - 1){
            view = (UIView*)_viewsArray[(_currentPage - 1 + i)%_allPages];
        }else{
            view = (UIView*)_viewsArray[(_currentPage - 1 + i)%_allPages];
        }
        [_currentScrollViews addObject:view];
    }
    // 刷新滚动视图
    [self refreshScrollView];
}

// 刷新ScrollView
- (void)refreshScrollView{
    for (NSInteger i = 0; i < CURRENT_IMAGEVIEW_NUM; i++) {
        UIView * view = (UIView*)_currentScrollViews[i];
        CGFloat x,y = 0;
        if (_scrollDirection ==  XWCycleDirectionVertical) {
            x = 0;
            y = _height * (i - 1);
        }else if (_scrollDirection == XWCycleDirectionHorizontal){
            x = _width * (i - 1);
            y = 0;
        }
        view.frame = CGRectMake(x, y, _width, _height);
        [_scrollView addSubview:view];
    }
}

-(void)refreshView{
    [self refreshViewWithPage:_currentPage];
}

- (void)refreshViewWithPage:(NSUInteger)page{
    _allPages = _viewsArray.count;  // 更新总页数
    [self configPageControlPagesAndCenter:_allPages];  // 更新页面指示器数量
    [self refreshCurrentScrollViewsWithCurrentPage:page];
    [self refreshScrollView];
}

// ScrollView动画设置信息
- (void)scrollViewAnimation{
    _pageControl.currentPage = _currentPage;
    [UIView animateWithDuration:0.5 animations:^{
        // 1.当前正在自动滚动,则直接滚动第三个View
        // 2.当前非自动滚动,则需要根据滚动方向设置ScrollView中View的位置
        if (!_isAutoScrolling) {
            _scrollView.contentOffset = CGPointMake(_width * ( 1 + _handleRollingDirection), 0);
        }else{
            _scrollView.contentOffset = CGPointMake(_width * 2, 0);
            // 自动滚动操作完成后,将_isAutoScrolling设为NO
            _isAutoScrolling = NO;
        }
    } completion:^(BOOL finished) {
        [self refreshCurrentScrollViewsWithCurrentPage:_currentPage];
        
        // 调用滚动到某个View相应的方法
        // 包括协议方法
        [self didScrollToImgView];
    }];
}


#pragma mark - ImageView点击事件
-(void)imgViewTapClick:(UITapGestureRecognizer*)tap{
    if (_delegate && [_delegate respondsToSelector:@selector(xwCycleScrollViewDelegate:didSelectedIndex:)]) {
        [_delegate xwCycleScrollViewDelegate:self didSelectedIndex:_currentPage];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(xwCycleScrollViewDelegate:didSelectdIndex:selectedView:)]) {
        [_delegate xwCycleScrollViewDelegate:self didSelectdIndex:_currentPage selectedView:_currentView];
    }
}

#pragma mark - 定时器相关方法
- (void)setTimerInterval:(CGFloat)timerInterval{
    _timerInterVal = timerInterval;
    
    // 停止定时器
    // 1. 停止
    // 2. 使其失效
    // 3. 将其置空
    // 4. 间隔一定时间, 重新初始化一个定时器
    [_autoTimer setFireDate:[NSDate distantFuture]];
    [_autoTimer invalidate];
    _autoTimer = nil;
    
    // 可以解决开始定时器后, 广告页立即跳转的问题
    [NSTimer scheduledTimerWithTimeInterval:_timerInterVal target:self selector:@selector(reSetAutoTimer) userInfo:nil repeats:NO];
}

- (void)reSetAutoTimer{
    _autoTimer = [NSTimer scheduledTimerWithTimeInterval:_timerInterVal target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
}

- (void)startAutoScroll{
    if (_allPages > 2) {
        [_autoTimer setFireDate:[NSDate date]];
    }
}

- (void)stopAutoScroll{
    [_autoTimer setFireDate:[NSDate distantFuture]];
    _isDelayStartAutoTimerWithHandleScroll = YES;
}

-(void)startAutoScrolling:(CGFloat)animationDuration{
    if (_allPages > 2) {
        [self setTimerInterval:animationDuration];
        [self startAutoScroll];
    }
}

-(void)stopAutoScrolling{
    [self stopAutoScroll];
}

// 定时器重复执行的方法
- (void)timerAction{
    if (_currentPage >= (_allPages - 1)) {
        _currentPage = 0;
    }else{
        _currentPage++;
    }
    _isAutoScrolling = YES;  // 即将开始自动滚动, _isAutoScrolling设为真
    [self scrollViewAnimation];
}

- (void)didScrollToImgView{
    // 代理非空,实现协议方法, 则执行对应方法
    if (_delegate && [_delegate respondsToSelector:@selector(xwCycleScrollViewDelegate:didScrollToIndex:)]) {
        [_delegate xwCycleScrollViewDelegate:self didScrollToIndex:_currentPage];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(xwCycleScrollViewDelegate:didSelectdIndex:selectedView:)]) {
        [_delegate xwCycleScrollViewDelegate:self didScrollToIndex:_currentPage currentView:_currentView];
    }
}


#pragma mark - 滚动视图协议方法

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    //    NSLog(@"已经结束减速. scrollViewDidEndDecelerating");
    //    NSLog(@"======%f,%f",_scrollView.contentOffset.x,_scrollView.contentOffset.y);
    
    /*   如果当前是自动滚动状态, 则无需任何操作, 直接跳过方法体  */
    if (_isAutoScrolling) {
        return;
    }
    
    // 判断手动滚动方向
    if (_scrollView.contentOffset.x >= _width * 2) {
        _handleRollingDirection = XWHandleRollingDirectionRight;
    }else if (_scrollView.contentOffset.x <= 0.0){
        _handleRollingDirection = XWHandeleRollingDirectionLeft;
    }
    
    if (_scrollView.contentOffset.y >= _height * 2) {
        _handleRollingDirection = XWHandleRollingDirectionDown;
    }else if (_handleRollingDirection <= 0.0){
        _handleRollingDirection = XWHandleRollingDirectionUp;
    }
    
    // 处理循环滚动
    if (_currentPage >= (_allPages - 1) && (_handleRollingDirection == XWHandleRollingDirectionRight || _handleRollingDirection == XWHandleRollingDirectionDown)) {
        // 如果当前到达最后一页,且是向右滚动,  则跳到第一页
        _currentPage = 0;
    }else if (_currentPage <= 0 && (_handleRollingDirection == XWHandeleRollingDirectionLeft || _handleRollingDirection == XWHandleRollingDirectionUp)){
        // 如果当前到达第一页,且是向前滚动,  则跳到最后一页
        _currentPage = _allPages - 1;
    }else{
        // 正常滚动,根据滚动方向确定当前页
        _currentPage += 1;
    }
    [self scrollViewAnimation];
    
    if (_isDelayStartAutoTimerWithHandleScroll) {
        NSLog(@"延时启动自动滚动");
        [NSTimer scheduledTimerWithTimeInterval:_timerInterVal target:self selector:@selector(startAutoScroll) userInfo:nil repeats:NO];
        
        // 设置手动滑动无需延时启动定时器
        _isDelayStartAutoTimerWithHandleScroll = NO;
    }
    
    // 间隔_timerInterval启动定时滚动
    //    [self startAutoScrollWaitingTimerInterval];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    //    NSLog(@"已经结束拖拽. scrollViewDidEndDragging");
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    //    NSLog(@"正在滚动. scrollViewDidScroll");
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView{
    //    NSLog(@"已经滚动到顶部. scrollViewDidScrollToTop");
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView{
    //    NSLog(@"scrollViewShouldScrollToTop");
    return NO;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    //    NSLog(@"即将开始减速. scrollViewWillBeginDecelerating");
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    //    NSLog(@"将开始拖拽. scrollViewWillBeginDragging");
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view{
    //    NSLog(@"scrollViewWillBeginZooming");
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    //    NSLog(@"将结束拖拽. scrollViewWillEndDragging");
}
#pragma mark - Tools
// 根据16进制和alpha计算UIColor
- (UIColor *)HEX2Color:(NSInteger)hexCode inAlpha:(CGFloat)alpha{
    float red   = ((hexCode >> 16) & 0x000000FF)/255.0f;
    float green = ((hexCode >> 8) & 0x000000FF)/255.0f;
    float blue  = ((hexCode) & 0x000000FF)/255.0f;
    return [UIColor colorWithRed:red
                           green:green
                            blue:blue
                           alpha:alpha];
}

#pragma mark - Getter
- (UIScrollView *)scrollView{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.bounces = NO;
        _scrollView.showsHorizontalScrollIndicator = YES;
        _scrollView.showsVerticalScrollIndicator = YES;
        [self addSubview:_scrollView];
        CGSize contentSize = CGSizeMake(0, 0);
        if (_scrollDirection == XWCycleDirectionHorizontal) {
            contentSize = CGSizeMake(_width * CURRENT_IMAGEVIEW_NUM, 0);
        }else if (_scrollDirection == XWCycleDirectionVertical){
            contentSize = CGSizeMake(0, _height * CURRENT_IMAGEVIEW_NUM);
        }
        _scrollView.contentSize = contentSize;
    }
    return _scrollView;
}

- (UIPageControl *)pageControl{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        [self configPageControlPagesAndCenter:_allPages];
        _pageControl.currentPageIndicatorTintColor = [self HEX2Color:0xE2273A inAlpha:1.0];
        _pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:0.5 alpha:0.5];
        [self insertSubview:_pageControl aboveSubview:_scrollView];
    }
    return _pageControl;
}

- (NSTimer *)autoTimer{
    if (!_autoTimer) {
        _autoTimer = [NSTimer scheduledTimerWithTimeInterval:_timerInterVal target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    }
    return _autoTimer;
}

#pragma mark - Setter
- (void)setViewsArray:(NSMutableArray *)viewsArray{
    if (viewsArray && viewsArray.count > 0) {
        _viewsArray = viewsArray;
    }
}

@end
