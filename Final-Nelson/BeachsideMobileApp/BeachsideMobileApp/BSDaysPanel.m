//
//  BSDaysPanel.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "BSDaysPanel.h"

// Date Button
#import "BSCalendarViewDateButton.h"

@implementation BSDaysPanel
-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 1. Define sizes
        CGFloat viewHeight = frame.size.height;
        CGFloat viewWidth = frame.size.width;
        CGFloat sideGap = 5.0;
        CGFloat buttonsGap = 1.0;
        CGFloat contentWidth = viewWidth - 2 * sideGap - 6 * buttonsGap;
        CGFloat contentHeight = viewHeight - 2 * sideGap - 5 * buttonsGap;
        CGFloat cellWidth = contentWidth/7;
        CGFloat cellHeight = contentHeight/6;
        
        //
        _panelDateComponents = [[NSDateComponents alloc] init];
        
        // 2. Place buttons
        NSInteger tagIndex = 11;
        for (NSInteger i = 0; i < 6; i++) {
            for (NSInteger j = 0; j < 7; j++) {
                BSCalendarViewDateButton *dateButton = [BSCalendarViewDateButton buttonWithType:UIButtonTypeCustom];
                dateButton.frame = CGRectMake(j*(cellWidth + buttonsGap) + sideGap, i * (cellHeight + buttonsGap) + sideGap, cellWidth, cellHeight);
                [dateButton setBackgroundColor:[UIColor whiteColor]];
                dateButton.tag = tagIndex;
                [dateButton addTarget:self action:@selector(dateButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dateButtonPressedWithGesture:)];
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(dateButtonLongPressedWithGesture:)];
                [dateButton addGestureRecognizer:longPress];
                [dateButton addGestureRecognizer:singleTap];
                [dateButton setTitle:[NSString stringWithFormat:@"%d",tagIndex] forState:UIControlStateNormal];
                [dateButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [self addSubview:dateButton];
                
                tagIndex++;
            }
        }
        
        [self setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    }
    return self;
}

- (void)removeEventIndicatorsFromButtons {
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[BSCalendarViewDateButton class]]) {
            BSCalendarViewDateButton *button = (BSCalendarViewDateButton*)view;
            [button hasNoEvents];
        }
    }
}

- (void)dateButtonPressed:(id)sender {
    if ([_buttonDelegate respondsToSelector:@selector(daysPanel:buttonPressed:manually:)]) {
        BSCalendarViewDateButton *dateButton = (BSCalendarViewDateButton*)sender;
        [_buttonDelegate daysPanel:self buttonPressed:dateButton manually:YES];
    }
}

- (void)dateButtonPressedWithGesture:(UITapGestureRecognizer*)gestureRecognizer {
    // Find button with basic hitTest
    UIView *view = gestureRecognizer.view;
    CGPoint tapLocation = [gestureRecognizer locationInView:view];
    BSCalendarViewDateButton *dateButton = (BSCalendarViewDateButton*)[view hitTest:tapLocation withEvent:nil];
    
    [self dateButtonPressed:dateButton];
}

- (void)dateButtonLongPressedWithGesture:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([_buttonDelegate respondsToSelector:@selector(daysPanel:buttonLongPressed:)]) {
            // Find button with basic hitTest
            UIView *view = gestureRecognizer.view;
            CGPoint tapLocation = [gestureRecognizer locationInView:view];
            BSCalendarViewDateButton *dateButton = (BSCalendarViewDateButton*)[view hitTest:tapLocation withEvent:nil];
            
            [_buttonDelegate daysPanel:self buttonLongPressed:dateButton];
        }
    }
}

#pragma mark - Public. Select button
- (void)selectButtonWithDate:(NSDate*)date {
    for (BSCalendarViewDateButton *button in self.subviews) {
        if ([button.date compare:date] == NSOrderedSame) {
            [button selectDateButton];
            [self dateButtonPressed:button];
        }
    }
}
@end