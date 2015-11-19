//
//  EventsTableViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "EventsTableViewController.h"

// Event kit
#import <EventKitUI/EventKitUI.h>

// Basic view to view/edit event
#import <EventKitUI/EKEventEditViewController.h>

// Model
#import "BSCalendarModel.h"

@interface EventsTableViewController () <UITableViewDelegate, UITableViewDataSource, EKEventEditViewDelegate>
{
    UITableView *eventsTable;
    UIView *noEventsView;
    // Data source
    NSArray *_events;
}
@end

@implementation EventsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create table view
    [self setEdgesForExtendedLayout:UIRectEdgeNone]; // we don't want table to be under nav bar or status bar
    eventsTable = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    eventsTable.delegate = self;
    eventsTable.dataSource = self;
    [self.view addSubview:eventsTable];
    
    // Create view that holds 'No Events' info
    noEventsView = [[UIView alloc] initWithFrame:self.view.bounds];
    UILabel *lbl_header = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 320, 30)];
    lbl_header.font = [UIFont systemFontOfSize:30];
    lbl_header.textAlignment = NSTextAlignmentCenter;
    lbl_header.text = @"No events";
    lbl_header.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    lbl_header.backgroundColor = [UIColor clearColor];
    UILabel *lbl_text = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(lbl_header.frame), 280, 80)];
    lbl_text.textAlignment = NSTextAlignmentCenter;
    lbl_text.text = @"To add an event press the 'Add' button on the navigation bar";
    lbl_text.numberOfLines = 0;
    lbl_text.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    lbl_text.backgroundColor = [UIColor clearColor];
    [noEventsView addSubview:lbl_header];
    [noEventsView addSubview:lbl_text];
    [noEventsView setBackgroundColor:[UIColor whiteColor]];
    [self.view insertSubview:noEventsView belowSubview:eventsTable];
    
    // Button to add event
    UIBarButtonItem *addEventButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleBordered target:self action:@selector(addEvent)];
    self.navigationItem.rightBarButtonItem = addEventButton;
    
    // Load events array
    [self updateDataSource];
}

#pragma mark - Model. Load events

- (void)updateDataSource {
    [[BSCalendarModel sharedManager] fetchEventsForDate:_selectedDate completion:^(NSArray *eventsArray){
        _events = eventsArray;
        
        [eventsTable reloadData];
    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_events.count == 0) {
        [self.view bringSubviewToFront:noEventsView];
    } else {
        [self.view sendSubviewToBack:noEventsView];
    }
    return _events.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"EventCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    
    // Configure the cell...
    EKEvent *event = _events[indexPath.row];
    cell.textLabel.text = event.title;
    cell.detailTextLabel.text = event.calendar.title;
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EKEvent *event = [_events objectAtIndex:indexPath.row];
    
    EKEventEditViewController *editViewContoller = [[EKEventEditViewController alloc] init];
    editViewContoller.event = event;
    editViewContoller.eventStore = [[BSCalendarModel sharedManager] eventStore];
    editViewContoller.editViewDelegate = self;
    
    [self presentViewController:editViewContoller animated:YES completion:nil];
}

#pragma mark - Add event
- (void)addEvent {
    // Creating event
    EKEventEditViewController *eventViewController = [[EKEventEditViewController alloc] init];
    eventViewController.editViewDelegate = self;
    eventViewController.eventStore = [[BSCalendarModel sharedManager] eventStore];
    
    [self presentViewController:eventViewController animated:YES completion:nil];
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
                 // Reload calendars
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"kALCalendarUpdateEvents" object:nil];
                 
                 // Reload your table view
                 [self updateDataSource];
             }
         }];
    }
}
@end
