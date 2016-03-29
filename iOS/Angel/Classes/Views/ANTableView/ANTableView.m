/*
 * Copyright (c) 2016, Seraphim Sense Ltd.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions
 *    and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to
 *    endorse or promote products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ANTableView.h"
#import "ANTableViewItem.h"
#import "NSObject+MTKObserving.h"

NSUInteger kTableViewSection = 0;

@interface ANTableView () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *itemsViewContainer;

@property NSInteger indexOfPinchingItem;
@property CGFloat originalHeightOfPinchingItem;
@property CGPoint offsetTableViewBeforePinching;
@property UIEdgeInsets insetTableView;

@property BOOL animating;

@end

@implementation ANTableView

#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.bounds];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.tableView];
    
    self.itemsViewContainer = [NSMutableArray array];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self addGestureRecognizer:pinchRecognizer];
    
    self.indexOfOpenedItem = NSNotFound;
    self.animating = NO;
    
}

#pragma mark Custom getters/setters

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    self.tableView.scrollEnabled = scrollEnabled;
}

- (BOOL)scrollEnabled {
    return self.tableView.scrollEnabled;
}

#pragma mark Reloading data;

- (void)reloadData {
    self.itemsViewContainer = [NSMutableArray array];
    
    NSUInteger numberOfElements = [self.dataSource numberOfItemsInTableView:self];
    
    for (NSUInteger index = 0; index < numberOfElements; index++) {
        ANTableViewItem *view = [self createTableViewItemAtIndex:index];
        [self.itemsViewContainer insertObject:view atIndex:index];
    }
    
    if (self.isOpenedState) {
        [self openAllItemsExceptAtIndex:NSNotFound];
    }
    else {
        [self closeAllItemsExceptAtIndex:NSNotFound];
    }
    
    [self.tableView reloadData];
}

- (ANTableViewItem *)createTableViewItemAtIndex:(NSUInteger)index {
    ANTableViewItem *view = nil;
    
    UIView *openedView = [self.dataSource tableView:self openedViewAtIndex:index];
    UIView *closedView = [self.dataSource tableView:self closedViewAtIndex:index];
    
    if (self.isOpenedState) {
        view = [[ANTableViewItem alloc] initItemWithType:ANTableViewItemTypeOpened closedView:closedView openedView:openedView];
    }
    else {
        view = [[ANTableViewItem alloc] initItemWithType:ANTableViewItemTypeClosed closedView:closedView openedView:openedView];
    }
    
    return view;
}

#pragma mark Item opening/closing handling

- (void)openItemAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void(^)(void))completion {
    @synchronized(self) {
        void (^internalCompletion)(void) = ^{
            self.indexOfOpenedItem = index;
            self.isOpenedState = YES;
            self.animating = NO;
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
            if (completion) {
                completion();
            }
        };
        void (^handleAnimationBlock)(void) = ^{
            self.animating = YES;
            if (self.indexOfOpenedItem != NSNotFound) {
                [self collapseItemAtIndex:self.indexOfOpenedItem animated:animated completion:^ {
                    [self expandItemAtIndex:index animated:animated completion:internalCompletion];
                }];
            } else {
                [self expandItemAtIndex:index animated:animated completion:internalCompletion];
            }
        };
        if (!self.animating) {
            handleAnimationBlock();
        } else {
            [self observeProperty:@"animating" withBlock:^(__weak id self, NSNumber *oldVal, NSNumber *newVal) {
                if (oldVal && newVal) {
                    if (!newVal.boolValue) {
                        [self removeAllObservations];
                        handleAnimationBlock();
                    }
                }
            }];
        }
    }
    
}

- (void)closeItemAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void(^)(void))completion {
    @synchronized(self) {
        void (^internalCompletion)(void) = ^{
            self.indexOfOpenedItem = NSNotFound;
            self.isOpenedState = NO;
            
            self.animating = NO;
            if (completion) {
                completion();
            }
        };
        void (^handleAnimationBlock)(void) = ^{
            self.animating = YES;
            if (self.indexOfOpenedItem != NSNotFound) {
                [self collapseItemAtIndex:self.indexOfOpenedItem animated:animated completion:internalCompletion];
            } else {
                [self collapseItemAtIndex:index animated:animated completion:internalCompletion];
            }
        };
        if (!self.animating) {
            handleAnimationBlock();
        } else {
            [self observeProperty:@"animating" withBlock:^(__weak id self, NSNumber *oldVal, NSNumber *newVal) {
                if (oldVal && newVal) {
                    if (!newVal.boolValue) {
                        [self removeAllObservations];
                        handleAnimationBlock();
                    }
                }
            }];
        }
    }
}

- (NSUInteger)indexOfItem:(ANTableViewItem *)item {
    NSUInteger index = [self.itemsViewContainer indexOfObject:item];
    return index;
}

- (ANTableViewItem *)itemAtIndex:(NSUInteger)index {
    ANTableViewItem *item = [self.itemsViewContainer objectAtIndex:index];
    return item;
}

- (void)openAllItemsExceptAtIndex:(NSUInteger)indexExcept {
    for (NSUInteger index = 0; index < _itemsViewContainer.count; index++) {
        if (index != indexExcept) {
            [self.itemsViewContainer[index] openItemAnimated:NO completion:nil];
        }
    }
}

- (void)closeAllItemsExceptAtIndex:(NSUInteger)indexExcept {
    for (NSUInteger index = 0; index < _itemsViewContainer.count; index++) {
        if (index != indexExcept) {
            [self.itemsViewContainer[index] closeItemAnimated:NO completion:nil];
        }
    }
}

- (void)expandItemAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void (^)(void))blockCompletion  {
    ANTableViewItem *view = self.itemsViewContainer[index];
    [view openItemAnimated:animated completion:blockCompletion];
    [self updateCellsHeightsAnimated:animated];
}

- (void)collapseItemAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void (^)(void))blockCompletion {
    ANTableViewItem *view = self.itemsViewContainer[index];
    [view closeItemAnimated:animated completion:blockCompletion];
    [self updateCellsHeightsAnimated:animated];
}

- (void)scrollToTopCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:kTableViewSection];
    CGRect frameOfCell = [self.tableView rectForRowAtIndexPath:indexPath];
    CGPoint offsetCellToTop = CGPointMake(self.tableView.contentOffset.x, frameOfCell.origin.y);
    
    void (^blockScrollToTop)(void) = ^(void) {
        self.tableView.contentOffset = offsetCellToTop;
    };
    
    if (animated) {
        [UIView animateWithDuration:kItemAnimationDuration animations:blockScrollToTop];
    }
    else {
        blockScrollToTop();
    }
}

- (void)scrollToContentBoundsCellAtIndex:(NSInteger)indexSelected animated:(BOOL)animated {
    CGFloat visibleTableHeight = self.tableView.frame.size.height - _insetTableView.top - _insetTableView.bottom;
    
    NSUInteger indexOfLastCell = [self.tableView numberOfRowsInSection:kTableViewSection] - 1;
    ANTableViewItem *lastElement = (ANTableViewItem *)self.itemsViewContainer[indexOfLastCell];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfLastCell inSection:kTableViewSection];
    CGFloat heightOfContent = [self.tableView rectForRowAtIndexPath:indexPath].origin.y + lastElement.closedHeight;
    
    CGPoint newContentOffset = CGPointZero;
    
    if (visibleTableHeight > heightOfContent) {
        newContentOffset = CGPointMake(self.tableView.contentOffset.x, 0.f - _insetTableView.top);
    }
    else {
        CGFloat maxContentOffset = heightOfContent - visibleTableHeight;
        CGFloat percentOfMaxOffset = MIN(1.f, indexSelected / (CGFloat)(indexOfLastCell - 2));
        newContentOffset = CGPointMake(self.tableView.contentOffset.x, maxContentOffset * percentOfMaxOffset - _insetTableView.top);
    }
    
    void (^blockScrollToBorder)(void) = ^(void)
    {
        self.tableView.contentOffset = newContentOffset;
    };
    
    if (animated) {
        [UIView animateWithDuration:kItemAnimationDuration animations:blockScrollToBorder];
    }
    else {
        blockScrollToBorder();
    }
}

#pragma mark Custome getters and setters

- (void)setDataSource:(id <ANTableViewDataSource>)dataSource {
    _dataSource = dataSource;
    if (_dataSource) {
        [self reloadData];
    }
}

#pragma mark UITableView dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger numberOfRows = self.itemsViewContainer.count;
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =  [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    
    ANTableViewItem *view = self.itemsViewContainer[indexPath.row];
    [cell.contentView addSubview:view];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ANTableViewItem *element = self.itemsViewContainer[indexPath.row];
    CGFloat height = ceil(element.frame.size.height);
    return height;
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(tableView:didSelectItemAtIndex:)]) {
        [self.delegate tableView:self didSelectItemAtIndex:indexPath.row];
    }
}

#pragma mark UIGestureRecognizer delegate

- (void)handlePinch:(UIPinchGestureRecognizer*)pinchRecognizer {
    if (pinchRecognizer.state == UIGestureRecognizerStateBegan) {
        [self onPinchStateBegan:pinchRecognizer];
    }
    else if (pinchRecognizer.state == UIGestureRecognizerStateChanged) {
        [self onPinchStateChanged:pinchRecognizer];
    }
    else if ((pinchRecognizer.state == UIGestureRecognizerStateCancelled) || (pinchRecognizer.state == UIGestureRecognizerStateEnded)) {
        [self onPinchStateEnded:pinchRecognizer];
    }
}

- (void)onPinchStateBegan:(UIPinchGestureRecognizer*)pinchRecognizer {
    self.indexOfPinchingItem = NSNotFound;
    
    CGPoint pinchLocation = [pinchRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pinchLocation];
    
    if (indexPath != nil) {
        self.indexOfPinchingItem = indexPath.row;
        
        ANTableViewItem *view = self.itemsViewContainer[self.indexOfPinchingItem];
        self.originalHeightOfPinchingItem = view.frame.size.height;
        self.offsetTableViewBeforePinching = self.tableView.contentOffset;
    }
}

- (void)onPinchStateChanged:(UIPinchGestureRecognizer*)pinchRecognizer {
    if (self.indexOfPinchingItem == NSNotFound) {
        return;
    }
    
    CGFloat newHeight = self.originalHeightOfPinchingItem * pinchRecognizer.scale;
    
    ANTableViewItem *view = self.itemsViewContainer[self.indexOfPinchingItem];
    [view changeHeight:newHeight];
    
    [self updateCellsHeightsAnimated:NO];
}

- (void)onPinchStateEnded:(UIPinchGestureRecognizer*)pinchRecognizer {
    if (self.indexOfPinchingItem == NSNotFound) {
        return;
    }
    
    ANTableViewItem *view = self.itemsViewContainer[self.indexOfPinchingItem];
    CGFloat finalHeight = view.currentHeight;
    
    BOOL open = [self.delegate tableView:self shouldOpenItemAtIndex:self.indexOfPinchingItem sourceHeight:self.originalHeightOfPinchingItem targetHeight:finalHeight];
    if (open) {
        [self openItemAtIndex:self.indexOfPinchingItem animated:YES completion:nil];
    }
    else {
        [self closeItemAtIndex:self.indexOfPinchingItem animated:YES completion:nil];
    }
}

- (void)updateCellsHeightsAnimated:(BOOL)animated {
    BOOL animationsEnabled = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:animated];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:animationsEnabled];
}


@end
