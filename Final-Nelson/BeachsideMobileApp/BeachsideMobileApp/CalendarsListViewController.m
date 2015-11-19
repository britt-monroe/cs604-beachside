//
//  CalendarsListViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "CalendarsListViewController.h"

// Model
#import "BSCalendarModel.h"

// Controller: Edit/Create calendar
#import "CalendarEditViewController.h"

// Google Calendar API
#import "Google Calendar API/GTLCalendar.h"

// Event kit
#import <EventKitUI/EventKitUI.h>

@interface CalendarsListViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, CalendarEditDelegate>
{
    NSMutableArray *preferredCalendars; // Array with identifiers
    NSDictionary *calendarTypes;
    
    UITableView *calendarsTableView;
}
@end

@implementation CalendarsListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    calendarsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    calendarsTableView.delegate = self;
    calendarsTableView.dataSource = self;
    [self setView:calendarsTableView];

    // Left button
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    // Right buttons
    UIBarButtonItem *closeViewButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(closeViewController)];
    UIBarButtonItem *addCalendarButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleBordered target:self action:@selector(showActionSheet)];
    self.navigationItem.rightBarButtonItems = @[closeViewButton, addCalendarButton];

    preferredCalendars = [[[BSCalendarModel sharedManager] preferredCalendars] mutableCopy];
    if (!preferredCalendars) preferredCalendars = [NSMutableArray array];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[BSCalendarModel sharedManager] fetchCalendarsListWithCompletionHandler:^(NSDictionary *calendarsDictionary){
        calendarTypes = calendarsDictionary;
        
        [calendarsTableView reloadData];
    }];
}

#pragma mark - Navigation
- (void)closeViewController {
    [[BSCalendarModel sharedManager] setPreferredCalendars:preferredCalendars];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return calendarTypes.allValues.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSString *key = calendarTypes.allKeys[section];
    NSArray *calendars = calendarTypes[key];
    return calendars.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CalendarCell";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Configure the cell...
    if (self.editing) {
        [self configureEditingCell:cell atIndexPath:indexPath];
    } else {
        [self configureCell:cell atIndexPath:indexPath];
    }
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    BOOL contains;
    NSString *key = calendarTypes.allKeys[indexPath.section];
    NSArray *calendars = calendarTypes[key];
    id object = calendars[indexPath.row];
    if ([object isKindOfClass:[EKCalendar class]]) {
        EKCalendar *calendar = (EKCalendar*)object;
        cell.textLabel.text = calendar.title;
        contains = ([preferredCalendars indexOfObject:calendar.calendarIdentifier] != NSNotFound)?YES:NO;
    }
    
    else {
        GTLCalendarCalendar *googleCalendar = (GTLCalendarCalendar*)object;
        cell.textLabel.text = googleCalendar.summary;
        contains = ([preferredCalendars indexOfObject:googleCalendar.identifier] != NSNotFound)?YES:NO;
    }
    
    if (preferredCalendars.count == 0) contains = NO;
    
    NSString *fileName = (contains)?@"cell_checkmark.png":@"cell_dot.png";
    cell.imageView.image = [UIImage imageNamed:fileName];
    cell.imageView.contentMode = UIViewContentModeCenter;
    
    cell.textLabel.textColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)configureEditingCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {

    NSString *key = calendarTypes.allKeys[indexPath.section];
    NSArray *calendars = calendarTypes[key];
    id object = calendars[indexPath.row];
    if ([object isKindOfClass:[EKCalendar class]]) {
        EKCalendar *calendar = (EKCalendar*)object;
        cell.textLabel.text = calendar.title;
        if ((calendar.source.sourceType == EKSourceTypeCalDAV) || (calendar.source.sourceType == EKSourceTypeLocal)) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.textColor = [UIColor blackColor];
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textColor = [UIColor lightGrayColor];
        }
    }
    
    else {
        GTLCalendarCalendar *googleCalendar = (GTLCalendarCalendar*)object;
        cell.textLabel.text = googleCalendar.summary;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.imageView.image = nil;
    cell.imageView.contentMode = UIViewContentModeCenter;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return calendarTypes.allKeys[section];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [calendarsTableView reloadData];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        [self pushCalendarInfoAtIndexPath:indexPath];
        return;
    }
    
    NSString *key = calendarTypes.allKeys[indexPath.section];
    NSArray *calendars = calendarTypes[key];
    id object = calendars[indexPath.row];
    
    NSString *calendarID;
    BOOL contains;
    
    if ([object isKindOfClass:[EKCalendar class]]) {
        EKCalendar *calendar = object;
        calendarID = calendar.calendarIdentifier;
        contains = ([preferredCalendars indexOfObject:calendarID] != NSNotFound)?YES:NO;
    }
    else {
        GTLCalendarCalendar *calendar = object;
        calendarID = calendar.identifier;
        contains = ([preferredCalendars indexOfObject:calendarID] != NSNotFound)?YES:NO;
    }
    
    if (preferredCalendars.count == 0) contains = NO;
    
    if (contains) {
        [preferredCalendars removeObject:calendarID];
    }
    else {
        [preferredCalendars addObject:calendarID];
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *fileName = (!contains)?@"cell_checkmark.png":@"cell_dot.png";
    cell.imageView.image = [UIImage imageNamed:fileName];
}

- (void)pushCalendarInfoAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    CalendarEditViewController *calendarViewController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CalendarEditViewController class])];
    
    NSString *key = calendarTypes.allKeys[indexPath.section];
    NSArray *calendars = calendarTypes[key];
    id object = calendars[indexPath.row];
    if ([object isKindOfClass:[EKCalendar class]]) {
        EKCalendar *calendar = (EKCalendar*)object;
        calendarViewController.calendar = calendar;
        
        if ((calendar.source.sourceType != EKSourceTypeCalDAV) && (calendar.source.sourceType != EKSourceTypeLocal)) {
            return;
        }
    }
    
    else {
        GTLCalendarCalendar *googleCalendar = (GTLCalendarCalendar*)object;
        calendarViewController.calendar = googleCalendar;
    }
    
    calendarViewController.editDelegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:calendarViewController];
    [self presentViewController:navigationController animated:YES completion:^(){
        // To prevent some problems
        [self setEditing:NO];
    }];
}

#pragma mark -
#pragma mark Action Sheet Management

- (void)showActionSheet {
    NSString *actionSheetTitle = @"Create calendar"; //Action Sheet Title
    NSString *other1 = @"Apple calendar";
    NSString *other2 = @"Google calendar";
    NSString *cancelTitle = @"Cancel";
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:actionSheetTitle
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:other1, other2, nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 2) {
        return; // Cancel
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    CalendarEditViewController *calendarViewController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CalendarEditViewController class])];
    calendarViewController.addingAppleCalendar = (buttonIndex == 0)?YES:NO;
    calendarViewController.editDelegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:calendarViewController];
    [self presentViewController:navigationController animated:YES completion:^(){
        // To prevent some problems
        [self setEditing:NO];
    }];
}

#pragma mark -
#pragma mark Calendar Edit View Delegate
- (void)calendarEditViewController:(CalendarEditViewController*)controller didCompleteWithAction:(CalendarEditViewAction)action {
    if (action == CalendarEditViewActionCanceled) {
        [controller dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    if (action == CalendarEditViewActionSaved) {
        [[BSCalendarModel sharedManager] fetchCalendarsListWithCompletionHandler:^(NSDictionary *calendarsDictionary){
            calendarTypes = calendarsDictionary;
            
            [calendarsTableView reloadData];
            
            [controller dismissViewControllerAnimated:YES completion:nil];
            return;
        }];
    }
    
    if (action == CalendarEditViewActionDeleted) {
        [[BSCalendarModel sharedManager] fetchCalendarsListWithCompletionHandler:^(NSDictionary *calendarsDictionary){
            calendarTypes = calendarsDictionary;
            
            [calendarsTableView reloadData];
            
            [controller dismissViewControllerAnimated:YES completion:nil];
            return;
        }];
    }
}
@end
