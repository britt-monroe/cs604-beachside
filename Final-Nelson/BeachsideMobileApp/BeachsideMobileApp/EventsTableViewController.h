//
//  EventsTableViewController.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventsTableViewController : UIViewController

/*
 Set the date selected by user to find events for that date
 */
@property (nonatomic, copy) NSDate *selectedDate;

@end
