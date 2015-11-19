//
//  BSDaysPanel.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//


#import <UIKit/UIKit.h>

@class BSCalendarViewDateButton;

@protocol BSDaysPanelButtonDelegate;

/* Days Panel
 * Description:
 Days Panel is a view that holds 42 buttons representing 42 days in six weeks.
 */
@interface BSDaysPanel : UIView

/********** Public properties **********/
@property (nonatomic) NSDateComponents *panelDateComponents;
@property (nonatomic) id <BSDaysPanelButtonDelegate> buttonDelegate;

/* Select button */
/**
 *  Selected button with specific date on panel
 *  Method is used by Calendar View in case of moving to new month panel.
 *  @param date Selected date
 */
- (void)selectButtonWithDate:(NSDate*)date;

/**
 *  Reset all indicators on buttons
 */
- (void)removeEventIndicatorsFromButtons;
@end

@protocol BSDaysPanelButtonDelegate <NSObject>
/**
 *  Main delegate method. Tell the handler that button was pressed.
 *
 *  @param panel     Days Panel that contains tapped button
 *  @param button    Calendar Date Button that has been tapped
 *  @param hasTapped Boolean. Yes if user manually tapped the button
 */
- (void)daysPanel:(BSDaysPanel*)panel buttonPressed:(BSCalendarViewDateButton*)button manually:(BOOL)hasTapped;

@optional
/**
 *  Optional method for handling long tap on date button
 *
 *  @param panel  Days Panel that contains tapped button
 *  @param button Calendar Date Button that has been tapped
 */
- (void)daysPanel:(BSDaysPanel *)panel buttonLongPressed:(BSCalendarViewDateButton*)button;
@end