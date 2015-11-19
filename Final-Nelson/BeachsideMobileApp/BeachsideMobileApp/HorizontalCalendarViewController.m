//
//  HorizontalCalendarViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

// CONTROLLER: Horizontal
#import "HorizontalCalendarViewController.h"

// CONTROLLER: Settings
#import "SettingsViewController.h"

// CONTROLLER: Google Event View Controller
#import "GoogleEventEditViewController.h"

// VIEW: Calendar
#import "BSCalendarView.h"

// VIEW: Week Panel
#import "BSWeekPanel.h"

// MODEL:
#import "BSCalendarModel.h"

// Google Calendar API
#import "GTLCalendarEvent+Calendar_Property.h" // includes gtlcalendar.h

// Simple VC to check Event details
#import <EventKitUI/EKEventEditViewController.h>

@interface HorizontalCalendarViewController ()
< // Protocols
BSCalendarDelegate,             // Handle calendar taps and content
BSGoogleEventEditViewDelegate,  // Handle user actions with google events
BSWeekPanelDelegate,            // Handle week panel taps and content
UITableViewDataSource,          // Table View with events
UITableViewDelegate,            // Handle table view taps
EKEventEditViewDelegate,        // Handle user actions with apple events
UIActionSheetDelegate           // Handle user choice
>

{
    // VIEW CONTAINERS
    UIView *containerCalendarWithTable;
    BSWeekPanel *containerWeekPanel;
    
    // Calendar
    BSCalendarView *_calendarView;
    // Table View
    UITableView *_eventsTableView;
    // Events
    NSArray *eventsOnDate;
    // Date Selection View
    UIView *_jumpToDateView;
    UIDatePicker *datePicker;
    // Last selected date
    NSDate *lastSelectedDate;
}
@end

@implementation HorizontalCalendarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGRect viewRect = self.view.bounds;
    CGFloat viewWidth = viewRect.size.width;
    CGFloat viewHeight = viewRect.size.height;
    
    /*** Container for calendar ***/
    containerCalendarWithTable = [[UIView alloc] initWithFrame:CGRectZero];
    [containerCalendarWithTable setBackgroundColor:[UIColor whiteColor]];
    
    // Set calendar view
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    CGRect calendarFrame = CGRectMake(CGRectGetMinX(viewRect), CGRectGetMinY(viewRect), viewWidth, viewHeight/2);
    // (0, under the NavBar, 320, half of screen)
    _calendarView = [[BSCalendarView alloc] initHorizontalCalendarWithNumberOfPanels:15 andWithFrame:calendarFrame];
    _calendarView.calendarDelegate = self;
    
    [containerCalendarWithTable addSubview:_calendarView];
    
    // Set table view
    _eventsTableView = [[UITableView alloc] initWithFrame:CGRectMake(CGRectGetMinX(viewRect),
                                                                     CGRectGetMaxY(calendarFrame),
                                                                     viewWidth,
                                                                     viewHeight - CGRectGetMaxY(calendarFrame)) style:UITableViewStylePlain];
    _eventsTableView.dataSource = self;
    _eventsTableView.delegate = self;
    [containerCalendarWithTable addSubview:_eventsTableView];
    
    
    /*** Container for week panel ***/
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    CGFloat panelWidth = (height > width)?height:width;
    CGFloat panelHeight = (height > width)?width:height;
    containerWeekPanel = [[BSWeekPanel alloc] initWithFrame:CGRectMake(0, 0, panelWidth, panelHeight)];
    containerWeekPanel.weekPanelDelegate = self;
    
    // Calendar with table will be initial controller
    [self setView:containerCalendarWithTable];
    
    // Define navigation buttons
    [self placeButtonsOnNavigationBar];
}

- (void)placeButtonsOnNavigationBar {
    // Update title on bar
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"LLLL"];
    [self.navigationItem setTitle:[dateFormatter stringFromDate:[NSDate date]]];
    
    /* Button to configure list of calendars */
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(openSettingsController)];
    self.navigationItem.rightBarButtonItem = settingsButton;
    
    /* Button to add event */
    UIBarButtonItem *addEventButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleBordered target:self action:@selector(addEvent)];
#warning Uncomment if you want to use "Add Event" button
    //self.navigationItem.rightBarButtonItem = addEventButton;
    
    /* Jump To Date Button */
    UIBarButtonItem *jumptodateButton = [[UIBarButtonItem alloc] initWithTitle:@"Jump" style:UIBarButtonItemStyleBordered target:self action:@selector(showDateSelectionView)];
    self.navigationItem.leftBarButtonItem = jumptodateButton;
}

#pragma mark - Calendar Delegate
- (void)userScrolledToMonth:(NSInteger)month {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"LLLL"];
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.month = month;
    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
    
    [self.navigationItem setTitle:[dateFormatter stringFromDate:date]];
}

- (void)daysPanel:(NSInteger)panelIndex isReadyToSetEventsForFirstDate:(NSDate *)firstDate andLastDate:(NSDate *)lastDate {
    [[BSCalendarModel sharedManager] fetchPanelEventsForPanel:panelIndex forStartDate:firstDate andEndDate:lastDate completion:^(NSArray *eventsArray, NSInteger panelIndex){
        [_calendarView setEventsArray:eventsArray onDaysPanelWithIndex:panelIndex];
    }];
}

- (void)dateSelected:(NSDate *)date manually:(BOOL)hasTapped {
    // Set to nil
    eventsOnDate = @[];
    
    // Update last selected date
    // Storing this one to use this date when creating new event
    lastSelectedDate = date;
    
    [[BSCalendarModel sharedManager] fetchEventsForDate:date completion:^(NSArray *eventsArray){
        eventsOnDate = eventsArray;
        
        [_eventsTableView reloadData];
    }];
}

- (void)dateSelectedWithLongTap:(NSDate *)date {
    // Update last selected date
    // Storing this one to use this date when creating new event
    lastSelectedDate = date;
    
    [self addEvent];
}

#pragma mark - Week Panel Delegate
- (void)weekPanelIsReadyToSetEventsForFirstDay:(NSDate*)firstDate andLastDate:(NSDate*)lastDate {
    [[BSCalendarModel sharedManager] fetchWeekPanelEventsforStartDate:firstDate andEndDate:lastDate completion:^(NSArray *eventsArray){
        [containerWeekPanel setEventsArray:eventsArray];
    }];
}

- (void)weekPanelEventSelected:(id)event {
    if ([event isKindOfClass:[EKEvent class]]) {
        EKEventEditViewController *editViewContoller = [[EKEventEditViewController alloc] init];
        editViewContoller.event = event;
        editViewContoller.eventStore = [[BSCalendarModel sharedManager] eventStore];
        editViewContoller.editViewDelegate = self;
        
        [self presentViewController:editViewContoller animated:YES completion:nil];
    }
    else {
        GTLCalendarEvent *googleEvent = event;
        
        GoogleEventEditViewController *editViewController = [[GoogleEventEditViewController alloc] init];
        editViewController.event = googleEvent;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editViewController];
        
        [self presentViewController:navController animated:YES completion:nil];
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
    
    static NSString *CellIdentifier = @"Cell";
    
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
            
            [self presentViewController:editViewController animated:YES completion:nil];
        }
        else {
            GTLCalendarEvent *event = object;
            
            GoogleEventEditViewController *editViewController = [[GoogleEventEditViewController alloc] init];
            editViewController.event = event;
            editViewController.editViewDelegate = self;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editViewController];
            
            [self presentViewController:navController animated:YES completion:nil];
        }
    }
}

/*
 - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
 return 44.0f;
 }
 */

#pragma mark - Jump To Date function
- (void)showDateSelectionView {
    if (!_jumpToDateView) {
        // All screen will be used
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        CGRect frame = CGRectMake(0, 0, screenWidth, screenHeight);
        
        // Init view
        _jumpToDateView = [[UIView alloc] initWithFrame:frame];
        
        // Create toolbar
        UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, (screenHeight - 260)/2, screenWidth, 44)];
        UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"Jump to date" style:UIBarButtonItemStyleBordered target:self action:@selector(dateSelectionUserSelectedDate)];
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(dateSelectionUserCanceled)];
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [toolBar setItems:@[cancel,space,save]];
        [_jumpToDateView addSubview:toolBar];
        datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(toolBar.frame), screenWidth, 216)];
        [datePicker setDatePickerMode:UIDatePickerModeDate];
        [datePicker setBackgroundColor:[UIColor whiteColor]];
        [_jumpToDateView addSubview:datePicker];
        
        [_jumpToDateView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    }
    
    // Place on window
    [self.view.window addSubview:_jumpToDateView];
}

- (void)dateSelectionUserSelectedDate {
    NSDate *selectedDate = datePicker.date;
    
    [_jumpToDateView removeFromSuperview];
    [_calendarView jumpToDate:selectedDate];
    
    // Update title on bar
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"LLLL"];
    [self.navigationItem setTitle:[dateFormatter stringFromDate:selectedDate]];
}

- (void)dateSelectionUserCanceled {
    [_jumpToDateView removeFromSuperview];
}

#pragma mark - Opening Calendars List
- (void)openSettingsController {
    SettingsViewController *settingsController = [[SettingsViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Orientation Changed
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [containerWeekPanel setSelectedDayOfWeek:lastSelectedDate];
        [self setView:containerWeekPanel];
        
        [UIView animateWithDuration:duration animations:^{
            CGRect tabBarRect = self.tabBarController.tabBar.frame;
            self.tabBarController.tabBar.frame = CGRectOffset(tabBarRect, 0, 49);
        }];
    }
    
    else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [self setView:containerCalendarWithTable];
        
        [UIView animateWithDuration:duration animations:^{
            CGRect tabBarRect = self.tabBarController.tabBar.frame;
            self.tabBarController.tabBar.frame = CGRectOffset(tabBarRect, 0, -49);
        }];
    }
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
             // Update data source for table
             [self dateSelected:lastSelectedDate manually:NO];
             // Update week panel source
             if (containerWeekPanel.selectedDayOfWeek) {
                 [containerWeekPanel refetch];
             }
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
                 // Update data source for table
                 [self dateSelected:lastSelectedDate manually:NO];
                 // Update week panel source
                 if (containerWeekPanel.selectedDayOfWeek) {
                     [containerWeekPanel refetch];
                 }
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
        
        [self presentViewController:eventViewController animated:YES completion:nil];
    }
    
    if (buttonIndex == 1) {
        // Google event
        GoogleEventEditViewController *editViewController = [[GoogleEventEditViewController alloc] init];
        editViewController.editViewDelegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editViewController];
        
        [self presentViewController:navController animated:YES completion:nil];
    }
}
@end
