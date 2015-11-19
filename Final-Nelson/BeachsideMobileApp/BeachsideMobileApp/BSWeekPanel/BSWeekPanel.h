//
//  BSWeekPanel.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EKEvent;

@protocol BSWeekPanelDelegate <NSObject>
@optional
- (void)weekPanelEventSelected:(id)event;
- (void)weekPanelIsReadyToSetEventsForFirstDay:(NSDate*)firstDate andLastDate:(NSDate*)lastDate;
@end

@interface BSWeekPanel : UIView

/********** Public properties **********/

@property (nonatomic, copy) NSDate *selectedDayOfWeek;
@property (nonatomic) id <BSWeekPanelDelegate> weekPanelDelegate;

/**
 *  Apply events array to week panel
 *
 *  @param eventsArray NSArray with
 */
- (void)setEventsArray:(NSArray*)eventsArray;

/**
 *  Call to update week panel events views if some events were changed (edited or deleted)
 */
- (void)refetch;
@end
