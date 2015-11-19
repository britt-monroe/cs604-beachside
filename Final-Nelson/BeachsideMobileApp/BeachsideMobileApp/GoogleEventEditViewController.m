//
//  GoogleEventEditViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "GoogleEventEditViewController.h"

// Google Calendar API
#import "GTLCalendarEvent+Calendar_Property.h" // includes gtlcalendar.h
#import "GPPSignIn.h"
#import "GooglePlus OpenSource/GTMOAuth2Authentication.h"

// Model
#import "BSCalendarModel.h"

// Controller
#import "GoogleCalendarListViewController.h"

@interface GoogleEventEditViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, GoogleCalendarListDelegate>
{
    UITableView *_tableView;
    
    // Navigation Button
    UIBarButtonItem *saveButton;
    
    BOOL datePickerEnabled, datePickerShownUnderStartCell;
    
    // Event cell management
    NSDate *refStartDate, *refEndDate;
    UITextField *locationTextField, *summaryTextField;
    UITextView *descriptionTextView;
    UIDatePicker *datePicker;
    
    GTLCalendarCalendar *selectedCalendar;
}
@end

@implementation GoogleEventEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (!refStartDate) {
        refStartDate = [NSDate date];
        refEndDate = [refStartDate dateByAddingTimeInterval:(60 * 60)];
    }
    
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [self setView:_tableView];
    }
    
    // Calendar ID
    if (!_event) {
        // selectedCalendarId = [GPPSignIn sharedInstance].authentication.userEmail;
    }
    
    // Buttons
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(closeViewController)];
    self.navigationItem.leftBarButtonItem = closeButton;
    
    // Save button
    saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(saveEvent)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    // Cells configuration
    datePickerEnabled = NO;
    datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 320, 162)];
    [datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)closeViewController {
    if ([_editViewDelegate respondsToSelector:@selector(eventGoogleEditViewController:didCompleteWithAction:)]) {
        [_editViewDelegate eventGoogleEditViewController:self didCompleteWithAction:ALGoogleEventEditViewActionCanceled];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return (_event)?5:4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return 2;
            break;
        case 1:
            return (datePickerEnabled)?3:2;
            break;
        case 2:
            return 1;
            break;
        case 3:
            return 1;
            break;
        case 4:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    switch (indexPath.section) {
        case 0:
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GoogleEventSummaryInfoCell"];
            break;
        case 1:
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"GoogleEventTimeInfoCell"];
            break;
        case 2:
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"GoogleEventCalendarInfoCell"];
            break;
        case 3:
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GoogleEventDescriptionInfoCell"];
            break;
        case 4:
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GoogleDeleteEventCell"];
            break;
    }
    // Configure the cell...
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    switch (indexPath.section) {
        case 0:
            [self configureSummaryCell:cell atIndexPath:indexPath];
            break;
        case 1:
            [self configureTimeCell:cell atIndexPath:indexPath];
            break;
        case 2:
            [self configureCalendarInfoCell:cell atIndexPath:indexPath];
            break;
        case 3:
            [self configureDescriptionCell:cell atIndexPath:indexPath];
            break;
        case 4:
            cell.textLabel.text = @"Delete event";
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [UIColor redColor];
            break;
    }
}

- (void)configureSummaryCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row == 0) {
        summaryTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 280, 21)];
        summaryTextField.font = [UIFont systemFontOfSize:15];
        summaryTextField.placeholder = @"Event title";
        summaryTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        summaryTextField.keyboardType = UIKeyboardTypeDefault;
        summaryTextField.returnKeyType = UIReturnKeyDone;
        summaryTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        summaryTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        //textField.delegate = self;
        [cell.contentView addSubview:summaryTextField];

        summaryTextField.text = (_event.summary)?_event.summary:@"";
    } else {
        locationTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 280, 21)];
        locationTextField.font = [UIFont systemFontOfSize:15];
        locationTextField.placeholder = @"Event location";
        locationTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        locationTextField.keyboardType = UIKeyboardTypeDefault;
        locationTextField.returnKeyType = UIReturnKeyDone;
        locationTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        locationTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        //textField.delegate = self;
        [cell.contentView addSubview:locationTextField];
        
        locationTextField.text = (_event.location)?_event.location:@"";
    }
}

- (void)configureTimeCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd LLL y HH:mm"];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Starts:";
        cell.detailTextLabel.text = [dateFormatter stringFromDate:refStartDate];
        
        return;
    }
    
    if (indexPath.row == 1) {
        if (datePickerEnabled) {
            if (datePickerShownUnderStartCell) {
                // Start date picker opened
                [datePicker setDate:refStartDate];
                [cell.contentView addSubview:datePicker];
                cell.clipsToBounds = YES;
            } else {
                cell.textLabel.text = @"Ends:";
                cell.detailTextLabel.text = [dateFormatter stringFromDate:refEndDate];
                cell.detailTextLabel.textColor = ([refEndDate compare:refStartDate] == NSOrderedAscending)?[UIColor redColor]:[UIColor blackColor];
            }
            
        }
        else {
            cell.textLabel.text = @"Ends:";
            cell.detailTextLabel.text = [dateFormatter stringFromDate:refEndDate];
            cell.detailTextLabel.textColor = ([refEndDate compare:refStartDate] == NSOrderedAscending)?[UIColor redColor]:[UIColor blackColor];
        }
        
        return;
    }
    
    if (indexPath.row == 2) {
        if (datePickerEnabled) {
            if (datePickerShownUnderStartCell) {
                cell.textLabel.text = @"Ends:";
                cell.detailTextLabel.text = [dateFormatter stringFromDate:refEndDate];
                cell.detailTextLabel.textColor = ([refEndDate compare:refStartDate] == NSOrderedAscending)?[UIColor redColor]:[UIColor blackColor];
            } else {
                // End date picker opened
                [datePicker setDate:refEndDate];
                [cell.contentView addSubview:datePicker];
                cell.clipsToBounds = YES;
            }
        }
        else {
            cell.textLabel.text = @"Ends:";
            cell.detailTextLabel.text = [dateFormatter stringFromDate:refEndDate];
            cell.detailTextLabel.textColor = ([refEndDate compare:refStartDate] == NSOrderedAscending)?[UIColor redColor]:[UIColor blackColor];
        }
        
        return;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section != 1) {
        if (indexPath.section == 3) {
            return 180.0f;
        } else return 44.0f;
    } else {
        // Time Cells
        switch (indexPath.row) {
            case 0:
                return 44.0f;
                break;
            case 1:
                if (datePickerEnabled) {
                    if (datePickerShownUnderStartCell)
                        return 180.0f;
                    else
                        return 44.0f;
                }
                else return 44.0f;
                break;
            case 2:
                if (datePickerEnabled) {
                    if (datePickerShownUnderStartCell)
                        return 44.0f;
                    else
                        return 180.0f;
                }
                else return 44.0f;
                break;
        }
    }
    
    return 44.0f;
}

- (void)configureDescriptionCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row == 0) {
        descriptionTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, cell.frame.size.width - 20, 160)];
        descriptionTextView.text = (_event.descriptionProperty)?_event.descriptionProperty:@"";
        [cell.contentView addSubview:descriptionTextView];
        cell.clipsToBounds = YES;
    } else {
        
    }
}

- (void)configureCalendarInfoCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Calendar";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // If no event - paste standart google event
        cell.detailTextLabel.text = (selectedCalendar)?selectedCalendar.summary:@"Choose calendar";
    } else {
        
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        
        if (indexPath.row == 0) {
            if (datePickerEnabled) {
                if (datePickerShownUnderStartCell) {
                    // Hide it
                    datePickerEnabled = NO;
                    [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
                }
                else {
                    // Show it under start cell
                    datePickerShownUnderStartCell = YES;
                    [tableView beginUpdates];
                    [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
                    [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationBottom];
                    [tableView endUpdates];
                }
            }
            else {
                // Show it
                datePickerEnabled = YES;
                datePickerShownUnderStartCell = YES;
                [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
            }
            return;
        }
        
        if (indexPath.row == 1) {
            //
            if (datePickerEnabled) {
                if (!datePickerShownUnderStartCell) {
                    // Hide it
                    datePickerEnabled = NO;
                    [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
                }
            }
            else {
                // Show it
                datePickerEnabled = YES;
                datePickerShownUnderStartCell = NO;
                [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
            }
            return;
        }
        
        if (indexPath.row == 2) {
            if (datePickerShownUnderStartCell) {
                datePickerShownUnderStartCell = NO;
                [tableView beginUpdates];
                [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
                [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationBottom];
                [tableView endUpdates];
            }
        }
    }
    
    if (indexPath.section == 2) {
        GoogleCalendarListViewController *googleList = [[GoogleCalendarListViewController alloc] init];
        googleList.calendarDelegate = self;
        [self.navigationController pushViewController:googleList animated:YES];
    }
    
    if (indexPath.section == 4) {
        NSString *actionSheetTitle = @"Are you sure you want to delete this event?"; //Action Sheet Message
        NSString *destructiveButtonTitle = @"Delete event";
        NSString *cancelTitle = @"Cancel";
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                      initWithTitle:actionSheetTitle
                                      delegate:self
                                      cancelButtonTitle:cancelTitle
                                      destructiveButtonTitle:destructiveButtonTitle
                                      otherButtonTitles:nil];
        
        [actionSheet showInView:self.view];
    }
}

#pragma mark - Calendar Choosing
- (void)googleCalendarListController:(GoogleCalendarListViewController *)controller didSelectCalendar:(GTLCalendarCalendar *)calendar {
    selectedCalendar = calendar;
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark -
#pragma mark UIActionSheet deledate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self deleteEvent];
    }
}

#pragma mark -
#pragma mark Event Management

- (void)dateChanged:(id)sender{
    // handle date changes
    NSDate *selectedDate = datePicker.date;
    [_tableView beginUpdates];
    if (datePickerShownUnderStartCell) {
        refStartDate = selectedDate;
        refEndDate = [selectedDate dateByAddingTimeInterval:(60 * 60 *2)];
        
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        refEndDate = selectedDate;
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [_tableView endUpdates];
    // Check for opened picker
    // And update reference dates for corresponding cell
}

- (void)setEvent:(GTLCalendarEvent *)event {
    _event = event;
    
    selectedCalendar = event.calendar;
    
    NSDate *startDate = (event.start.dateTime.date)?event.start.dateTime.date:event.start.date.date;
    refStartDate = startDate;
    NSDate *endDate = (event.end.dateTime.date)?event.end.dateTime.date:event.end.date.date;
    refEndDate = endDate;
}

- (void)saveEvent {
    if (!selectedCalendar) {
        UIAlertView *noCalendarSelectedAlert = [[UIAlertView alloc] initWithTitle:@"Erorr" message:@"Choose Google calendar" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noCalendarSelectedAlert show];
        return;
    }
    
    if (_event) {
        GTLCalendarEventDateTime *startDateTime = [[GTLCalendarEventDateTime alloc] init];
        startDateTime.dateTime = [GTLDateTime dateTimeWithDate:refStartDate timeZone:[NSTimeZone localTimeZone]];
        GTLCalendarEventDateTime *endDateTime = [[GTLCalendarEventDateTime alloc] init];
        endDateTime.dateTime = [GTLDateTime dateTimeWithDate:refEndDate timeZone:[NSTimeZone localTimeZone]];
        _event.start = startDateTime;
        _event.end = endDateTime;
        _event.summary = summaryTextField.text;
        _event.location = locationTextField.text;
        _event.descriptionProperty = descriptionTextView.text;
        
        // Update
        [[BSCalendarModel sharedManager] updateGoogleEvent:_event withCalendarId:selectedCalendar.identifier competion:^(BOOL success, NSError *error){
            if (success) {
                if ([_editViewDelegate respondsToSelector:@selector(eventGoogleEditViewController:didCompleteWithAction:)]) {
                    [_editViewDelegate eventGoogleEditViewController:self didCompleteWithAction:ALGoogleEventEditViewActionSaved];
                }
            } else [self handleErrorWithError:error];
        }];
    } else {
        // Create
        GTLCalendarEvent *createdEvent = [[GTLCalendarEvent alloc] init];
        GTLCalendarEventDateTime *startDateTime = [[GTLCalendarEventDateTime alloc] init];
        startDateTime.dateTime = [GTLDateTime dateTimeWithDate:refStartDate timeZone:[NSTimeZone localTimeZone]];
        GTLCalendarEventDateTime *endDateTime = [[GTLCalendarEventDateTime alloc] init];
        endDateTime.dateTime = [GTLDateTime dateTimeWithDate:refEndDate timeZone:[NSTimeZone localTimeZone]];
        createdEvent.start = startDateTime;
        createdEvent.end = endDateTime;
        createdEvent.summary = summaryTextField.text;
        createdEvent.location = locationTextField.text;
        createdEvent.descriptionProperty = descriptionTextView.text;
        
        [[BSCalendarModel sharedManager] createGoogleEvent:createdEvent withCalendarId:selectedCalendar.identifier competion:^(BOOL success, NSError *error){
            if (success) {
                if ([_editViewDelegate respondsToSelector:@selector(eventGoogleEditViewController:didCompleteWithAction:)]) {
                    [_editViewDelegate eventGoogleEditViewController:self didCompleteWithAction:ALGoogleEventEditViewActionSaved];
                }
            } else [self handleErrorWithError:error];
        }];
    }
}

- (void)deleteEvent {
    [[BSCalendarModel sharedManager] deleteGoogleEvent:_event competion:^(BOOL success, NSError *error){
        if (success) {
            if ([_editViewDelegate respondsToSelector:@selector(eventGoogleEditViewController:didCompleteWithAction:)]) {
                [_editViewDelegate eventGoogleEditViewController:self didCompleteWithAction:ALGoogleEventEditViewActionDeleted];
            }
        } else [self handleErrorWithError:error];
    }];
}

- (void)handleErrorWithError:(NSError*)error {
    NSString *message = (error)?error.description:@"Unable to perform task";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}
@end
