//
//  GoogleCalendarListViewController.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GTLCalendarCalendar;

@protocol GoogleCalendarListDelegate;

@interface GoogleCalendarListViewController : UIViewController
@property (nonatomic, weak) id <GoogleCalendarListDelegate>  calendarDelegate;
@end

@protocol GoogleCalendarListDelegate <NSObject>
- (void)googleCalendarListController:(GoogleCalendarListViewController*)controller didSelectCalendar:(GTLCalendarCalendar*)calendar;
@end