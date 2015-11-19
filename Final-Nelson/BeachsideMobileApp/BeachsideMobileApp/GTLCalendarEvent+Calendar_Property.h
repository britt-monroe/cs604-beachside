//
//  GTLCalendarEvent+Calendar_Property.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "GTLCalendar.h"

@interface GTLCalendarEvent (Calendar_Property)

// Apple way. Save link to parent calendar
@property (nonatomic, copy) GTLCalendarCalendar *calendar;
@end
