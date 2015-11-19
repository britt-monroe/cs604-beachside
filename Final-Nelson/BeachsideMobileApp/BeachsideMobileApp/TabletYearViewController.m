//
//  TabletYearViewController.m
///  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "TabletYearViewController.h"

// VIEW: Calendar
#import "BSCalendarView.h"

// MODEL:
#import "BSCalendarModel.h"

// MODEL: EventKit
#import <EventKit/EventKit.h>

// Google Calendar API
#import "GTLCalendarEvent+Calendar_Property.h" // includes gtlcalendar.h

// CONTROLLER: Google Event View Controller
#import "GoogleEventEditViewController.h"

// CONTROLLER: Apple Event View Controller
#import <EventKitUI/EKEventEditViewController.h>

@interface TabletYearViewController ()
< // Protocols
BSGoogleEventEditViewDelegate,  // Handle user actions with google events
BSCalendarDelegate,             // Handle calendar taps and content
UITableViewDataSource,          // Table View with events
UITableViewDelegate,            // Handle table view taps
EKEventEditViewDelegate,        // Handle user actions with apple events
UIActionSheetDelegate           // Handle user choice
>

{
    // Calendar
    BSCalendarView *_calendarView;
    // Table with events
    UIView *_tableContainer;
    UITableView *_eventsTableView;
    // Events
    NSArray *eventsOnDate;
    // Last selected date
    NSDate *lastSelectedDate;
}
@end

@implementation TabletYearViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Calendar
    _calendarView = [[BSCalendarView alloc] initCalendarViewForTablet];
    _calendarView.calendarDelegate = self;
    [self.view addSubview:_calendarView];
    //
    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
}

- (void)viewWillLayoutSubviews {
    CGRect viewRect = self.view.bounds;
    //
    CGRect calendarFrame = CGRectMake(0, 20, CGRectGetWidth(viewRect), CGRectGetHeight(viewRect) - 20);
    _calendarView.frame = calendarFrame;
}

#pragma mark - Calendar Delegate
- (void)daysPanel:(NSInteger)panelIndex isReadyToSetEventsForFirstDate:(NSDate *)firstDate andLastDate:(NSDate *)lastDate {
    [[BSCalendarModel sharedManager] fetchPanelEventsForPanel:panelIndex forStartDate:firstDate andEndDate:lastDate completion:^(NSArray *eventsArray, NSInteger panelIndex){
        [_calendarView setEventsArray:eventsArray onDaysPanelWithIndex:panelIndex];
    }];
}

- (void)dateSelected:(NSDate *)date manually:(BOOL)hasTapped {
    if (!hasTapped) {
        return;
    }
    
    if (!_tableContainer) {
        // open view with table
        CGRect viewRect = self.view.bounds;
        CGFloat width = 300.0f;
        CGFloat height = 400.0f;
        _tableContainer = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(viewRect) - width)/2, (CGRectGetHeight(viewRect) - height)/2, width, height)];
        _tableContainer.backgroundColor = [UIColor whiteColor];
        UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_tableContainer.frame), 44)];
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Events"];
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(tableview_closeContentView)];
        navItem.leftBarButtonItem = closeButton;
        [navigationBar setItems:@[navItem]];
        [_tableContainer addSubview:navigationBar];
        _eventsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(navigationBar.frame), width, height - 44) style:UITableViewStylePlain];
        _eventsTableView.delegate = self;
        _eventsTableView.dataSource = self;
        _eventsTableView.backgroundColor = [UIColor clearColor];
        [_tableContainer addSubview:_eventsTableView];
        //
        _tableContainer.layer.cornerRadius = 20.0f;
        [self.view addSubview:_tableContainer];
        
        // Set to nil
        eventsOnDate = @[];
        // Update last selected date
        // Storing this one to use this date when creating new event
        lastSelectedDate = date;
        [[BSCalendarModel sharedManager] fetchEventsForDate:date completion:^(NSArray *eventsArray){
            eventsOnDate = eventsArray;
            [_eventsTableView reloadData];
        }];
    } else {
        // close view
        [_tableContainer removeFromSuperview];
        _tableContainer = nil;
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return eventsOnDate.count + 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"EventCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // Configure the cell...
    if (indexPath.row == eventsOnDate.count) {
        // Last cell
        cell.textLabel.text = @"            Press to add event"; // text is centered only on UITableViewCellStyleDefault
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.detailTextLabel.text = @"";
    }
    
    else {
        [self configureCell:cell atIndexPath:indexPath];
    }
    
    return cell;
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    id object = [eventsOnDate objectAtIndex:indexPath.row];
    if ([object isKindOfClass:[EKEvent class]]) {
        EKEvent *event = object;
        cell.textLabel.text = event.title;
        cell.detailTextLabel.text = event.calendar.title;
    }
    else {
        GTLCalendarEvent *event = object;
        cell.textLabel.text = event.summary;
        cell.detailTextLabel.text = (event.calendar)?event.calendar.summary:@"Google account";
    }
    cell.textLabel.textColor = [UIColor blackColor];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == eventsOnDate.count) {
        [self addEvent];
    }
    
    else {
        id object = [eventsOnDate objectAtIndex:indexPath.row];
        if ([object isKindOfClass:[EKEvent class]]) {
            EKEvent *event = object;
            
            EKEventEditViewController *editViewController = [[EKEventEditViewController alloc] init];
            editViewController.event = event;
            editViewController.eventStore = [[BSCalendarModel sharedManager] eventStore];
            editViewController.editViewDelegate = self;
            
            editViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:editViewController animated:YES completion:nil];
        }
        else {
            GTLCalendarEvent *event = object;
            
            GoogleEventEditViewController *editViewController = [[GoogleEventEditViewController alloc] init];
            editViewController.event = event;
            editViewController.editViewDelegate = self;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editViewController];
            
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navController animated:YES completion:nil];
        }
    }
}

#pragma mark - Close table view

- (void)tableview_closeContentView {
    // close view
    [_tableContainer removeFromSuperview];
    _tableContainer = nil;
}

#pragma mark - Event Management
#pragma mark -
#pragma mark Google Event Edit Delegate
- (void)eventGoogleEditViewController:(GoogleEventEditViewController *)controller didCompleteWithAction:(BSGoogleEventEditViewAction)action {
    [controller dismissViewControllerAnimated:YES completion:^
     {
         if (action != ALGoogleEventEditViewActionCanceled)
         {
             [[NSNotificationCenter defaultCenter] postNotificationName:@"kALCalendarUpdateEvents" object:nil];
         }
     }];
}

#pragma mark - EKEvent Edit Delegate
- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action {
    if (![controller isBeingDismissed]) {
        // Apple way
        // Dismiss the modal view controller
        [self dismissViewControllerAnimated:YES completion:^
         {
             if (action != EKEventEditViewActionCanceled)
             {
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"kALCalendarUpdateEvents" object:nil];
             }
         }];
    }
}

#pragma mark - Add event
- (void)addEvent {
    NSString *actionSheetTitle = @"Create event"; //Action Sheet Title
    NSString *other1 = @"Apple event";
    NSString *other2 = @"Google event";
    NSString *cancelTitle = @"Cancel";
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:actionSheetTitle
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:other1, other2, nil];
    
    [actionSheet showInView:self.view];
}

#pragma mark - Action Sheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Apple event
        EKEventStore *eventStore = [[BSCalendarModel sharedManager] eventStore];
        
        // Pre-create event
        EKEvent *event = [EKEvent eventWithEventStore:eventStore];
        event.startDate = lastSelectedDate;
        event.endDate = [lastSelectedDate dateByAddingTimeInterval:60*60*2];
        
        // Creating event controller
        EKEventEditViewController *eventViewController = [[EKEventEditViewController alloc] init];
        eventViewController.editViewDelegate = self;
        eventViewController.eventStore = eventStore;
        
        // Set event
        eventViewController.event = event;
        
        eventViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:eventViewController animated:YES completion:nil];
    }
    
    if (buttonIndex == 1) {
        // Google event
        GoogleEventEditViewController *editViewController = [[GoogleEventEditViewController alloc] init];
        editViewController.editViewDelegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editViewController];
        
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:nil];
    }
}
@end
