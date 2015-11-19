//
//  CalendarModel.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "BSCalendarModel.h"

#import <EventKit/EventKit.h>

// Google API
#import "GooglePlus OpenSource/GTMOAuth2Authentication.h"
#import "GooglePlusSDK/GPPSignIn.h"
// Extension
#import "GTLCalendarEvent+Calendar_Property.h" // includes gtlcalendar.h

@interface BSCalendarModel () <GPPSignInDelegate>
{
    dispatch_queue_t _eventsFetchQueue;
    NSOperationQueue *_fetchQueue;
    dispatch_queue_t _calendarSyncQueue;
    
    GTLServiceCalendar *googleService;
    
    NSDictionary *googleCalendarsDictionary;
    
    NSArray *preferredAppleCalendars;
    NSArray *preferredGoogleCalendarsIdentifiers;
}

/* Private properties */
@property (nonatomic, copy) BSCalendarModelEventsFetcherCompletionBlock tableEventsCompletionBlock;
@property (nonatomic, copy) BSCalendarModelWeekEventsFetcherCompletionBlock weekEventsCompletionBlock;
@end

static NSString * const kALCalendarModePreferredCalendarKey = @"UserPreferredCalendars";
static NSString *const kKeychainItemName = @"AIzaSyD-r6SDRkv0hVAgQwfdgHrvVFSH9jYPEE8";
static NSString *const kClientSecret = @"YJYFLfxqDg9iIH-8pMB0zDoB";

@implementation BSCalendarModel

+ (BSCalendarModel *)sharedManager {
    static BSCalendarModel *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        // 0. Try google
        [self googleSilentSignIn];
        
        // 1. Init event store
        self.eventStore = [[EKEventStore alloc] init];
        
        // 2. Set queues
        _fetchQueue = [[NSOperationQueue alloc] init];
        [_fetchQueue setSuspended:YES];
        _eventsFetchQueue =
        dispatch_queue_create("com.eventKitTutorial.fetchQueue",
                              DISPATCH_QUEUE_SERIAL);
        _calendarSyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        // 3. Request access to use events
        [_eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error){
            if (granted) {
                NSLog(@"Calendar Model. Access granted. Start fetching queue");
                [_fetchQueue setSuspended:NO];
            }
        }];
        
        // 4.
        //[self preferredCalendars];
    }
    
    return self;
}

- (void)googleSilentSignIn {
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.shouldFetchGoogleUserEmail = YES;
    signIn.delegate = self;
    [signIn setScopes:@[@"https://www.googleapis.com/auth/plus.login",
                        @"https://www.googleapis.com/auth/calendar"]];
    [signIn trySilentAuthentication];
}

#pragma mark - GPPSignInDelegate

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
    [self setAuthorised:(error)?NO:YES];
}

- (void)didDisconnectWithError:(NSError *)error {
    [self setAuthorised:NO];
}

- (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate {
    return (([date compare:beginDate] != NSOrderedAscending) && ([date compare:endDate] != NSOrderedDescending));
}

- (void)setAuthorised:(BOOL)authorised {
    _authorised = authorised;
    
    if (authorised) {
        googleService = [[GTLServiceCalendar alloc] init];
        googleService.authorizer = [GPPSignIn sharedInstance].authentication;
        
        [self fetchCalendarsListWithCompletionHandler:^(NSDictionary *calendarsDictionary){
            // Updated dictionary list, update views
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kALCalendarUpdateEvents" object:nil];
        }];
    }
}

#pragma mark - Fetching events

- (void)fetchEventsForDate:(NSDate*)date completion:(BSCalendarModelEventsFetcherCompletionBlock)completionBlock {

    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        self.tableEventsCompletionBlock = completionBlock;
        
        __block NSMutableArray *eventsForDate;
        /* 
         * There are two ways for fetching events
         * 1. Create array and just fill with EKCalendars and GTLCalendars
         * 2. Create dictionary with array of EKCalendars for @"Apple" key and array with GTLCalendars for @"Google" key
         */
        
        // do the job
        dispatch_async(_eventsFetchQueue, ^{
            NSCalendar *calendar = [NSCalendar currentCalendar];
            
            NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay fromDate:date];
            
            NSDateComponents *weekAgoComponents = [[NSDateComponents alloc] init];
            //weekAgoComponents.week = -1; // Method was deprecated
            weekAgoComponents.weekOfYear = -1;
            NSDate *weekAgoDate = [calendar dateByAddingComponents:weekAgoComponents toDate:date options:0];

            NSDateComponents *weekLaterComponents = [[NSDateComponents alloc] init];
            //weekLaterComponents.week = 1; // Method was deprecated
            weekLaterComponents.weekOfYear = 1;
            
            NSDate *weekLaterDate = [calendar dateByAddingComponents:weekLaterComponents toDate:date options:0];

            NSPredicate *predicate = [_eventStore predicateForEventsWithStartDate:weekAgoDate endDate:weekLaterDate calendars:preferredAppleCalendars];
            
            NSArray *eventsArrayObject = [_eventStore eventsMatchingPredicate:predicate];
            eventsForDate = [NSMutableArray array];
            
            // Create a date with same day, but at 00:01
            NSDateComponents *components = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
            components.hour = 0;
            components.minute = 1;
            NSDate *zerozerooneDate = [calendar dateFromComponents:components];
            
            for (EKEvent *event in eventsArrayObject) {
                // Check if start or end date is equal
                NSDateComponents *eventStartDateComponents = [calendar components:(NSCalendarUnitDay) fromDate:event.startDate];
                if (dateComponents.day == eventStartDateComponents.day) {
                    [eventsForDate addObject:event];
                } else {
                    // Check if it is more-than-one-day event
                    if ([self date:zerozerooneDate isBetweenDate:event.startDate andDate:event.endDate]) {
                        [eventsForDate addObject:event];
                    }
                }
            }
            
            if (self.isAuthorised) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    // We have list. Now parse events
                    GTLBatchQuery *batchQuery = [GTLBatchQuery batchQuery];
                    for (NSString *calendarID in preferredGoogleCalendarsIdentifiers) {
                        GTLQueryCalendar *eventsQuery = [GTLQueryCalendar queryForEventsListWithCalendarId:calendarID];
                        eventsQuery.completionBlock = ^(GTLServiceTicket *ticket, id object, NSError *error) {
                            GTLCalendarEvents *eventsList = (GTLCalendarEvents*)object;
                            NSArray *eventsArray = (eventsList.items)?eventsList.items:@[];
                            for (GTLCalendarEvent *event in eventsArray) {
                                // Check if it's suitable
                                NSDateComponents *eventStartDateComponents = event.start.dateTime.dateComponents;
                                if (dateComponents.day == eventStartDateComponents.day) {
                                    GTLCalendarCalendar *calendar = [googleCalendarsDictionary objectForKey:calendarID];
                                    [event setCalendar:calendar];
                                    [eventsForDate addObject:event];
                                } else {
                                    // Check if it is more-than-one-day event
                                    NSDate *startDate = (event.start.dateTime.date)?event.start.dateTime.date:event.start.date.date;
                                    NSDate *endDate = (event.end.dateTime.date)?event.end.dateTime.date:event.end.date.date;
                                    if ([self date:zerozerooneDate isBetweenDate:startDate andDate:endDate]) {
                                        GTLCalendarCalendar *calendar = [googleCalendarsDictionary objectForKey:calendarID];
                                        [event setCalendar:calendar];
                                        [eventsForDate addObject:event];
                                    }
                                }
                            }
                        };
                        [batchQuery addQuery:eventsQuery];
                    }
                    // Batch query created. Fetch it
                    [googleService executeQuery:batchQuery completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                        if (!error) {
                            // Send back
                            if (_tableEventsCompletionBlock) {
                                _tableEventsCompletionBlock(eventsForDate);
                            }
                        }
                        // Set to nil to avoid retain cycles
                        self.tableEventsCompletionBlock = nil;
                    }];
                });
            }
            
            else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    // Send back
                    if (_tableEventsCompletionBlock) {
                        _tableEventsCompletionBlock(eventsForDate);
                    }
                    // Set to nil to avoid retain cycles
                    self.tableEventsCompletionBlock = nil;
                });
            }
        });
    }];
    [_fetchQueue addOperation:operation];
}

- (void)fetchPanelEventsForPanel:(NSInteger)panelIndex forStartDate:(NSDate*)startDate andEndDate:(NSDate*)endDate completion:(BSCalendarModelPanelEventsFetcherCompletionBlock)completionBlock {

    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(_eventsFetchQueue, ^{
            
            NSPredicate *predicate = [_eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:preferredAppleCalendars];
            
            NSArray *appleEventsArray = [_eventStore eventsMatchingPredicate:predicate];
            
            
            // Apple events are easy to fetch
            
            if (self.isAuthorised) {
                NSMutableArray *allEvents = [NSMutableArray arrayWithArray:appleEventsArray];
                
                // Fetch Google events
                dispatch_sync(dispatch_get_main_queue(), ^{
                    // We have list. Now parse events
                    GTLBatchQuery *batchQuery = [GTLBatchQuery batchQuery];
                    for (NSString *calendarID in preferredGoogleCalendarsIdentifiers) {
                        GTLQueryCalendar *eventsQuery = [GTLQueryCalendar queryForEventsListWithCalendarId:calendarID];
                        eventsQuery.completionBlock = ^(GTLServiceTicket *ticket, id object, NSError *error) {
                            GTLCalendarEvents *eventsList = (GTLCalendarEvents*)object;
                            NSArray *eventsArray = (eventsList.items)?eventsList.items:@[];
                            for (GTLCalendarEvent *event in eventsArray) {
                                // Check if it's suitable
                                NSDate *eventStartDate = (event.start.dateTime.date)?event.start.dateTime.date:event.start.date.date;
                                NSDate *eventEndDate = (event.end.dateTime.date)?event.end.dateTime.date:event.end.date.date;
                                // 3 cases (1. Event IN panel, 2. Out of panel, 3. Half-out)
                                // Optimised algorythm - 2 checks for 4 situations (half-out can be left and right)
                                if ([self date:eventStartDate isBetweenDate:startDate andDate:endDate] ||
                                    [self date:startDate isBetweenDate:eventStartDate andDate:eventEndDate]) {
                                    [allEvents addObject:event];
                                }
                            }
                        };
                        [batchQuery addQuery:eventsQuery];
                    }
                    // Batch query created. Fetch it
                    [googleService executeQuery:batchQuery completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                        if (!error) {
                            completionBlock([NSArray arrayWithArray:allEvents],panelIndex);
                        }
                    }];
                });
            }
            
            else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    // Send back
                    completionBlock([NSArray arrayWithArray:appleEventsArray],panelIndex);
                });
            }
            
        });
    }];
    [_fetchQueue addOperation:operation];
}

- (void)fetchWeekPanelEventsforStartDate:(NSDate*)startDate andEndDate:(NSDate*)endDate completion:(BSCalendarModelWeekEventsFetcherCompletionBlock)completionBlock {
    self.weekEventsCompletionBlock = completionBlock;
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(_eventsFetchQueue, ^{
            
            NSCalendar *calendar = [NSCalendar currentCalendar];
            
            NSDateComponents *twoDaysAgoComponents = [[NSDateComponents alloc] init];
            twoDaysAgoComponents.day = -2;
            NSDate *twoDaysAgoDate = [calendar dateByAddingComponents:twoDaysAgoComponents toDate:startDate options:0];
            
            NSDateComponents *oneDayLaterComponents = [[NSDateComponents alloc] init];
            oneDayLaterComponents.day = 1;
            NSDate *oneDayLaterDate = [calendar dateByAddingComponents:oneDayLaterComponents toDate:endDate options:0];
            
            NSPredicate *predicate = [_eventStore predicateForEventsWithStartDate:twoDaysAgoDate endDate:oneDayLaterDate calendars:preferredAppleCalendars];
            
            NSArray *appleEventsArray = [_eventStore eventsMatchingPredicate:predicate];
            
            if (self.isAuthorised) {
                NSMutableArray *allEvents = [NSMutableArray arrayWithArray:appleEventsArray];
                
                // Fetch Google events
                dispatch_sync(dispatch_get_main_queue(), ^{
                    // We have list. Now parse events
                    GTLBatchQuery *batchQuery = [GTLBatchQuery batchQuery];
                    for (NSString *calendarID in preferredGoogleCalendarsIdentifiers) {
                        GTLQueryCalendar *eventsQuery = [GTLQueryCalendar queryForEventsListWithCalendarId:calendarID];
                        eventsQuery.completionBlock = ^(GTLServiceTicket *ticket, id object, NSError *error) {
                            GTLCalendarEvents *eventsList = (GTLCalendarEvents*)object;
                            NSArray *eventsArray = (eventsList.items)?eventsList.items:@[];
                            for (GTLCalendarEvent *event in eventsArray) {
                                // Check if it's suitable
                                
                                NSDate *eventStartDate = (event.start.dateTime.date)?event.start.dateTime.date:event.start.date.date;
                                NSDate *eventEndDate = (event.end.dateTime.date)?event.end.dateTime.date:event.end.date.date;
                                // 3 cases (1. Event IN panel, 2. Out of panel, 3. Half-out)
                                // Optimised algorythm - 2 checks for 4 situations (half-out can be left and right)
                                if ([self date:eventStartDate isBetweenDate:startDate andDate:endDate] ||
                                    [self date:startDate isBetweenDate:eventStartDate andDate:eventEndDate]) {
                                    [allEvents addObject:event];
                                }
                                
                            }
                        };
                        [batchQuery addQuery:eventsQuery];
                    }
                    // Batch query created. Fetch it
                    [googleService executeQuery:batchQuery completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                        if (!error) {
                            if (_weekEventsCompletionBlock) {
                                _weekEventsCompletionBlock([NSArray arrayWithArray:allEvents]);
                            }
                            // Set to nil to avoid retain cycles
                            self.weekEventsCompletionBlock = nil;
                        }
                    }];
                });
            }
            
            else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    // Send back
                    if (_weekEventsCompletionBlock) {
                        _weekEventsCompletionBlock([NSArray arrayWithArray:appleEventsArray]);
                    }
                    // Set to nil to avoid retain cycles
                    self.weekEventsCompletionBlock = nil;
                });
            }
        });
    }];
    [_fetchQueue addOperation:operation];
}

#pragma mark - Calendars

- (void)fetchCalendarsListWithCompletionHandler:(BSCalendarModelCalendarListFetcherCompletionBlock)completionBlock {
    NSArray *appleCalendars = [_eventStore calendarsForEntityType:EKEntityTypeEvent];
    NSMutableDictionary *calendarsDictionary = [NSMutableDictionary dictionary];
    
    for (EKCalendar *calendar in appleCalendars) {
        NSString *calendarSourceTitle = calendar.source.title;
        NSMutableArray *arrayForSourceType = [calendarsDictionary[calendarSourceTitle] mutableCopy];
        if (!arrayForSourceType) {
            arrayForSourceType = [NSMutableArray array];
        }
        [arrayForSourceType addObject:calendar];
        [calendarsDictionary setObject:arrayForSourceType forKey:calendarSourceTitle];
    }
    
    __block NSArray *googleCalendars = [NSArray array];
    
    if (self.isAuthorised) {
        // fetch google calendars
        GTLQueryCalendar *queryForFetchingCalendarList = [GTLQueryCalendar queryForCalendarListList];
        [googleService executeQuery:queryForFetchingCalendarList completionHandler:^(GTLServiceTicket *ticket,id calendarList, NSError *error) {
            GTLCalendarCalendarList *calendarList_ = calendarList;
            googleCalendars = calendarList_.items;
            [calendarsDictionary setObject:googleCalendars forKey:@"Google"];
            
            // Place all google calendars into dictionary
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            for (GTLCalendarCalendar *calendar in googleCalendars) {
                [dictionary setObject:calendar forKey:calendar.identifier];
            }
            googleCalendarsDictionary = [NSDictionary dictionaryWithDictionary:dictionary];
            
            completionBlock([NSDictionary dictionaryWithDictionary:calendarsDictionary]);
        }];
    }
    
    else {
        [calendarsDictionary setObject:googleCalendars forKey:@"Google"];
        completionBlock([NSDictionary dictionaryWithDictionary:calendarsDictionary]);
    }
}

// Setter with barrier
- (void)setPreferredCalendars:(NSArray *)preferredCalendarsIdentifiers {
    dispatch_barrier_async(_calendarSyncQueue, ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:preferredCalendarsIdentifiers forKey:kALCalendarModePreferredCalendarKey];
        [userDefaults synchronize];
        
        // Update preferred arrays
        [self preferredCalendars];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            // Reload panels
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kALCalendarUpdateEvents" object:nil];
        });
    });
}

// Getter
- (NSArray *)preferredCalendars {
    __block NSArray *localArray;
    dispatch_sync(_calendarSyncQueue, ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        localArray = [userDefaults objectForKey:kALCalendarModePreferredCalendarKey];
        if (localArray) {
            
            // Magic Apple Problems
            // 0.1. Get all calendars
            NSArray *appleCalendars = [_eventStore calendarsForEntityType:EKEntityTypeEvent];
            
            NSMutableArray *apples = [NSMutableArray array];
            NSMutableArray *googles = [NSMutableArray array];
            for (NSString *identifier in localArray) {
                // We need to divide into two arrays
                // From apple id's -> create ekcalendar
                // From google id's -> just save
                if ([identifier rangeOfString:@".com"].location == NSNotFound) {
                    // 0.2. Search for that calendar
                    for (EKCalendar *calendar in appleCalendars) {
                        if ([calendar.calendarIdentifier isEqualToString:identifier]) {
                            [apples addObject:calendar];
                        }
                    } // 'expensive' algorythm
                }
                else {
                    [googles addObject:identifier];
                }
                preferredAppleCalendars = [NSArray arrayWithArray:apples];
                preferredGoogleCalendarsIdentifiers = [NSArray arrayWithArray:googles];
            }
        }
        
        else {
            preferredAppleCalendars = [NSArray array];
            preferredGoogleCalendarsIdentifiers = [NSArray array];
        }
    });
    
    return localArray;
}

#pragma mark - Calendar Management
#pragma mark -
#pragma mark Apple Calendar
- (void)createAppleCalendarWithTitle:(NSString*)title competion:(void(^)(BOOL success, NSError *error))completionBlock {
    EKCalendar *calendar;
    NSError *error;
    
    // Get the calendar source
    EKSource* localSource;
    for (EKSource* source in _eventStore.sources) {
        if (source.sourceType == EKSourceTypeLocal)
        {
            localSource = source;
            break;
        }
    }
    
    if (!localSource) {
        completionBlock(NO, error);
    }
    
    calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:_eventStore];
    calendar.source = localSource;
    calendar.title = title;
    
    BOOL success= [_eventStore saveCalendar:calendar commit:YES error:&error];
    completionBlock(success, error);
}

- (void)deleteAppleCalendar:(EKCalendar*)calendar competion:(void(^)(BOOL success, NSError *error))completionBlock {
    if (calendar) {
        NSError *error = nil;
        BOOL success = [self.eventStore removeCalendar:calendar commit:YES error:&error];
        completionBlock(success, error);
    } else {
        completionBlock(NO, nil);
    }
}

#pragma mark Google Calendar
- (void)deleteGoogleCalendarWithIdentifier:(NSString*)calendarId competion:(void(^)(BOOL success, NSError *error))completionBlock {
    if (self.isAuthorised) {
        // fetch google calendars
        // Check if it is primary - primary's id is equal to user email
        if ([calendarId isEqualToString:[GPPSignIn sharedInstance].authentication.userEmail]) {
            GTLQueryCalendar *queryForDeletingCalendar = [GTLQueryCalendar queryForCalendarsClearWithCalendarId:calendarId];
            [googleService executeQuery:queryForDeletingCalendar completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                completionBlock((error)?NO:YES,error);
            }];
        } else {
            GTLQueryCalendar *queryForDeletingCalendar = [GTLQueryCalendar queryForCalendarsDeleteWithCalendarId:calendarId];
            [googleService executeQuery:queryForDeletingCalendar completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                completionBlock((error)?NO:YES,error);
            }];
        }
    } else {
        completionBlock(NO, nil);
    }
}

- (void)createGoogleCalendar:(GTLCalendarCalendar*)calendar competion:(void(^)(BOOL success, NSError *error))completionBlock {
    if (self.isAuthorised) {
        // fetch google calendars
        GTLQueryCalendar *queryForDeletingCalendar = [GTLQueryCalendar queryForCalendarsInsertWithObject:calendar];
        [googleService executeQuery:queryForDeletingCalendar completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            completionBlock((error)?NO:YES,error);
        }];
    } else {
        completionBlock(NO, nil);
    }
}

#pragma mark - Event Management
#pragma mark -
#pragma mark Google events
- (void)deleteGoogleEvent:(GTLCalendarEvent*)event competion:(void(^)(BOOL success, NSError *error))completionBlock {
    if (self.isAuthorised) {
        NSString *calendarId = event.calendar.identifier;
        NSString *eventId = event.identifier;
        GTLQueryCalendar *queryForDeletingEvent = [GTLQueryCalendar queryForEventsDeleteWithCalendarId:calendarId eventId:eventId];
        [googleService executeQuery:queryForDeletingEvent completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            completionBlock((error)?NO:YES,error);
        }];
    } else {
        completionBlock(NO, nil);
    }
}

- (void)createGoogleEvent:(GTLCalendarEvent*)event withCalendarId:(NSString*)calendarId competion:(void(^)(BOOL success, NSError *error))completionBlock {
    if (self.isAuthorised) {
        GTLQueryCalendar *queryForCreatingEvent = [GTLQueryCalendar queryForEventsInsertWithObject:event calendarId:calendarId];
        [googleService executeQuery:queryForCreatingEvent completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            completionBlock((error)?NO:YES,error);
        }];
    } else {
        completionBlock(NO, nil);
    }
}

- (void)updateGoogleEvent:(GTLCalendarEvent*)event withCalendarId:(NSString*)calendarId competion:(void(^)(BOOL success, NSError *error))completionBlock {
    if (self.isAuthorised) {
        GTLQueryCalendar *queryForUpdatingEvent = [GTLQueryCalendar queryForEventsUpdateWithObject:event calendarId:calendarId eventId:event.identifier];
        [googleService executeQuery:queryForUpdatingEvent completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            completionBlock((error)?NO:YES,error);
        }];
    } else {
        completionBlock(NO, nil);
    }
}
@end








