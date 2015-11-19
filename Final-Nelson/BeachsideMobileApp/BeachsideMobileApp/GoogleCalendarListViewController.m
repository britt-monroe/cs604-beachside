//
//  GoogleCalendarListViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "GoogleCalendarListViewController.h"

// Model
#import "BSCalendarModel.h"

// Google API
#import "GTLCalendarEvent+Calendar_Property.h" // includes gtlcalendar.h

@interface GoogleCalendarListViewController () <UITableViewDataSource, UITableViewDelegate>
{
    UITableView *calendarsTableView;
    
    NSArray *googleCalendarsArray;
}
@end

@implementation GoogleCalendarListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize table view
    if (!calendarsTableView) {
        calendarsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        calendarsTableView.delegate = self;
        calendarsTableView.dataSource = self;
        [self setView:calendarsTableView];
    }
    
    // Ask for content
    [[BSCalendarModel sharedManager] fetchCalendarsListWithCompletionHandler:^(NSDictionary *calendarsDictionary){
        googleCalendarsArray = calendarsDictionary[@"Google"];
        [calendarsTableView reloadData];
    }];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return googleCalendarsArray.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"GoogleCalendarCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    GTLCalendarCalendar *calendar = googleCalendarsArray[indexPath.row];
    cell.textLabel.text = calendar.summary;
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GTLCalendarCalendar *calendar = googleCalendarsArray[indexPath.row];
    if ([_calendarDelegate respondsToSelector:@selector(googleCalendarListController:didSelectCalendar:)]) {
        [_calendarDelegate googleCalendarListController:self didSelectCalendar:calendar];
    }
}
@end
