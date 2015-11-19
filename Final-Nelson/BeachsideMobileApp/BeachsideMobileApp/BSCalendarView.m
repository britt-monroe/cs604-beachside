//
//  BSHorizontalCalendarView.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "BSCalendarView.h"
#import <EventKit/EventKit.h>

// Date buttons
#import "BSCalendarViewDateButton.h"

// Days Panel
#import "BSDaysPanel.h"

// Google Calendar API
#import "Google Calendar API/GTLCalendar.h"

@implementation NSCalendar (MySpecialCalculations)
-(NSInteger)daysWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate
{
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setTimeZone:[NSTimeZone localTimeZone]];
    NSDate *newDate1 = [startDate dateByAddingTimeInterval:[[NSTimeZone localTimeZone] secondsFromGMT]];
    NSDate *newDate2 = [endDate dateByAddingTimeInterval:[[NSTimeZone localTimeZone] secondsFromGMT]];
    
    NSInteger startDay=[gregorian ordinalityOfUnit:NSDayCalendarUnit
                                            inUnit: NSEraCalendarUnit forDate:newDate1];
    NSInteger endDay=[gregorian ordinalityOfUnit:NSDayCalendarUnit
                                          inUnit: NSEraCalendarUnit forDate:newDate2];
    return endDay-startDay;
}
@end

/* Calendar
 * Description:
 Calendar with scroll view and defined number of loaded month.
 It is not infinite, so if user scroll to the end of content size, there will be nothing.
 New month is loaded as user scrolls to last or first month or JumpToDate method is used.
 */
@interface BSCalendarView () <UIScrollViewDelegate, BSDaysPanelButtonDelegate>
{
    /* View frame */
    CGRect calendarBounds;
    /* Calendar type */
    BOOL isVerticallyOriented;
    BOOL tabletVersion;
    /* Scroll view that contain calendars */
    UIScrollView *_scrollView;
    /* Calendar attributes */
    NSCalendar *calendar;
    NSInteger selectedButtonIndex;
    /* Selected date - jump to date */
    NSDateComponents *selectedDateComponents;
}
@end

@implementation BSCalendarView

// Notification key
NSString * const kALCalendarUpdateEventsNotification = @"kALCalendarUpdateEvents";


#pragma mark - Initialization and Memory Management

/* Create calendar with vertical scrolling */
- (id)initVerticalCalendarWithNumberOfPanels:(NSInteger)numberOfPanels andWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        isVerticallyOriented = YES;
        tabletVersion = NO;
        
        // Update property
        _numberOfPanels = (numberOfPanels > 0)?numberOfPanels:5;
        
        // Save rect
        calendarBounds = self.bounds;
        
        /* Set calendar properties */
        calendar = [NSCalendar currentCalendar];
        [calendar setLocale:[NSLocale currentLocale]];
        [calendar setFirstWeekday:2];
        
        /* Create and place week panel */
        CGFloat sideGap = 5.0;
        CGFloat buttonsGap = 1.0;
        CGFloat contentWidth = calendarBounds.size.width - 2 * sideGap - 6 * buttonsGap;
        CGFloat cellWidth = contentWidth/7;
        UIView *weekPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, calendarBounds.size.width, 24)];
        weekPanel.backgroundColor = [UIColor clearColor];
        NSArray *daysOfWeek = @[@"Mo",@"Tu",@"We",@"Th",@"Fr",@"Sa",@"Su"];
        [daysOfWeek enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            NSString *weekDay = (NSString*)obj;
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(idx*(cellWidth + buttonsGap) + sideGap, 0, cellWidth, weekPanel.frame.size.height)];
            [label setText:weekDay];
            [label setTextAlignment:NSTextAlignmentCenter];
            [weekPanel addSubview:label];
        }];
        [self addSubview:weekPanel];
        
        /* Create scroll view to hold days panels */
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(weekPanel.frame), calendarBounds.size.width, calendarBounds.size.height - CGRectGetHeight(weekPanel.frame))];
        [_scrollView setContentSize:CGSizeMake(frame.size.width, (frame.size.height - CGRectGetHeight(weekPanel.frame)) * _numberOfPanels)];
        [_scrollView setPagingEnabled:YES];
        [_scrollView setShowsVerticalScrollIndicator:NO];
        [_scrollView setDelegate:self];

        /* Create and place Days Panels on scroll view */
        for (int index = 0; index < _numberOfPanels; index++) {
            CGRect viewFrame = CGRectMake(0, index * _scrollView.bounds.size.height, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
            BSDaysPanel *daysPanel = [[BSDaysPanel alloc] initWithFrame:viewFrame];
            daysPanel.buttonDelegate = self;
            [daysPanel setTag:(index + 100)];
            [_scrollView addSubview:daysPanel];
        }
        [self addSubview:_scrollView];
        
        /* Register for notifications */
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateEventsNotificationReceived)
                                                     name:kALCalendarUpdateEventsNotification object:nil];
    }
    return self;
}

/* Create calendar with horizontal scrolling */
- (id)initHorizontalCalendarWithNumberOfPanels:(NSInteger)numberOfPanels andWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        isVerticallyOriented = NO;
        tabletVersion = NO;
        
        // Update property
        _numberOfPanels = (numberOfPanels > 0)?numberOfPanels:5;
        
        // Save rect
        calendarBounds = self.bounds;
        
        /* Set calendar properties */
        calendar = [NSCalendar currentCalendar];
        [calendar setLocale:[NSLocale currentLocale]];
        [calendar setFirstWeekday:2];
        
        /* Create and place week panel */
        CGFloat sideGap = 5.0;
        CGFloat buttonsGap = 1.0;
        CGFloat contentWidth = calendarBounds.size.width - 2 * sideGap - 6 * buttonsGap;
        CGFloat cellWidth = contentWidth/7;
        UIView *weekPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, calendarBounds.size.width, 24)];
        weekPanel.backgroundColor = [UIColor clearColor];
        NSArray *daysOfWeek = @[@"Mo",@"Tu",@"We",@"Th",@"Fr",@"Sa",@"Su"];
        [daysOfWeek enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            NSString *weekDay = (NSString*)obj;
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(idx*(cellWidth + buttonsGap) + sideGap, 0, cellWidth, weekPanel.frame.size.height)];
            [label setText:weekDay];
            [label setTextAlignment:NSTextAlignmentCenter];
            [weekPanel addSubview:label];
        }];
        [self addSubview:weekPanel];
        
        /* Create scroll view to hold days panels */
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(weekPanel.frame), calendarBounds.size.width, calendarBounds.size.height - CGRectGetHeight(weekPanel.frame))];
        [_scrollView setContentSize:CGSizeMake(calendarBounds.size.width * _numberOfPanels, calendarBounds.size.height - CGRectGetHeight(weekPanel.frame))];
        [_scrollView setPagingEnabled:YES];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        [_scrollView setDelegate:self];
        
        /* Create and place Days Panels on scroll view */
        for (int index = 0; index < _numberOfPanels; index++) {
            CGRect viewFrame = CGRectMake(index * _scrollView.bounds.size.width, 0, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
            BSDaysPanel *daysPanel = [[BSDaysPanel alloc] initWithFrame:viewFrame];
            daysPanel.buttonDelegate = self;
            [daysPanel setTag:(index + 100)];
            [_scrollView addSubview:daysPanel];
        }
        [self addSubview:_scrollView];
        
        /* Register for notifications */
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateEventsNotificationReceived)
                                                     name:kALCalendarUpdateEventsNotification object:nil];
    }
    return self;
}

- (id)initCalendarViewForTablet {
    self = [super init];
    if (self) {
        // Update property
        _numberOfPanels = 12;
        tabletVersion = YES;
        
        /* Set calendar properties */
        calendar = [NSCalendar currentCalendar];
        [calendar setLocale:[NSLocale currentLocale]];
        [calendar setFirstWeekday:2];
        
        // Using scroll view as views container
        _scrollView = [[UIScrollView alloc] init];
        [self addSubview:_scrollView];
        
        /* Register for notifications */
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateEventsNotificationReceived)
                                                     name:kALCalendarUpdateEventsNotification object:nil];
    }
    return self;
}

- (void)tablet_updatePanelPosition {
    for (UIView *subview in [NSArray arrayWithArray:[_scrollView subviews]]) {
        [subview removeFromSuperview];
    }
    
    // Horizontal or vertical?
    CGRect viewRect = _scrollView.bounds;
    CGFloat height = CGRectGetHeight(viewRect);
    CGFloat width = CGRectGetWidth(viewRect);
    isVerticallyOriented = (height > width)?YES:NO;
    
    /* Create and place week panels */
    CGFloat sideGap = 5.0f;
    CGFloat buttonsGap = 1.0f;
    CGFloat weekPanelHeight = 24.0f;
    NSInteger rows = (isVerticallyOriented)?4:3;
    NSInteger columns = (isVerticallyOriented)?3:4;
    CGFloat panelWidth = (width - (columns + 1) * sideGap) / columns;
    CGFloat panelHeight = (height - (rows + 1) * sideGap) / rows;
    CGFloat contentWidth = panelWidth - 6 * buttonsGap;
    CGFloat cellWidth = contentWidth/7;
    
    NSInteger tagIndex = 100;
    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger column = 0; column < columns; column++) {
            UIView *weekPanel = [[UIView alloc] initWithFrame:CGRectMake(sideGap + column * sideGap + column * panelWidth,
                                                                         sideGap + row * sideGap + row * panelHeight,
                                                                         panelWidth,
                                                                         weekPanelHeight)];
            weekPanel.backgroundColor = [UIColor clearColor];
            NSArray *daysOfWeek = @[@"Mo",@"Tu",@"We",@"Th",@"Fr",@"Sa",@"Su"];
            [daysOfWeek enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
                NSString *weekDay = (NSString*)obj;
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(idx*(cellWidth + buttonsGap) + sideGap, 0, cellWidth, weekPanelHeight)];
                [label setText:weekDay];
                [label setTextAlignment:NSTextAlignmentCenter];
                [weekPanel addSubview:label];
            }];
            [_scrollView addSubview:weekPanel];
            
            CGRect viewFrame = CGRectMake(sideGap + column * sideGap + column * panelWidth,
                                          sideGap + row * sideGap + row * panelHeight + weekPanelHeight,
                                          panelWidth,
                                          panelHeight - weekPanelHeight);
            BSDaysPanel *daysPanel = [[BSDaysPanel alloc] initWithFrame:viewFrame];
            daysPanel.buttonDelegate = self;
            [daysPanel setTag:tagIndex];
            tagIndex++;
            [_scrollView addSubview:daysPanel];
        }
    }
}

- (void)layoutSubviews {
    [self setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
    if (tabletVersion) {
        _scrollView.frame = self.bounds;
        [self tablet_updatePanelPosition];
    }
    
    /* When loaded - show current month */
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour) fromDate:[NSDate date]];
    [self setDatesOnAllDaysPanelsWithDateComponents:dateComponents];
}

- (void)jumpToDate:(NSDate*)selectedDate {
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour) fromDate:selectedDate];
    [self setDatesOnAllDaysPanelsWithDateComponents:dateComponents];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setting up dates

/* Define what month to set on day panel */
- (void)setDatesOnAllDaysPanelsWithDateComponents:(NSDateComponents*)dateComponents {
    selectedDateComponents = [dateComponents copy];
    
    NSInteger chosedMonth = dateComponents.month;
    NSDate *chosedDate = [calendar dateFromComponents:dateComponents];

    NSInteger centralPanelIndex = floorf(_numberOfPanels/2);
    
    // Split to two arrays
    NSMutableArray *daysPanels = [NSMutableArray array];
    for (UIView *view in _scrollView.subviews) {
        if ([view isKindOfClass:[BSDaysPanel class]]) {
            [daysPanels addObject:view];
        }
    }
    NSArray *rightPanels = [daysPanels subarrayWithRange:NSMakeRange(centralPanelIndex + 1, (daysPanels.count - 1) - centralPanelIndex)];
    NSArray *leftPanels = [[[daysPanels subarrayWithRange:NSMakeRange(0, centralPanelIndex)] reverseObjectEnumerator] allObjects];
    
    // Set dates for central panel
    BSDaysPanel *centralPanel = [daysPanels objectAtIndex:centralPanelIndex];
    centralPanel.panelDateComponents.month = chosedMonth;
    centralPanel.panelDateComponents.year = dateComponents.year;
    [self configureDatesOnDaysPanel:centralPanel startWithWeek:[self weekOfYearForFirstDayOfMonth:dateComponents] requestForEvents:YES];
    
    // Configure dates for panels on the right
    NSDateComponents *nextMonthComponents = [[NSDateComponents alloc] init];
    nextMonthComponents.month = 1;
    NSDate *nextMonth = [calendar dateByAddingComponents:nextMonthComponents toDate:chosedDate options:0];
    for (BSDaysPanel *panel in rightPanels) {
        // Define components of next month
        NSDateComponents *_components = [calendar components:(NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:nextMonth];
        panel.panelDateComponents.month = _components.month;
        panel.panelDateComponents.year = _components.year;
        [self configureDatesOnDaysPanel:panel startWithWeek:[self weekOfYearForFirstDayOfMonth:_components] requestForEvents:YES];
        // Increment
        nextMonthComponents.month = 1;
        nextMonth = [calendar dateByAddingComponents:nextMonthComponents toDate:nextMonth options:0];
    }
    
    // Configure dates for panels on the left
    NSDateComponents *previousMonthComponents = [[NSDateComponents alloc] init];
    previousMonthComponents.month = -1;
    NSDate *previousMonth = [calendar dateByAddingComponents:previousMonthComponents toDate:chosedDate options:0];
    for (BSDaysPanel *panel in leftPanels) {
        // Define components for previous month
        NSDateComponents *_components = [calendar components:(NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:previousMonth];
        panel.panelDateComponents.month = _components.month;
        panel.panelDateComponents.year = _components.year;
        [self configureDatesOnDaysPanel:panel startWithWeek:[self weekOfYearForFirstDayOfMonth:_components] requestForEvents:YES];
        // Decrement
        previousMonthComponents.month = -1;
        previousMonth = [calendar dateByAddingComponents:previousMonthComponents toDate:previousMonth options:0];
    }
    
    // Move scroll to central panel
    // If you are using jumpToDate function, selected month will be on the central panel
    if (tabletVersion) return;
    
    if (isVerticallyOriented) {
        [_scrollView setContentOffset:CGPointMake(0, floorf(_numberOfPanels/2) * _scrollView.frame.size.height)];
    } else {
        [_scrollView setContentOffset:CGPointMake(floorf(_numberOfPanels/2) * _scrollView.frame.size.width, 0)];
    }
}

/* Placing right dates on day panel */
- (void)configureDatesOnDaysPanel:(BSDaysPanel*)panel startWithWeek:(NSInteger)weekNumber requestForEvents:(BOOL)sendRequest {
    NSInteger tagIndex = 11;
    
    // That't for highlighting today
    NSDateComponents *currentDateComponents = [calendar components:(NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear) fromDate:[NSDate date]];
    
    // Get first day for that panel
    // 1. Get first day of second week
    NSDateComponents *firstDayOfSecondWeekComps = [[NSDateComponents alloc] init];
    firstDayOfSecondWeekComps.weekOfYear = weekNumber + 1;
    firstDayOfSecondWeekComps.weekday = 2;
    firstDayOfSecondWeekComps.hour = 12;
    firstDayOfSecondWeekComps.year = panel.panelDateComponents.year;
    NSDate *firstDayOfSecondWeekDate = [calendar dateFromComponents:firstDayOfSecondWeekComps];
    // 2. Substract one week
    NSDateComponents *componentsForFirstDay = [[NSDateComponents alloc] init];
    //componentsForFirstDay.week = -1; // Method was deprecated
    componentsForFirstDay.weekOfYear = -1;
    
    // 3. Got it
    NSDate *firstDayOfPanelDate = [calendar dateByAddingComponents:componentsForFirstDay toDate:firstDayOfSecondWeekDate options:0];
    
    // Cycle Logic: Create first day - Place on panel - Go to next
    NSDateComponents *nextDayComponents = [[NSDateComponents alloc] init];
    nextDayComponents.day = 1;
    
    for (NSInteger i = 0; i < 6; i++) {
        for (NSInteger j = 0; j < 7; j++) {
            NSDateComponents *interimDateComponents = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth) fromDate:firstDayOfPanelDate];
            
            // Get the right label
            BSCalendarViewDateButton *dateButton = (BSCalendarViewDateButton*)[panel viewWithTag:tagIndex];
            [dateButton setTitle:[NSString stringWithFormat:@"%ld",(long)interimDateComponents.day] forState:UIControlStateNormal];
            [dateButton setAlpha:(interimDateComponents.month != panel.panelDateComponents.month)?0.5:1.0];
            // Set blank
            [dateButton deselectAsToday];
            [dateButton hasNoEvents];
            // Set date
            [dateButton setDate:firstDayOfPanelDate];
            
            // Search for selected date
            if ((selectedDateComponents.month == interimDateComponents.month) && (selectedDateComponents.day == interimDateComponents.day) && (selectedDateComponents.year == panel.panelDateComponents.year)) {
                // Here is selected date
                if(panel.panelDateComponents.month == selectedDateComponents.month) {
                    [dateButton selectDateButton];
                    [self daysPanel:panel buttonPressed:dateButton manually:NO];
                }
            }
            
            // Search for today
            if ((currentDateComponents.month == interimDateComponents.month) && (currentDateComponents.day == interimDateComponents.day) && (currentDateComponents.year == panel.panelDateComponents.year)) {
                // Here is today
                // Select on panels if exists
                [dateButton selectAsTodayButton];
            }
            
            firstDayOfPanelDate = [calendar dateByAddingComponents:nextDayComponents toDate:firstDayOfPanelDate options:0];
            tagIndex++;
        }
    }
    
    /* Send request to VC */
    if (!sendRequest) return;
    
    if ([_calendarDelegate respondsToSelector:@selector(daysPanel:isReadyToSetEventsForFirstDate:andLastDate:)]) {
        BSCalendarViewDateButton *firstDateButton = (BSCalendarViewDateButton*)[panel viewWithTag:11];
        BSCalendarViewDateButton *lastDateButton = (BSCalendarViewDateButton*)[panel viewWithTag:52];
        [_calendarDelegate daysPanel:panel.tag isReadyToSetEventsForFirstDate:firstDateButton.date andLastDate:lastDateButton.date];
    }
}

#pragma mark - Setting up events
- (void)setEventsArray:(NSArray*)eventsArray onDaysPanelWithIndex:(NSInteger)panelIndex {
    
    BSDaysPanel *panel = (BSDaysPanel*)[_scrollView viewWithTag:panelIndex];
    [panel removeEventIndicatorsFromButtons];
    
    BSCalendarViewDateButton *dateButton = (BSCalendarViewDateButton*)[panel viewWithTag:11];
    NSDate *firstDateOnPanel = dateButton.date;
    
    for (id object in eventsArray) {
        NSDate *startDate, *endDate;
        BOOL allDay;
        if ([object isKindOfClass:[EKEvent class]]) {
            EKEvent *event = object;
            startDate = event.startDate;
            endDate = event.endDate;
            allDay = event.allDay;
        } else {
            GTLCalendarEvent *event = object;
            startDate = (event.start.dateTime.date)?event.start.dateTime.date:event.start.date.date;
            endDate = (event.end.dateTime.date)?event.end.dateTime.date:event.end.date.date;
            allDay = NO; // Didn't find property yet
        }
        
        NSInteger dateDifference = [calendar daysWithinEraFromDate:firstDateOnPanel toDate:startDate];
        BSCalendarViewDateButton *eventStartDateButton = (BSCalendarViewDateButton*)[panel viewWithTag:(dateDifference + 11)];
        if (eventStartDateButton.tag == 0) {
            continue; // Code can return button with 00 tag
        }
        
        // Case 1. Allday event is going to select two days instead of one
        if (allDay) {
            BSCalendarViewDateButton *interimDateButton = (BSCalendarViewDateButton*)[panel viewWithTag:eventStartDateButton.tag];
            NSDateComponents *components = [calendar components:NSCalendarUnitMonth fromDate:interimDateButton.date];
            if (components.month == panel.panelDateComponents.month) [interimDateButton hasAnEvent];
            continue;
        }
        
        NSDateComponents *withoutAMinuteComponents = [[NSDateComponents alloc] init];
        withoutAMinuteComponents.minute = -1;
        NSDate *correctedEndDate = [calendar dateByAddingComponents:withoutAMinuteComponents toDate:endDate options:0];
        // If you have something up to midnight, standart calendar math will return +1 day duration of event, so we decrease duration by one minute
        NSInteger eventDuration = [calendar daysWithinEraFromDate:startDate toDate:correctedEndDate];
        
        // Case 2. Event is long. Check every button from start to end
        if (eventDuration > 0) {
            for (int i = 0; i <= eventDuration; i++) {
                if ((eventStartDateButton.tag + i + 1) < 53) {
                    BSCalendarViewDateButton *interimDateButton = (BSCalendarViewDateButton*)[panel viewWithTag:(eventStartDateButton.tag + i)];
                    // Show only for selected month
                    NSDateComponents *components = [calendar components:NSCalendarUnitMonth fromDate:eventStartDateButton.date];
                    if (components.month == panel.panelDateComponents.month) [interimDateButton hasAnEvent];
                }
            }
        }
        
        // Case 3. Common. One-day event
        else {
            // Show only for selected month
            NSDateComponents *components = [calendar components:NSCalendarUnitMonth fromDate:eventStartDateButton.date];
            if (components.month == panel.panelDateComponents.month) [eventStartDateButton hasAnEvent];
        }

        
    }
}

#pragma mark - Notification received
- (void)updateEventsNotificationReceived {
    // Get panels
    NSArray *panelsArray = [self allDaysPanels];
    // Send requests to update events arrays
    for (BSDaysPanel *panel in panelsArray) {
        if ([_calendarDelegate respondsToSelector:@selector(daysPanel:isReadyToSetEventsForFirstDate:andLastDate:)]) {
            BSCalendarViewDateButton *firstDateButton = (BSCalendarViewDateButton*)[panel viewWithTag:11];
            BSCalendarViewDateButton *lastDateButton = (BSCalendarViewDateButton*)[panel viewWithTag:52];
            [_calendarDelegate daysPanel:panel.tag isReadyToSetEventsForFirstDate:firstDateButton.date andLastDate:lastDateButton.date];
        }
    }
}

#pragma mark - Button Pressed 
- (void)daysPanel:(BSDaysPanel *)panel buttonPressed:(BSCalendarViewDateButton *)button manually:(BOOL)hasTapped {
    
    // 0. If tablet - no scrolling
    if (tabletVersion) {
        // deselect from all panels, don't save so much details
        for (UIView *view in _scrollView.subviews) {
            if ([view isKindOfClass:[BSDaysPanel class]]) {
                BSCalendarViewDateButton *previousButton = (BSCalendarViewDateButton*)[view viewWithTag:selectedButtonIndex];
                [UIView animateWithDuration:0.2 animations:^{
                    [previousButton deselectDateButton];
                }];
            }
        }
        // 3. Delegate methods
        if ([_calendarDelegate respondsToSelector:@selector(dateSelected:manually:)]) {
            [_calendarDelegate dateSelected:button.date manually:hasTapped];
        }
        // 4. Highlight selected button
        [button selectDateButton];
        // 5. Update tag
        selectedButtonIndex = button.tag;
        
        return;
    }
    
    // 1. Check if we need to scroll to another month
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitMonth fromDate:button.date];
    if (dateComponents.month != panel.panelDateComponents.month) {
        
        // 2. scroll to other month
        BOOL scrollForward = dateComponents.month > panel.panelDateComponents.month;
        if ((dateComponents.month == 1) && (panel.panelDateComponents.month == 12)) scrollForward = YES;
        if ((dateComponents.month == 12) && (panel.panelDateComponents.month == 1)) scrollForward = NO;
        
        NSInteger panelIndex = ((scrollForward)?panel.tag+1:panel.tag-1) - 100;
        CGPoint destinationPoint = CGPointMake((isVerticallyOriented)?0:(panelIndex * _scrollView.frame.size.width),(isVerticallyOriented)?(panelIndex * _scrollView.frame.size.height):0);
        [_scrollView setContentOffset:destinationPoint animated:YES];
        BSDaysPanel *destinationPanel = (BSDaysPanel*)[_scrollView viewWithTag:(panelIndex + 100)];
        [destinationPanel selectButtonWithDate:button.date];
    } else {
        // 2. Deselect previous button
        // deselect from all panels, don't save so much details
        for (UIView *view in _scrollView.subviews) {
            if ([view isKindOfClass:[BSDaysPanel class]]) {
                BSCalendarViewDateButton *previousButton = (BSCalendarViewDateButton*)[view viewWithTag:selectedButtonIndex];
                [UIView animateWithDuration:0.2 animations:^{
                    [previousButton deselectDateButton];
                }];
            }
        }
        
        // 3. Delegate methods
        if ([_calendarDelegate respondsToSelector:@selector(dateSelected:manually:)]) {
            [_calendarDelegate dateSelected:button.date manually:hasTapped];
        }
        
        // 4. Highlight selected button
        [button selectDateButton];
        
        // 5. Update tag
        selectedButtonIndex = button.tag;
    }
}

- (void)daysPanel:(BSDaysPanel *)panel buttonLongPressed:(BSCalendarViewDateButton *)button {
    /*
        With long press - at first open AddEvent view and then scroll to that date
     */
    
    if ([_calendarDelegate respondsToSelector:@selector(dateSelectedWithLongTap:)]) {
        [_calendarDelegate dateSelectedWithLongTap:button.date];
    }
    
    // Move
    [self daysPanel:panel buttonPressed:button manually:NO];
}

#pragma mark - Scroll View Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat verticalRatio = scrollView.contentOffset.y/scrollView.frame.size.height;
    CGFloat horizonralRatio = scrollView.contentOffset.x/scrollView.frame.size.width;
    NSInteger selectedIndex = (isVerticallyOriented)?round(verticalRatio):round(horizonralRatio);
    BSDaysPanel *panel = (BSDaysPanel*)[_scrollView viewWithTag:(selectedIndex + 100)];
    
    if (fmodf(((isVerticallyOriented)?verticalRatio:horizonralRatio), 1) == 0) {

        if (selectedIndex == 0) {
            [self addPanelOnTheLeftOrTop];
            
            if (isVerticallyOriented) {
                [scrollView setContentOffset:CGPointMake(0, scrollView.frame.size.height)];
            } else {
                [scrollView setContentOffset:CGPointMake(scrollView.frame.size.width, 0)];
            }
        }
        if (selectedIndex == (_numberOfPanels - 1)) {
            [self addPanelOnTheRightOrBottom];
            
            if (isVerticallyOriented) {
                [scrollView setContentOffset:CGPointMake(0, (selectedIndex - 1) * scrollView.frame.size.height)];
            } else {
                [scrollView setContentOffset:CGPointMake((selectedIndex - 1) * scrollView.frame.size.width, 0)];
            }
        }
    }
    
    if ([_calendarDelegate respondsToSelector:@selector(userScrolledToMonth:)]) {
        [_calendarDelegate userScrolledToMonth:panel.panelDateComponents.month];
    }
}

#pragma mark - Add panels on scroll view
- (void)addPanelOnTheLeftOrTop {
    /*
     * Logic:
     * 1. Add panel on left/top
     * 2. Configure dates
     * 3. Move all panels right/down
     * 4. Delete first
     */
    
    // Get panels
    NSArray *allDaysPanels = [self allDaysPanels];
    
    // Create panel
    BSDaysPanel *daysPanel = [[BSDaysPanel alloc] initWithFrame:CGRectMake(0, 0, _scrollView.bounds.size.width, _scrollView.bounds.size.height)];
    daysPanel.buttonDelegate = self;
    // Define components for that panel
    NSDateComponents *firstPanelComponents = [(BSDaysPanel*)allDaysPanels[0] panelDateComponents];
    if (firstPanelComponents.month == 1) {
        daysPanel.panelDateComponents.month = 12;
        daysPanel.panelDateComponents.year = firstPanelComponents.year - 1;
    } else {
        daysPanel.panelDateComponents.month = firstPanelComponents.month - 1;
        daysPanel.panelDateComponents.year = firstPanelComponents.year;
    }
    [daysPanel setTag:99];
    [_scrollView addSubview:daysPanel];
    
    // Set dates on created panel
    [self configureDatesOnDaysPanel:daysPanel startWithWeek:[self weekOfYearForFirstDayOfMonth:daysPanel.panelDateComponents] requestForEvents:NO];
    
    NSArray *reversed = [[allDaysPanels reverseObjectEnumerator] allObjects];
    BSDaysPanel *panelToDelete = (BSDaysPanel*)[reversed objectAtIndex:0];
    CGRect destinationFrame = panelToDelete.frame;
    for (int index = 1; index < reversed.count; index++) {
        BSDaysPanel *nextPanel = [reversed objectAtIndex:index];
        CGRect saveFrame = nextPanel.frame;
        [nextPanel setFrame:destinationFrame];
        destinationFrame = saveFrame;
    }
    [panelToDelete removeFromSuperview];
    
    // Edit indexes
    allDaysPanels = [self allDaysPanels];
    NSInteger index = 100;
    for (BSDaysPanel *panel in allDaysPanels) {
        panel.tag = index;
        index++;
    }
    
    if ([_calendarDelegate respondsToSelector:@selector(daysPanel:isReadyToSetEventsForFirstDate:andLastDate:)]) {
        BSCalendarViewDateButton *firstDateButton = (BSCalendarViewDateButton*)[daysPanel viewWithTag:11];
        BSCalendarViewDateButton *lastDateButton = (BSCalendarViewDateButton*)[daysPanel viewWithTag:52];
        [_calendarDelegate daysPanel:daysPanel.tag isReadyToSetEventsForFirstDate:firstDateButton.date andLastDate:lastDateButton.date];
    }
}

- (void)addPanelOnTheRightOrBottom {
    /*
     * Logic:
     * 1. Add panel on right/bottom
     * 2. Configure dates
     * 3. Move all panels left/up
     * 4. Delete first
     */
    
    // Get panels
    NSArray *allDaysPanels = [self allDaysPanels];
    
    // Create panel
    CGFloat originX = (isVerticallyOriented)?0.0f:(_scrollView.contentSize.width - _scrollView.bounds.size.width);
    CGFloat originY = (isVerticallyOriented)?(_scrollView.contentSize.height - _scrollView.bounds.size.height):0.0f;
    BSDaysPanel *daysPanel = [[BSDaysPanel alloc] initWithFrame:CGRectMake(originX, originY, _scrollView.bounds.size.width, _scrollView.bounds.size.height)];
    daysPanel.buttonDelegate = self;
    // Define components for that panel
    NSDateComponents *lastPanelComponents = [(BSDaysPanel*)allDaysPanels.lastObject panelDateComponents];
    if (lastPanelComponents.month == 12) {
        daysPanel.panelDateComponents.month = 1;
        daysPanel.panelDateComponents.year = lastPanelComponents.year + 1;
    } else {
        daysPanel.panelDateComponents.month = lastPanelComponents.month + 1;
        daysPanel.panelDateComponents.year = lastPanelComponents.year;
    }
    [daysPanel setTag:299];
    [_scrollView addSubview:daysPanel];
    
    // Set dates on created panel
    [self configureDatesOnDaysPanel:daysPanel startWithWeek:[self weekOfYearForFirstDayOfMonth:daysPanel.panelDateComponents] requestForEvents:NO];
    
    BSDaysPanel *panelToDelete = (BSDaysPanel*)[allDaysPanels objectAtIndex:0];
    CGRect destinationFrame = panelToDelete.frame;
    for (int index = 1; index < allDaysPanels.count; index++) {
        BSDaysPanel *nextPanel = [allDaysPanels objectAtIndex:index];
        CGRect saveFrame = nextPanel.frame;
        [nextPanel setFrame:destinationFrame];
        destinationFrame = saveFrame;
    }
    [panelToDelete removeFromSuperview];
    
    // Edit indexes
    allDaysPanels = [self allDaysPanels];
    NSInteger index = 100;
    for (BSDaysPanel *panel in allDaysPanels) {
        panel.tag = index;
        index++;
    }
    
    // Request for events
    if ([_calendarDelegate respondsToSelector:@selector(daysPanel:isReadyToSetEventsForFirstDate:andLastDate:)]) {
        BSCalendarViewDateButton *firstDateButton = (BSCalendarViewDateButton*)[daysPanel viewWithTag:11];
        BSCalendarViewDateButton *lastDateButton = (BSCalendarViewDateButton*)[daysPanel viewWithTag:52];
        [_calendarDelegate daysPanel:daysPanel.tag isReadyToSetEventsForFirstDate:firstDateButton.date andLastDate:lastDateButton.date];
    }
}

- (NSArray*)allDaysPanels {
    NSMutableArray *allDaysPanels = [NSMutableArray array];
    for (UIView *view in _scrollView.subviews) {
        if ([view isKindOfClass:[BSDaysPanel class]]) {
            [allDaysPanels addObject:view];
        }
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"tag" ascending:YES];
    return [allDaysPanels sortedArrayUsingDescriptors:@[sortDescriptor]];
}

#pragma mark - Calendar Math

- (NSInteger)weekOfYearForFirstDayOfMonth:(NSDateComponents*)dateComponents {
    dateComponents.day = 1;
    
    NSDate *firstDayOfChoosedMonthDate = [calendar dateFromComponents:dateComponents];
    // Define the week for this date
    NSDateComponents *weekForFirstDayOfMonthComponents = [calendar components:(NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday) fromDate:firstDayOfChoosedMonthDate];
    
    NSInteger valueToReturn = weekForFirstDayOfMonthComponents.weekOfYear;
    return valueToReturn;
}
@end
