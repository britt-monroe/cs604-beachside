//
//  BSCalendarViewDateButton.m
///  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "BSCalendarViewDateButton.h"

@interface BSCalendarViewDateButton ()
{
    CALayer *eventLayer;
    BOOL _today;
    NSInteger eventCounter;
}
@end

@implementation BSCalendarViewDateButton

- (void)selectDateButton {
    CGFloat redFloat = 232.0;
    CGFloat greenFloat = 136.0;
    CGFloat blueFloat = 4.0;
    UIColor *barTintColor = [UIColor colorWithRed:redFloat/255.0 green:greenFloat/255.0 blue:blueFloat/255.0 alpha:1.0];
    
    [self setBackgroundColor:barTintColor];
    if (!_today) [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)deselectDateButton {
    [self setBackgroundColor:[UIColor whiteColor]];
    if (!_today) [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

- (void)selectAsTodayButton {
    _today = YES;
    [self setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
}

- (void)deselectAsToday {
    _today = NO;
    [self deselectDateButton];
}

- (void)hasAnEvent {
    eventCounter++;
    if (eventCounter > 3) eventCounter = 3;
    
    if (!eventLayer) {
        eventLayer = [CALayer layer];
        CGFloat height = self.bounds.size.height;
        CGFloat width = self.bounds.size.width;
        CGFloat layerHeight = height / 6;
        CGFloat indicatorY = layerHeight * 4.5;
        CGFloat indicatorX = 0.0;
        eventLayer.frame = CGRectMake(indicatorX, indicatorY, width, layerHeight);
        eventLayer.backgroundColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:eventLayer];
    }
    
    if (eventLayer.sublayers.count > 0) {
        [eventLayer setSublayers:@[]];
    }
    
    // place dots... or dot
    if (eventCounter == 1) {
        CGFloat dotWidth = eventLayer.frame.size.width / 3;
        CGFloat dotHeight = eventLayer.frame.size.height;
        CGFloat size = fminf(dotWidth, dotHeight);
        CALayer *sublayer = [CALayer layer];
        sublayer.frame = CGRectMake((eventLayer.frame.size.width - size)/2, 0, size, size);
        sublayer.backgroundColor = [UIColor lightGrayColor].CGColor;
        sublayer.cornerRadius = size/2;
        [eventLayer addSublayer:sublayer];
    } else if (eventCounter > 1) {
        CGFloat dotWidth = eventLayer.frame.size.width / (eventCounter * 2);
        CGFloat dotHeight = eventLayer.frame.size.height;
        CGFloat size = fminf(dotWidth, dotHeight);
        CGFloat containerSize = size * eventCounter + (eventCounter - 1) * (size/2);
        CGFloat sideGap = (eventLayer.frame.size.width - containerSize) / 2;
        
        for (int i = 0; i < eventCounter; i++) {
            CALayer *sublayer = [CALayer layer];
            sublayer.frame = CGRectMake(sideGap + i * size + i * (size / 2), (eventLayer.frame.size.height - size)/2, size, size);
            sublayer.backgroundColor = [UIColor lightGrayColor].CGColor;
            sublayer.cornerRadius = size/2;
            [eventLayer addSublayer:sublayer];
        }
    }
}

- (void)hasNoEvents {
    eventCounter = 0;
    
    if (eventLayer.sublayers.count > 0) {
        [eventLayer setSublayers:@[]];
    }
}
@end
