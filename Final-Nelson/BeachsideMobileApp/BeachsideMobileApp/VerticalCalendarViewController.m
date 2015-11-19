//
//  VerticalCalendarViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

// CONTROLLER: Vertical
#import "VerticalCalendarViewController.h"

// VIEW: Calendar
#import "BSCalendarView.h"

// MODEL:
#import "BSCalendarModel.h"

// Simple VC to check Event details
#import <EventKitUI/EKEventViewController.h>

// Table view with events for selected date
#import "EventsTableViewController.h"

// Calendars table
#import "CalendarsListViewController.h"

@interface VerticalCalendarViewController () <BSCalendarDelegate>
{
    // Calendar
    BSCalendarView *_calendarView;
    // Date Selection View
    UIView *_jumpToDateView;
    UIDatePicker *datePicker;
}
@end

@implementation VerticalCalendarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set calendar view
    CGRect viewRect = self.view.bounds;
    CGRect calendarFrame = CGRectMake(CGRectGetMinX(viewRect),
                                      CGRectGetMinY(viewRect),
                                      CGRectGetWidth(viewRect),
                                      CGRectGetHeight(viewRect) - CGRectGetHeight(self.tabBarController.tabBar.frame) - CGRectGetHeight(self.navigationController.navigationBar.frame) - 20);
    _calendarView = [[BSCalendarView alloc] initVerticalCalendarWithNumberOfPanels:5 andWithFrame:calendarFrame];
    _calendarView.calendarDelegate = self;
    [self.view addSubview:_calendarView];
    
    // Update title on bar
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"LLLL"];
    [self.navigationItem setTitle:[dateFormatter stringFromDate:[NSDate date]]];
    
    /* Jump To Date Button */
    UIBarButtonItem *jumptodateButton = [[UIBarButtonItem alloc] initWithTitle:@"Jump" style:UIBarButtonItemStyleBordered target:self action:@selector(showDateSelectionView)];
    self.navigationItem.leftBarButtonItem = jumptodateButton;
    
    /* Calendars List Button */
    UIBarButtonItem *calendarListButton = [[UIBarButtonItem alloc] initWithTitle:@"Calendars" style:UIBarButtonItemStyleBordered target:self action:@selector(openCalendarsList)];
    self.navigationItem.rightBarButtonItem = calendarListButton;
}

#pragma mark - Opening Calendars List
- (void)openCalendarsList {
    CalendarsListViewController *calendarsViewController = [[CalendarsListViewController alloc] init];
    calendarsViewController.hidesBottomBarWhenPushed = YES;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:calendarsViewController];
    
    [self presentViewController:navigationController animated:YES completion:nil];
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
    // Not to open table with events on loading and jump to date function
    if (!hasTapped) {
        return;
        // You can delete this boolean if you are going to use table view with vertical calendar on one view
    }
    
    EventsTableViewController *eventsTableController = [[EventsTableViewController alloc] init];
    eventsTableController.selectedDate = date;
    eventsTableController.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:eventsTableController animated:YES];
}

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
@end
