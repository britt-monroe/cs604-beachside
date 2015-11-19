//
//  TabletWeekViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "TabletWeekViewController.h"

// VIEW: Week Panel
#import "BSWeekPanel.h"

// MODEL:
#import "BSCalendarModel.h"

// CONTROLLER: Google Event View Controller
#import "GoogleEventEditViewController.h"

// CONTROLLER: Apple Event View Controller
#import <EventKitUI/EKEventEditViewController.h>

@interface TabletWeekViewController ()
< // Protocols
BSWeekPanelDelegate,           // Handle week panel taps and content
EKEventEditViewDelegate        // Handle user actions with apple events
>

{
    BSWeekPanel *_weekView;
    
}
@end

@implementation TabletWeekViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _weekView = [[BSWeekPanel alloc] init];
    _weekView.weekPanelDelegate = self;
    [self.view addSubview:_weekView];
    //
    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
}

- (void)viewWillLayoutSubviews {
    CGRect viewRect = self.view.bounds;
    
    CGRect weekPanelFrame = CGRectMake(0, 20, CGRectGetWidth(viewRect), CGRectGetHeight(viewRect) - 20);
    _weekView.frame = weekPanelFrame;
    [_weekView setSelectedDayOfWeek:[NSDate date]];
}

#pragma mark - Week Panel Delegate
- (void)weekPanelIsReadyToSetEventsForFirstDay:(NSDate*)firstDate andLastDate:(NSDate*)lastDate {
    [[BSCalendarModel sharedManager] fetchWeekPanelEventsforStartDate:firstDate andEndDate:lastDate completion:^(NSArray *eventsArray){
        [_weekView setEventsArray:eventsArray];
    }];
}

- (void)weekPanelEventSelected:(id)event {
    if ([event isKindOfClass:[EKEvent class]]) {
        EKEventEditViewController *editViewController = [[EKEventEditViewController alloc] init];
        editViewController.event = event;
        editViewController.eventStore = [[BSCalendarModel sharedManager] eventStore];
        editViewController.editViewDelegate = self;
        
        editViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:editViewController animated:YES completion:nil];
    }
    else {
        GTLCalendarEvent *googleEvent = event;
        
        GoogleEventEditViewController *editViewController = [[GoogleEventEditViewController alloc] init];
        editViewController.event = googleEvent;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editViewController];
        
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:nil];
    }
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
                 // Update week panel source
                 if (_weekView.selectedDayOfWeek) {
                     [_weekView refetch];
                 }
             }
         }];
    }
}
@end
