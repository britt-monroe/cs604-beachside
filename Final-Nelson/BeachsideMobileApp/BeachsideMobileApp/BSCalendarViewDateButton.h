//
//  BSCalendarViewDateButton.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import <UIKit/UIKit.h>

/* Date Button
 * Description:
 Date Button is an extension of usual button.
 It has Date property and methods to make button selected/deselected.
 */
@interface BSCalendarViewDateButton : UIButton

@property (nonatomic) NSDate *date;

/* Button selection */
- (void)selectDateButton;
- (void)deselectDateButton;

/* Manage 'today' indicator */
- (void)deselectAsToday;
- (void)selectAsTodayButton;

/* Manage event indicators */
- (void)hasAnEvent;
- (void)hasNoEvents;
@end