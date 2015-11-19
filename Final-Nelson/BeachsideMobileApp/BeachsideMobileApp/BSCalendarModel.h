//
//  CalendarModel.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EKEventStore;
@class EKCalendar;
@class GTLCalendarCalendar;
@class GTLCalendarEvent;

/**********  Blocks **********/
typedef void(^BSCalendarModelEventsFetcherCompletionBlock)(NSArray *eventsArray);
typedef void(^BSCalendarModelWeekEventsFetcherCompletionBlock)(NSArray *eventsArray);
typedef void(^BSCalendarModelPanelEventsFetcherCompletionBlock)(NSArray *eventsArray, NSInteger panelIndex);
typedef void(^BSCalendarModelCalendarListFetcherCompletionBlock)(NSDictionary *calendarsDictionary);

@interface BSCalendarModel : NSObject

/**
 *  Return a shared instance of Calendar Model
 *  @return shared instance of Calendar Model
 */
+ (BSCalendarModel *)sharedManager;

/********** Public properties **********/
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, getter = isAuthorised) BOOL authorised;

/********** Public methods **********/
/**
 *  Get events for selected date
 *
 *  @param date            Date selected from calendar
 *  @param completionBlock Completion Block
 */
- (void)fetchEventsForDate:(NSDate*)date completion:(BSCalendarModelEventsFetcherCompletionBlock)completionBlock;

/**
 *  Get events array for ALDaysPanel
 *
 *  @param panelIndex      Panel's index
 *  @param startDate       First date on panel
 *  @param endDate         Last date on panel
 *  @param completionBlock Completion Block
 */
- (void)fetchPanelEventsForPanel:(NSInteger)panelIndex forStartDate:(NSDate*)startDate andEndDate:(NSDate*)endDate completion:(BSCalendarModelPanelEventsFetcherCompletionBlock)completionBlock;

/**
 *  Get events for selected week for Week Panel
 *
 *  @param startDate       First date on panel
 *  @param endDate         Last date on panel
 *  @param completionBlock Completion Block
 */
- (void)fetchWeekPanelEventsforStartDate:(NSDate*)startDate andEndDate:(NSDate*)endDate completion:(BSCalendarModelWeekEventsFetcherCompletionBlock)completionBlock;

/**
 *  Get Calendar List (Dictionary) for user
 *
 *  @param completionBlock Completion block
 */
- (void)fetchCalendarsListWithCompletionHandler:(BSCalendarModelCalendarListFetcherCompletionBlock)completionBlock;

/**
 *  Returns list of calendars that user want to work with
 *
 *  @return NSArray with EKCalendars
 */
- (NSArray *)preferredCalendars;

/**
 *  Setter for an array of preferred calendars
 *
 *  @param preferredCalendars NSArray of preferred calendars
 */
- (void)setPreferredCalendars:(NSArray *)preferredCalendarsIdentifiers;

/* 
 * ReadWrite
 */

/**
 *  Call it to create EKCalendar with selected title
 *
 *  @param title           Title of the event
 *  @param completionBlock Completion Block. Handle error if any
 */
- (void)createAppleCalendarWithTitle:(NSString*)title competion:(void(^)(BOOL success, NSError *error))completionBlock;

/**
 *  Delete selected EKCalendar
 *
 *  @param calendar        EKCalendar to delete
 *  @param completionBlock Completion Block. Handle error if any
 */
- (void)deleteAppleCalendar:(EKCalendar*)calendar competion:(void(^)(BOOL success, NSError *error))completionBlock;

/**
 *  Delete GTLCalendarCalendar entity
 *
 *  @param calendarId      Identifier of selected calendar
 *  @param completionBlock Completion Block. Handle error if any
 */
- (void)deleteGoogleCalendarWithIdentifier:(NSString*)calendarId competion:(void(^)(BOOL success, NSError *error))completionBlock;

/**
 *  Create Google GTLCalendarCalendar entity.
 *
 *  @param calendar        GTLCalendar entity
 *  @param completionBlock Completion Block. Handle error if any
 */
- (void)createGoogleCalendar:(GTLCalendarCalendar*)calendar competion:(void(^)(BOOL success, NSError *error))completionBlock;

/**
 *  Delete selected Google GTLCalendarEvent
 *
 *  @param event           Event to delete
 *  @param completionBlock Completion Block. Handle error if any
 */
- (void)deleteGoogleEvent:(GTLCalendarEvent*)event competion:(void(^)(BOOL success, NSError *error))completionBlock;

/**
 *  Create google event
 *
 *  @param event           Event to create
 *  @param calendarId      GTLCalendarCalendar identifier
 *  @param completionBlock Completion Block. Handle error if any
 */
- (void)createGoogleEvent:(GTLCalendarEvent*)event withCalendarId:(NSString*)calendarId competion:(void(^)(BOOL success, NSError *error))completionBlock;

/**
 *  Update google event
 *
 *  @param event           Event to update
 *  @param calendarId      GTLCalendarCalendar identifier
 *  @param completionBlock Completion Block
 */
- (void)updateGoogleEvent:(GTLCalendarEvent*)event withCalendarId:(NSString*)calendarId competion:(void(^)(BOOL success, NSError *error))completionBlock;
@end
