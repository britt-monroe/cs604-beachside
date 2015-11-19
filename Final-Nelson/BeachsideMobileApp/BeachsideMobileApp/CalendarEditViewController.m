//
//  CalendarEditViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "CalendarEditViewController.h"

// Google calendar
#import "Google Calendar API/GTLCalendar.h"

// Apple calendar
#import <EventKit/EventKit.h>

// Model
#import "BSCalendarModel.h"

@interface CalendarEditViewController () <UIActionSheetDelegate>
{
    UIBarButtonItem *deleteCalendarButton;
    UIBarButtonItem *saveCalendarButton;
}
@end

@implementation CalendarEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // Minor design
    self.txt_description.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.txt_description.layer.borderWidth = 1.0f;
    self.txt_description.layer.cornerRadius = 5.0;
    
    // Bar Buttons
    // Left button
    UIBarButtonItem *closeViewButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeViewController)];
    self.navigationItem.leftBarButtonItem = closeViewButton;
    
    // Right button
    saveCalendarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(tryToSaveContent)];
    deleteCalendarButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered target:self action:@selector(tryToDeleteCalendar)];
    
    if (_calendar) {
        [self hideDeleteButton:NO];
        [self setUpCalendarInformation];
    } else {
        [self hideDeleteButton:YES];
        self.txt_description.text = @"";
        self.txt_description.editable = (self.isAddingAppleCalendar)?NO:YES;
    }
}

- (void)setUpCalendarInformation {
    if ([_calendar isKindOfClass:[EKCalendar class]]) {
        self.txt_description.editable = NO;
        
        // Parse apple calendar
        EKCalendar *calendar = _calendar;
        self.txt_title.text = calendar.title;
        self.txt_description.text = @"";
        [self hideDeleteButton:(calendar.allowsContentModifications)?NO:YES];
    }
    else {
        self.txt_description.editable = YES;
        
        // Parse google calendar
        GTLCalendarCalendar *calendar = _calendar;
        self.txt_title.text = calendar.summary;
        self.txt_description.text = calendar.descriptionProperty;
    }
}

- (void)hideDeleteButton:(BOOL)hide {
    if (hide) {
        self.navigationItem.rightBarButtonItem = saveCalendarButton;
    } else {
        self.navigationItem.rightBarButtonItems = @[saveCalendarButton, deleteCalendarButton];
    }
}

#pragma mark - Buttons tapped
- (void)closeViewController {
    if ([_editDelegate respondsToSelector:@selector(calendarEditViewController:didCompleteWithAction:)]) {
        [_editDelegate calendarEditViewController:self didCompleteWithAction:CalendarEditViewActionCanceled];
    }
}

- (void)tryToDeleteCalendar {
    NSString *actionSheetTitle = @"Are you sure you want to delete this calendar? All events associated with the calendar will also be deleted."; //Action Sheet Message
    NSString *destructiveButtonTitle = @"Delete Calendar";
    NSString *cancelTitle = @"Cancel";
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:actionSheetTitle
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:destructiveButtonTitle
                                  otherButtonTitles:nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self deleteCalendar];
    }
}

- (void)deleteCalendar {
    if ([_calendar isKindOfClass:[EKCalendar class]]) {
        // Parse apple calendar
        EKCalendar *calendar = _calendar;
        [[BSCalendarModel sharedManager] deleteAppleCalendar:calendar competion:^(BOOL success, NSError *error){
            if (success) {
                if ([_editDelegate respondsToSelector:@selector(calendarEditViewController:didCompleteWithAction:)]) {
                    [_editDelegate calendarEditViewController:self didCompleteWithAction:CalendarEditViewActionDeleted];
                }
            } else {
                [self handleErrorWithError:error];
            }
        }];
    }
    else {
        // Parse google calendar
        GTLCalendarCalendar *calendar = _calendar;
        [[BSCalendarModel sharedManager] deleteGoogleCalendarWithIdentifier:calendar.identifier competion:^(BOOL success, NSError *error){
            if (success) {
                if ([_editDelegate respondsToSelector:@selector(calendarEditViewController:didCompleteWithAction:)]) {
                    [_editDelegate calendarEditViewController:self didCompleteWithAction:CalendarEditViewActionDeleted];
                }
            } else {
                [self handleErrorWithError:error];
            }
        }];
    }
}

- (void)tryToSaveContent {
    NSString *calendarTitle = self.txt_title.text;
    NSString *calendarDescription = self.txt_description.text;
    
    // Check if title text field blank text
    if ([calendarTitle isEqualToString:@""]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please, create calendar title" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    if (self.isAddingAppleCalendar) {
        [[BSCalendarModel sharedManager] createAppleCalendarWithTitle:calendarTitle competion:^(BOOL success, NSError *error){
            if (success) {
                if ([_editDelegate respondsToSelector:@selector(calendarEditViewController:didCompleteWithAction:)]) {
                    [_editDelegate calendarEditViewController:self didCompleteWithAction:CalendarEditViewActionSaved];
                }
            } else {
                [self handleErrorWithError:error];
            }
        }];
    } else {
        // Creating google calendar
        GTLCalendarCalendar *calendar = [[GTLCalendarCalendar alloc] init];
        [calendar setSummary:calendarTitle];
        [calendar setDescriptionProperty:calendarDescription];
        [[BSCalendarModel sharedManager] createGoogleCalendar:calendar competion:^(BOOL success, NSError *error){
            if (success) {
                if ([_editDelegate respondsToSelector:@selector(calendarEditViewController:didCompleteWithAction:)]) {
                    [_editDelegate calendarEditViewController:self didCompleteWithAction:CalendarEditViewActionSaved];
                }
            } else {
                [self handleErrorWithError:error];
            }
        }];
    }
}

- (void)handleErrorWithError:(NSError*)error {
    NSString *message = (error)?error.description:@"Unable to perform task";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}
@end
