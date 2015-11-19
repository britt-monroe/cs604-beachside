//
//  BSCalendarView.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//


#import <UIKit/UIKit.h>

@protocol BSCalendarDelegate <NSObject>
@optional
- (void)userScrolledToMonth:(NSInteger)month;
- (void)dateSelectedWithLongTap:(NSDate *)date;
- (void)dateSelected:(NSDate*)date manually:(BOOL)hasTapped;
- (void)updateEventsArrayWithFirstDate:(NSDate*)firstDate andLastDate:(NSDate*)lastDate;
- (void)daysPanel:(NSInteger)panelIndex isReadyToSetEventsForFirstDate:(NSDate*)firstDate andLastDate:(NSDate*)lastDate;
@end

@interface BSCalendarView : UIView

@property (nonatomic) NSInteger numberOfPanels;
@property (nonatomic) id <BSCalendarDelegate> calendarDelegate;

/**
 *  Create horizontal calendar view in frame with selected number of month panels
 *
 *  @param numberOfPanels Number of month panels
 *  @param frame          Frame of calendar view
 *
 *  @return Calendar view instance
 */
- (id)initHorizontalCalendarWithNumberOfPanels:(NSInteger)numberOfPanels andWithFrame:(CGRect)frame;

/**
 *  Create vertical calendar view in frame with selected number of month panels
 *
 *  @param numberOfPanels Number of month panels
 *  @param frame          Frame of calendar view
 *
 *  @return Calendar view instance
 */
- (id)initVerticalCalendarWithNumberOfPanels:(NSInteger)numberOfPanels andWithFrame:(CGRect)frame;

/**
 *  Create calendar view with 12 panels ofr year view
 *
 *  @return Calendar view instance
 */
- (id)initCalendarViewForTablet;

/* Set events for month */
/**
 *  Apply events array to days panel
 *
 *  @param eventsArray NSArray with
 *  @param panelIndex  Index of panel
 */
- (void)setEventsArray:(NSArray*)eventsArray onDaysPanelWithIndex:(NSInteger)panelIndex;

/* Jump To Date function */
/**
 *  Ask calendar view to move to selected date
 *
 *  @param selectedDate Selected date
 */
- (void)jumpToDate:(NSDate*)selectedDate;
@end

