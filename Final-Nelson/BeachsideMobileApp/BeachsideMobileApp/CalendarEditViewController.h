//
//  CalendarEditViewController.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    CalendarEditViewActionCanceled,
    CalendarEditViewActionSaved,
    CalendarEditViewActionDeleted
} CalendarEditViewAction;

/*!
 @class      CalendarEditViewController
 @abstract   View controller to create/edit calendars.
 @discussion You can present this view controller to create a new calendar or edit an existing
 calendar. You should present it modally. You both create Google or Apple calendar. Controller will try 
 to access model and corresponding API to create/edit calendar.
 */
@protocol CalendarEditDelegate;

@interface CalendarEditViewController : UIViewController

@property(nonatomic, weak) id<CalendarEditDelegate>  editDelegate;

/*!
 @property   calendar
 @abstract   The calendar to edit.
 @discussion You must set this before presenting the view controller. You can leave
 it set to nil and a new calendar will be created for you. 
 Controller will check if it Apple EKCalendar or Google GTLCalendar.
 */
@property (nonatomic, retain) id calendar;

/*!
 @property   addingAppleCalendar
 @abstract   Set to YES if you are going to create EKCalendar.
 */
@property (nonatomic, getter = isAddingAppleCalendar) BOOL addingAppleCalendar;

@property (weak, nonatomic) IBOutlet UITextField *txt_title;
@property (weak, nonatomic) IBOutlet UITextView *txt_description;

@end


@protocol CalendarEditDelegate <NSObject>
@required
/*!
 @method     calendarEditViewController:didCompleteWithAction:
 @abstract   Called to let delegate know the controller is done editing.
 @discussion When the user presses Cancel, presses Done, or deletes the calendar, this method
 is called. Your delegate is responsible for dismissing the controller. If the editing
 session is terminated programmatically using cancelEditing,
 this method will not be called.
 
 @param      controller          the controller in question
 @param      action              the action that is causing the dismissal
 */
- (void)calendarEditViewController:(CalendarEditViewController*)controller didCompleteWithAction:(CalendarEditViewAction)action;
@end