//
//  HorizontalScrollView.m
//  testa
//
//  Created by Ishay Weinstock on 12/16/14.
//  Copyright (c) 2014 Ishay Weinstock. All rights reserved.
//

#import "HorizontalTableView.h"

#define SEPARATOR_WIDTH 1
#define DEFAULT_CELL_WIDTH 100

typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
} ScrollDirection;

@interface HorizontalTableView() <UIScrollViewDelegate>

#pragma mark - =========== Private properties ===========
@property (strong,nonatomic) NSMutableSet *cellsToReuseSet;//The set containing the reusable cells

@property (strong,nonatomic) UIScrollView *scrollView;//The scroll view with all the content of the "TableView"

@property (nonatomic) CGFloat widthOfTwoCells;
@property (nonatomic) CGPoint lastContentOffset; //Used to determine the amount of scrolling in scrollViewDidScroll.
@property (nonatomic) CGFloat scrollPointsCounter; // Resets after user scrolled more than self.cellsWidth

@property (nonatomic) NSInteger numberOfPossibleVisibleCells; //Calculted amount of visible cells at any moment.

@end







#pragma mark - =========== Implementation ===========
@implementation HorizontalTableView

#pragma mark - UIView overrides
-(void)drawRect:(CGRect)rect{
    
    [self prepareComponents];
    [self addFirstVisibleCells];
    
}



#pragma mark - Preparations
-(void)prepareComponents{
    
    _cellsToReuseSet = [[NSMutableSet alloc]initWithCapacity:10];
    self.cellWidth = self.cellWidth == 0?DEFAULT_CELL_WIDTH:self.cellWidth;
    _numberOfPossibleVisibleCells = self.frame.size.width / _cellWidth;
    _widthOfTwoCells = self.cellWidth * 2;
    
    self.scrollView = [[UIScrollView alloc]initWithFrame:self.bounds];
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];
    self.scrollView.contentSize = [self determineScrollViewContentSize];
    
}

-(CGSize)determineScrollViewContentSize{
    
    CGFloat height = self.scrollView.frame.size.height;
    CGFloat calculatedWidth = [self.dataSource horizontalScrollViewNumberOfCells:self] * self.cellWidth;
    
    return CGSizeMake(calculatedWidth, height);
}











#pragma mark - UIScrollView Delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    _scrollPointsCounter+= _lastContentOffset.x - scrollView.contentOffset.x;
    
    if (_scrollPointsCounter > _cellWidth || _scrollPointsCounter < -_cellWidth) {
        //User scrolled more than a width of a cell.
        
        //Determine scroll direction
        ScrollDirection scrollDirection = ScrollDirectionNone;
        
        if (_lastContentOffset.x > scrollView.contentOffset.x)
            scrollDirection                 = ScrollDirectionRight;
        else if (self.lastContentOffset.x < scrollView.contentOffset.x)
            scrollDirection                 = ScrollDirectionLeft;
        
        
        [self handleScrollingWithDirection:scrollDirection];
        
        //Reset after making changes.
        _lastContentOffset = scrollView.contentOffset;
        _scrollPointsCounter = 0;
        
        
        //Remove cells that are not visible
        for (int i = 0; i < scrollView.subviews.count; i++) {
            [self scrollView:scrollView removeViewIfNotVisible:scrollView.subviews[i]];
        }

    }

}





#pragma mark - Handle scrolling
/**
 *  Handles scrolling direction.
 *  If scrolling left, preparing cells from the right, and vice versa.
 *
 *  @param direction Direction of the scrolling.
 */
-(void)handleScrollingWithDirection:(ScrollDirection)direction{
    int index1ToPrepare;
    int index2ToPrepare;
    if (direction == ScrollDirectionRight){
        
        index1ToPrepare = (self.scrollView.contentOffset.x / self.cellWidth);
        index2ToPrepare = (self.scrollView.contentOffset.x / self.cellWidth) - 1;

    }else if (direction == ScrollDirectionLeft){
        index1ToPrepare = (self.scrollView.contentOffset.x / self.cellWidth) + _numberOfPossibleVisibleCells + 1;
        index2ToPrepare = (self.scrollView.contentOffset.x / self.cellWidth) + _numberOfPossibleVisibleCells + 2;

    }

    [self scrollView:self.scrollView addCellIfVisibleAtIndex:index1ToPrepare];
    [self scrollView:self.scrollView addCellIfVisibleAtIndex:index2ToPrepare];

}






#pragma mark - Remove / Add cells
/**
 *  Dequeues a cell from the reuseable cells set if there is any and removes it from the set right after.
 *
 *  @return The cell after dequeuing
 */
- (UIView*)dequeueCell{
    UIView* page = [_cellsToReuseSet anyObject];
    if (page != nil) {
        
        [_cellsToReuseSet removeObject: page];
        
    }
    return page;
}





/**
 *  Adds the first visible cells right after the scroll view is added to the view.
 */
-(void)addFirstVisibleCells{
    CGRect scrollViewBoundsWithAddition = CGRectMake(self.scrollView.bounds.origin.x,
                                                     self.scrollView.bounds.origin.y,
                                                     self.scrollView.bounds.size.width + (self.cellWidth *2), //Two additional cells to prevent sudden appearing
                                                     self.scrollView.bounds.size.height);
    
    for (int i = 0; i < [self.dataSource horizontalScrollViewNumberOfCells:self]; i++) {
        
        CGPoint viewOrigin = CGPointMake((self.cellWidth * i), 0);
        UIView *viewToAdd = [self.dataSource horizontalScrollView:self cellForIndex:i];
        viewToAdd.frame = CGRectMake(viewOrigin.x, viewOrigin.y, self.cellWidth, self.frame.size.height);
        
        if (CGRectContainsRect(scrollViewBoundsWithAddition, viewToAdd.frame))
        {
            //View is inside the bounds of its super view.
            [self.scrollView addSubview:viewToAdd];
            
        }else{
            
            return;
            
        }
    }
}






/**
 *   Checks the scroll view to see if the given index will be visible after adding the cell.
 *   if it will be visible - Adds it to the scroll view.
 *
 *  @param scrollView  The scrollview to check
 *  @param cellIndex  The index of the cell
 */
-(void)scrollView:(UIScrollView*)scrollView addCellIfVisibleAtIndex:(int)cellIndex{
    
    CGRect visibleScrollViewContentRect = CGRectMake(
                                                     scrollView.contentOffset.x - _widthOfTwoCells,
                                                     scrollView.contentOffset.y,
                                                     scrollView.frame.size.width + (_widthOfTwoCells * 2),
                                                     scrollView.frame.size.height);
    
    CGPoint viewOrigin = CGPointMake((self.cellWidth * cellIndex), 0);
    UIView *viewToAdd = [self.dataSource horizontalScrollView:self cellForIndex:cellIndex];
    if (viewToAdd != nil){
        viewToAdd.frame = CGRectMake(viewOrigin.x, viewOrigin.y, self.cellWidth, self.frame.size.height);
        
        
        BOOL isPartlyVisibleInScrollView = CGRectEqualToRect(CGRectIntersection(visibleScrollViewContentRect, viewToAdd.frame), viewToAdd.frame);
        
        
        if(isPartlyVisibleInScrollView && ![viewToAdd isDescendantOfView:self.scrollView])
        {
            
            [self.scrollView addSubview:viewToAdd];
            
        }
    }
}




/**
 *  Checks the scroll view to see if the given view is currently visible.
 *  if the view is NOT visible - Removes it and puts it on reuse cells set.
 *
 *  @param scrollView  The scrollview to check
 *  @param viewToCheck The given view inside it
 */
-(void)scrollView:(UIScrollView*)scrollView removeViewIfNotVisible:(UIView*)viewToCheck{
    
    CGRect visibleScrollViewContentRect = CGRectMake(scrollView.contentOffset.x - _widthOfTwoCells,
                                                     scrollView.contentOffset.y,
                                                     scrollView.frame.size.width + (_widthOfTwoCells * 2),
                                                     scrollView.frame.size.height);
    
    BOOL isPartlyVisibleInScrollView = CGRectEqualToRect(CGRectIntersection(visibleScrollViewContentRect, viewToCheck.frame), viewToCheck.frame);
    
    if(!isPartlyVisibleInScrollView)
    {
        [viewToCheck removeFromSuperview];
        [_cellsToReuseSet addObject:viewToCheck];
    }
}




@end
