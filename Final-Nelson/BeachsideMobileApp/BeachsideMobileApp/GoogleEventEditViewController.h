//
//  GoogleEventEditViewController.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GTLCalendarEvent;
@protocol BSGoogleEventEditViewDelegate;

typedef enum {
    ALGoogleEventEditViewActionCanceled,
    ALGoogleEventEditViewActionSaved,
    ALGoogleEventEditViewActionDeleted
    // Same as EKEventEditView actions
} BSGoogleEventEditViewAction;

@interface GoogleEventEditViewController : UIViewController
@property (nonatomic, weak) id <BSGoogleEventEditViewDelegate>  editViewDelegate;
@property (nonatomic, copy) GTLCalendarEvent *event;
@end


@protocol BSGoogleEventEditViewDelegate <NSObject>
@required

/**
 * Called to let delegate know the controller is done editing
 * @param      controller          the controller in question
 * @param      action              the action that is causing the dismissal
 */
- (void)eventGoogleEditViewController:(GoogleEventEditViewController *)controller didCompleteWithAction:(BSGoogleEventEditViewAction)action;
@end