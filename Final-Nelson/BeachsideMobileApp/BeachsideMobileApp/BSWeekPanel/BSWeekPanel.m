//
//  BSWeekPanel.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//


#import "BSWeekPanel.h"

// Event Kit for working with events
#import <EventKit/EventKit.h>

// Google Calendar API
#import "GTLCalendarEvent+Calendar_Property.h" // includes gtlcalendar.h

#pragma mark - NSCalendar Category
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

#pragma mark - Event View
@interface BSEventView : UIView
@property (nonatomic) id event;
- (id)initWithFrame:(CGRect)frame andEvent:(EKEvent*)event;
@end

@implementation BSEventView
- (id)initWithFrame:(CGRect)frame andEvent:(id)event{
    self = [super initWithFrame:frame];
    if (self) {
        // Just a bit of design
        // Corners
        //self.layer.cornerRadius = 5.0;
        
        // Color and border
        [self setEvent:event];
        
        CGColorRef color;
        NSString *title;
        if ([event isKindOfClass:[EKEvent class]]) {
            EKEvent *sub = event;
            color = sub.calendar.CGColor;
            title = sub.title;
        } else {
            GTLCalendarEvent *sub = event;
            color = [UIColor colorWithWhite:0.8 alpha:0.7].CGColor; // Because it's a real damn task to parse google calendar color set
            title = sub.summary;
        }
        
        // Main color
        UIColor *calendarColor = [UIColor colorWithCGColor:color];
        CGFloat hue;
        CGFloat saturation;
        CGFloat brightness;
        CGFloat alpha;
        if ([calendarColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
            calendarColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:0.5];
        }
        self.backgroundColor = calendarColor;
        
        CGRect bounds = self.bounds;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(3, 1)];
        [path addLineToPoint:CGPointMake(3, CGRectGetMaxY(bounds) - 1)];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [path CGPath];
        shapeLayer.strokeColor = [calendarColor CGColor];
        shapeLayer.lineWidth = 3.0;
        shapeLayer.fillColor = [calendarColor CGColor];
        [self.layer addSublayer:shapeLayer];
        
        // Title
        CATextLayer *titleLayer = [CATextLayer layer];
        titleLayer.frame = CGRectMake(1, 1, frame.size.width - 4, frame.size.height - 4);
        titleLayer.foregroundColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
        titleLayer.alignmentMode = kCAAlignmentCenter;
        CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"ArialRoundedMTBold");
        titleLayer.font = font;
        titleLayer.wrapped = YES;
        titleLayer.fontSize = 10;
        titleLayer.string = title;
        [titleLayer setContentsScale:[[UIScreen mainScreen] scale]];
        CFRelease(font);
        [self.layer addSublayer:titleLayer];
    }
    return self;
}
@end

#pragma mark - Week Chooser Element
@interface BSWeekChooserElement : UIView
@property (nonatomic) UILabel *label;
@property (nonatomic, copy) NSDate *monday;
@property (nonatomic, copy) NSDate *sunday;
- (void)configureLabel;
@end

@implementation BSWeekChooserElement
- (void)configureLabel {
    [_label removeFromSuperview];
    [self setLabel:nil];
    
    _label = [[UILabel alloc] initWithFrame:self.bounds];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"d"];
    _label.font = [UIFont fontWithName:@"AmericanTypewriter-Condensed" size:15.0f];
    _label.text = [NSString stringWithFormat:@"%@ - %@",[dateFormatter stringFromDate:_monday],[dateFormatter stringFromDate:_sunday]];
    _label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_label];
    
    self.layer.cornerRadius = 3.0f;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 1.0f;
}
@end

#pragma mark - Custom Week Panel
@interface BSWeekPanel () <UIScrollViewDelegate>
{
    UIScrollView *_timeStampScrollView;
    UIScrollView *_weekStampScrollView;
    UIScrollView *_contentScrollView;
    UIView *_weekChooserView;
    
    NSMutableArray *eventsViewsArray;
    NSArray *weekEventsArray;
    
    NSDate *monday;
    NSDate *sunday;
    
    CGFloat oneWeekDayWidth;
    CGFloat originalYForStartDay;
    
    NSCalendar *calendar;
    
    BOOL layoutFlag;
    BOOL parseWeekFromSelectedDay;
}
@end

@implementation BSWeekPanel

/******* View Parameters */
CGFloat const kALWeekPanelWeekStampSizeHeight      = 60.0f;
CGFloat const kALWeekPanelWeekChooserSizeHeight    = 30.0f;
CGFloat const kALWeekPanelWeekChooserElementGap    = 15.0f;
CGFloat const kALWeekPanelWeekChooserElementHeight = 20.0f;
CGFloat const kALWeekPanelTimeStampSizeWidth       = 50.0f;
CGFloat const kALWeekPanelTimeStampLabelHeight     = 10.0f;
CGFloat const kALWeekPanelTimeStampGapSize         = 30.0f;
CGFloat const kALWeekPanelTimeStampAllDaySize      = 30.0f;
/******* END */

// Notification key
static NSString * const kALCalendarUpdateEventsNotification = @"kALCalendarUpdateEvents";

- (id)init {
    if ((self = [super init])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        // Init subviews
        [self commonInit];
        // Set frames
        
        /* Time Stamp Scroll */
        CGRect timeStampRect = CGRectMake(0,
                                          kALWeekPanelWeekStampSizeHeight,
                                          kALWeekPanelTimeStampSizeWidth,
                                          frame.size.height - kALWeekPanelWeekStampSizeHeight - kALWeekPanelWeekChooserSizeHeight);
        _timeStampScrollView.frame = timeStampRect;
        _timeStampScrollView.contentSize = CGSizeMake(0, (kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampGapSize) * 24 + kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampAllDaySize);
        
        /* Week Stamp Scroll */
        CGRect weekStampRect = CGRectMake(CGRectGetMaxX(timeStampRect),
                                          0,
                                          frame.size.width - CGRectGetMaxX(timeStampRect),
                                          kALWeekPanelWeekStampSizeHeight);
        _weekStampScrollView.frame = weekStampRect;
        _weekStampScrollView.contentSize = CGSizeMake((weekStampRect.size.width/5)*7, 0);

        
        /* Content Scroll */
        CGRect contentRect = CGRectMake(CGRectGetMaxX(timeStampRect),
                                        CGRectGetMaxY(weekStampRect),
                                        CGRectGetWidth(weekStampRect),
                                        CGRectGetHeight(timeStampRect));
        _contentScrollView.frame = contentRect;
        _contentScrollView.contentSize = CGSizeMake(_weekStampScrollView.contentSize.width, _timeStampScrollView.contentSize.height);

        
        /* Week Chooser View */
        CGRect weekChooserRect = CGRectMake(CGRectGetMinX(timeStampRect),
                                            CGRectGetMaxY(timeStampRect),
                                            frame.size.width,
                                            kALWeekPanelWeekChooserSizeHeight);
        _weekChooserView.frame = weekChooserRect;
    }
    return self;
}

- (void)commonInit {
    /* Initialize subviews */
    self.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.96 alpha:1.0];
    
    /* Set calendar properties */
    calendar = [NSCalendar currentCalendar];
    [calendar setLocale:[NSLocale currentLocale]];
    [calendar setFirstWeekday:2];
    
    /* Parameters */
    originalYForStartDay = kALWeekPanelTimeStampAllDaySize;
    
    /* Time Stamp Scroll */
    _timeStampScrollView = [[UIScrollView alloc] init];
    _timeStampScrollView.showsVerticalScrollIndicator = YES;
    _timeStampScrollView.backgroundColor = [UIColor clearColor];
    _timeStampScrollView.showsVerticalScrollIndicator = NO;
    _timeStampScrollView.userInteractionEnabled = NO;
    [self addSubview:_timeStampScrollView];
    
    /* Week Stamp Scroll */
    _weekStampScrollView = [[UIScrollView alloc] init];
    _weekStampScrollView.showsHorizontalScrollIndicator = YES;
    _weekStampScrollView.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.96 alpha:1.0];
    _weekStampScrollView.delegate = self;
    [self addSubview:_weekStampScrollView];
    
    /* Content Scroll */
    _contentScrollView = [[UIScrollView alloc] init];
    _contentScrollView.showsHorizontalScrollIndicator = YES;
    _contentScrollView.showsVerticalScrollIndicator = YES;
    _contentScrollView.directionalLockEnabled = YES;
    _contentScrollView.backgroundColor = [UIColor whiteColor];
    _contentScrollView.delegate = self;
    [self addSubview:_contentScrollView];
    
    /* Week Chooser View */
    _weekChooserView = [[UIView alloc] init];
    _weekChooserView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_weekChooserView];
    
    // Init array for event views
    eventsViewsArray = [NSMutableArray array];
    
    /* Register for notifications */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refetch)
                                                 name:kALCalendarUpdateEventsNotification object:nil];
}

- (void)view_setFrames {
    CGRect viewRect = self.bounds;
    CGRect timeStampRect = CGRectMake(0,
                                      kALWeekPanelWeekStampSizeHeight,
                                      kALWeekPanelTimeStampSizeWidth,
                                      viewRect.size.height - kALWeekPanelWeekStampSizeHeight - kALWeekPanelWeekChooserSizeHeight);
    _timeStampScrollView.frame = timeStampRect;
    _timeStampScrollView.contentSize = CGSizeMake(0, (kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampGapSize) * 24 + kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampAllDaySize);
    //
    CGRect weekStampRect = CGRectMake(CGRectGetMaxX(timeStampRect),
                                      0,
                                      viewRect.size.width - CGRectGetMaxX(timeStampRect),
                                      kALWeekPanelWeekStampSizeHeight);
    _weekStampScrollView.frame = weekStampRect;
    _weekStampScrollView.contentSize = CGSizeMake((weekStampRect.size.width/5)*7, 0);
    //
    CGRect contentRect = CGRectMake(CGRectGetMaxX(timeStampRect),
                                    CGRectGetMaxY(weekStampRect),
                                    CGRectGetWidth(weekStampRect),
                                    CGRectGetHeight(timeStampRect));
    _contentScrollView.frame = contentRect;
    _contentScrollView.contentSize = CGSizeMake(_weekStampScrollView.contentSize.width, _timeStampScrollView.contentSize.height);
    //
    CGRect weekChooserRect = CGRectMake(CGRectGetMinX(timeStampRect),
                                        CGRectGetMaxY(timeStampRect),
                                        viewRect.size.width,
                                        kALWeekPanelWeekChooserSizeHeight);
    _weekChooserView.frame = weekChooserRect;
    // Placing time stamps
    [self view_oncePlaceTimeStamps];
    // Draw lines
    [self view_oncePlaceLinesOnContentScrollView];
}

#pragma mark - Placing content
- (void)layoutSubviews {
    if (!layoutFlag) return;
    
    // update frames
    [self view_setFrames];
    
    // Place labels
    [self view_placeLabelsOnWeekStampsWithStartDate:(parseWeekFromSelectedDay)?[self math_mondayOfTheWeekWithSelectedDay]:monday];
    
    // Update week chooser labels
    [self view_defineWeekChooserElements];
    
    layoutFlag = !layoutFlag;
}

#pragma mark -
- (void)view_oncePlaceTimeStamps {
    for (UILabel *label in [NSArray arrayWithArray:[_timeStampScrollView subviews]]) {
        [label removeFromSuperview];
    }
    
    NSArray *timeStampsLabels = @[@"00",@"01",@"02",@"03",@"04",@"05",@"06",@"07",@"08",@"09",@"10",@"11",@"12",@"13",@"14",@"15",@"16",@"17",@"18",@"19",@"20",@"21",@"22",@"23",@"00"];
    [timeStampsLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        NSString *labelText = obj;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, idx * (kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampGapSize) + (kALWeekPanelTimeStampAllDaySize - 0.5 * kALWeekPanelTimeStampLabelHeight), kALWeekPanelTimeStampSizeWidth, kALWeekPanelTimeStampLabelHeight)];
        label.text = [NSString stringWithFormat:@"%@:00",labelText];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:10.0f];
        label.textColor = [UIColor blackColor];
        [_timeStampScrollView addSubview:label];
    }];
}

- (void)view_oncePlaceLinesOnContentScrollView {
    oneWeekDayWidth = _weekStampScrollView.frame.size.width / 5;
    
    for (int index = 0; index < 25; index++) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(-1000,
                                      index * (kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampGapSize) + kALWeekPanelTimeStampAllDaySize)];
        [path addLineToPoint:CGPointMake(_contentScrollView.contentSize.width,
                                         index * (kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampGapSize) + kALWeekPanelTimeStampAllDaySize)];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [path CGPath];
        shapeLayer.strokeColor = [[UIColor colorWithHue:0.0 saturation:0.0 brightness:0.89 alpha:1.0] CGColor];
        shapeLayer.lineWidth = 0.5;
        shapeLayer.fillColor = [[UIColor clearColor] CGColor];
        [_contentScrollView.layer addSublayer:shapeLayer];
    }
    
    for (int index = 0; index < 8; index++) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(index * oneWeekDayWidth, -1000)];
        [path addLineToPoint:CGPointMake(index * oneWeekDayWidth, _contentScrollView.contentSize.height)];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [path CGPath];
        shapeLayer.strokeColor = [[UIColor colorWithHue:0.0 saturation:0.0 brightness:0.89 alpha:1.0] CGColor];
        shapeLayer.lineWidth = 0.5;
        shapeLayer.fillColor = [[UIColor clearColor] CGColor];
        [_contentScrollView.layer addSublayer:shapeLayer];
        
        UIBezierPath *weekPath = [UIBezierPath bezierPath];
        [weekPath moveToPoint:CGPointMake(index * oneWeekDayWidth, -1000)];
        [weekPath addLineToPoint:CGPointMake(index * oneWeekDayWidth, kALWeekPanelWeekStampSizeHeight)];
        CAShapeLayer *weekShapeLayer = [CAShapeLayer layer];
        weekShapeLayer.path = [weekPath CGPath];
        weekShapeLayer.strokeColor = [[UIColor colorWithHue:0.0 saturation:0.0 brightness:0.89 alpha:1.0] CGColor];
        weekShapeLayer.lineWidth = 0.5;
        weekShapeLayer.fillColor = [[UIColor clearColor] CGColor];
        [_weekStampScrollView.layer addSublayer:weekShapeLayer];
    }
}

#pragma mark -
- (void)view_placeLabelsOnWeekStampsWithStartDate:(NSDate*)startDate {

    // Clean the playground
    [self view_removeAllTextLayersFromWeekStamp];
    
    // Get CURRENT day components
    NSDateComponents *currentDayDateComponents = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:[NSDate date]];
    
    NSDate *day = startDate;
    for (int index = 0; index < 7; index++) {
        // Place text
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"d"];
        NSString *dayString = [dateFormatter stringFromDate:day];
        [dateFormatter setDateFormat:@"LLLL"];
        NSString *monthString = [dateFormatter stringFromDate:day];
        
        CATextLayer *monthTextLayer = [CATextLayer layer];
        monthTextLayer.frame = CGRectMake(index * oneWeekDayWidth, (kALWeekPanelWeekStampSizeHeight / 3)*2, oneWeekDayWidth, (kALWeekPanelWeekStampSizeHeight / 3));
        monthTextLayer.backgroundColor = [UIColor clearColor].CGColor;
        monthTextLayer.foregroundColor = [UIColor blackColor].CGColor;
        monthTextLayer.fontSize = 13;
        monthTextLayer.alignmentMode = @"center";
        monthTextLayer.string = monthString;
        monthTextLayer.contentsScale = [[UIScreen mainScreen] scale];
        [_weekStampScrollView.layer addSublayer:monthTextLayer];
        CATextLayer *dayTextLayer = [CATextLayer layer];
        dayTextLayer.frame = CGRectMake(index * oneWeekDayWidth, 15, oneWeekDayWidth, (kALWeekPanelWeekStampSizeHeight / 3)*2);
        dayTextLayer.backgroundColor = [UIColor clearColor].CGColor;
        dayTextLayer.foregroundColor = [UIColor blackColor].CGColor;
        dayTextLayer.fontSize = 22;
        dayTextLayer.alignmentMode = @"center";
        dayTextLayer.string = dayString;
        dayTextLayer.contentsScale = [[UIScreen mainScreen] scale];
        [_weekStampScrollView.layer addSublayer:dayTextLayer];
        
        // Weekend
        if (index > 4) {
            monthTextLayer.foregroundColor = [UIColor lightGrayColor].CGColor;
            dayTextLayer.foregroundColor = [UIColor lightGrayColor].CGColor;
        }
        
        // Selected day
        NSDateComponents *interimDayDateComponents = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:day];
        if ((currentDayDateComponents.day == interimDayDateComponents.day) &&
            (currentDayDateComponents.month == interimDayDateComponents.month) &&
            (currentDayDateComponents.month == interimDayDateComponents.month)) {
            monthTextLayer.foregroundColor = [UIColor redColor].CGColor;
            dayTextLayer.foregroundColor = [UIColor redColor].CGColor;
        }
        
        // Iterate
        NSDateComponents *nextDayComponents = [[NSDateComponents alloc] init];
        nextDayComponents.day = (index == 6)?0:1;
        day = [calendar dateByAddingComponents:nextDayComponents toDate:day options:0];
    }
    
    monday = startDate;
    sunday = day;
    if ([_weekPanelDelegate respondsToSelector:@selector(weekPanelIsReadyToSetEventsForFirstDay:andLastDate:)]) {
        [_weekPanelDelegate weekPanelIsReadyToSetEventsForFirstDay:startDate andLastDate:day];
    }
}

- (void)view_removeAllTextLayersFromWeekStamp {
    NSArray *sublayers = [_weekStampScrollView.layer sublayers];
    NSMutableArray *layersToDelete = [NSMutableArray array];
    for (CALayer *layer in sublayers) {
        if ([layer isKindOfClass:[CATextLayer class]]) {
            [layersToDelete addObject:layer];
        }
    }
    for (CATextLayer *layer in layersToDelete) {
        [layer removeFromSuperlayer];
    }
}

#pragma mark -
- (void)view_defineWeekChooserElements {
    // Delete previous
    NSArray *subviews = _weekChooserView.subviews;
    for (BSWeekChooserElement *element in subviews) {
        [element removeFromSuperview];
    }
    
    // Create new basing on current week settings
    CGFloat elementWidth = (CGRectGetWidth(self.bounds) - 8 * kALWeekPanelWeekChooserElementGap)/7;
    NSDateComponents *threeWeeksAgoComponents = [[NSDateComponents alloc] init];
    // threeWeeksAgoComponents.week = -3; // Method was deprecated
    threeWeeksAgoComponents.weekOfYear = -3;
    NSDateComponents *weekLaterComponents = [[NSDateComponents alloc] init];
    weekLaterComponents.weekOfYear = 1;
    NSDateComponents *sixDayLaterComponents = [[NSDateComponents alloc] init];
    sixDayLaterComponents.day = 6;
    NSDate *interimMonday = [calendar dateByAddingComponents:threeWeeksAgoComponents toDate:monday options:0];
    NSDate *interimSunday = [calendar dateByAddingComponents:sixDayLaterComponents toDate:interimMonday options:0];
    for (int index = 0; index < 7; index++) {
        CGRect elementFrame = CGRectMake(kALWeekPanelWeekChooserElementGap + index * (elementWidth + kALWeekPanelWeekChooserElementGap),
                                         (kALWeekPanelWeekChooserSizeHeight - kALWeekPanelWeekChooserElementHeight)/2,
                                         elementWidth,
                                         kALWeekPanelWeekChooserElementHeight);
        BSWeekChooserElement *element = [[BSWeekChooserElement alloc] initWithFrame:elementFrame];
        element.monday = interimMonday;
        element.sunday = interimSunday;
        [element configureLabel];
        if (index == 3) element.label.font = [UIFont fontWithName:@"AmericanTypewriter-CondensedBold" size:15.0f];
        [self view_addTapRecognizerOnWeekChooserElement:element];
        [_weekChooserView addSubview:element];
        
        interimMonday = [calendar dateByAddingComponents:weekLaterComponents toDate:interimMonday options:0];
        interimSunday = [calendar dateByAddingComponents:sixDayLaterComponents toDate:interimMonday options:0];
    }
}

- (void)view_addTapRecognizerOnWeekChooserElement:(BSWeekChooserElement*)element {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(weekChooserElementTapped:)];
    [element addGestureRecognizer:singleTap];
}

#pragma mark -
- (void)view_createAndPlaceEventsViewOnContentPanel {
    [self view_removeAllEventsViewsFromPanel];
    
    for (id object in weekEventsArray) {
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
        
        // Case 0. Event is out of bounds
        if (([endDate compare:monday] == NSOrderedAscending) || ([startDate compare:sunday] == NSOrderedDescending)) {
            continue;
        }
        
        NSInteger fromStartToEnd = [calendar daysWithinEraFromDate:startDate toDate:endDate];
        
        // Case 1. AllDay event
        if (allDay) {
            NSInteger originX = [self math_indexForDate:endDate];
            [self view_drawAllDayEventAtIndex:originX withEvent:object attachToTop:YES];
            continue;
        }
        
        // Case 2. Event is 'long'
        if (fromStartToEnd > 0) {
            if (([startDate compare:[self math_startOfDay:monday]] == NSOrderedAscending)) {
                // Event begins before the monday
                NSDate *interimStartDate = startDate;
                for (int index = 0; index < (fromStartToEnd + 1); index++) {
                    if (([interimStartDate compare:[self math_startOfDay:monday]] != NSOrderedAscending) && ([interimStartDate compare:[self math_endOfSunday]] != NSOrderedDescending)) {
                        // Get x
                        NSInteger originX = [self math_indexForDate:interimStartDate];
                        // Get y
                        CGFloat originY = originalYForStartDay;
                        // Get height
                        if (index != fromStartToEnd) {
                            [self view_drawAllDayEventAtIndex:originX withEvent:object attachToTop:NO];
                        } else {
                            // Calculate height
                            CGFloat height = [self math_distanceBetweenStartDate:[self math_startOfDay:interimStartDate] andEndDate:endDate];
                            BSEventView *eventView = [[BSEventView alloc] initWithFrame:CGRectMake(originX * oneWeekDayWidth + 1,
                                                                                                   originY + 1,
                                                                                                   oneWeekDayWidth - 2,
                                                                                                   height - 2) andEvent:object];
                            [self view_setTapRecognizerOnEventView:eventView];
                            [_contentScrollView addSubview:eventView];
                            [eventsViewsArray addObject:eventView];
                        }
                    }
                    
                    NSDateComponents *nextInterimDateComponents = [[NSDateComponents alloc] init];
                    nextInterimDateComponents.day = 1;
                    interimStartDate = [calendar dateByAddingComponents:nextInterimDateComponents toDate:interimStartDate options:0];
                }
            }
            
            else {
                NSDate *interimStartDate = startDate;
                for (int index = 0; index < (fromStartToEnd + 1); index++) {
                    if ([interimStartDate compare:[self math_endOfSunday]] != NSOrderedDescending) {
                        // Before sunday
                        // Get x
                        NSInteger originX = [self math_indexForDate:interimStartDate];
                        // Get y
                        CGFloat originY = (index == 0)?[self math_originYFromDate:startDate]:[self math_originYFromDate:[self math_startOfDay:interimStartDate]];
                        // Get height
                        if ((index != fromStartToEnd) && (index != 0)) {
                            [self view_drawAllDayEventAtIndex:originX withEvent:object attachToTop:NO];
                        } else {
                            // Calculate height
                            CGFloat height = (index == fromStartToEnd)?[self math_originYFromDate:endDate]:(24 * (kALWeekPanelTimeStampGapSize + kALWeekPanelTimeStampLabelHeight)) - originY;
                            BSEventView *eventView = [[BSEventView alloc] initWithFrame:CGRectMake(originX * oneWeekDayWidth + 1,
                                                                                                   originY + originalYForStartDay + 1,
                                                                                                   oneWeekDayWidth - 2,
                                                                                                   height - 2) andEvent:object];
                            [self view_setTapRecognizerOnEventView:eventView];
                            [_contentScrollView addSubview:eventView];
                            [eventsViewsArray addObject:eventView];
                        }
                    }
                    
                    NSDateComponents *nextInterimDateComponents = [[NSDateComponents alloc] init];
                    nextInterimDateComponents.day = 1;
                    interimStartDate = [calendar dateByAddingComponents:nextInterimDateComponents toDate:interimStartDate options:0];
                }
            }
        }
        
        // Case 3. One-day event
        else {
            // Get x
            NSInteger index = [self math_indexForDate:startDate];
            // Get y
            CGFloat originY = [self math_originYFromDate:startDate];
            // Get height
            CGFloat height = [self math_distanceBetweenStartDate:startDate andEndDate:endDate];
            
            BSEventView *eventView = [[BSEventView alloc] initWithFrame:CGRectMake(index * oneWeekDayWidth + 1,
                                                                                   originY + originalYForStartDay + 1,
                                                                                   oneWeekDayWidth - 2,
                                                                                   height - 2) andEvent:object];
            [self view_setTapRecognizerOnEventView:eventView];
            [_contentScrollView addSubview:eventView];
            [eventsViewsArray addObject:eventView];
        }
    }
    
    // Go through views and place smallest ones on top
    NSArray *sortedArray = [eventsViewsArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        BSEventView *eventViewA = (BSEventView*)a;
        CGFloat heightA = eventViewA.frame.size.height;
        BSEventView *eventViewB = (BSEventView*)b;
        CGFloat heightB = eventViewB.frame.size.height;
        
        return (heightA > heightB)?NSOrderedAscending:NSOrderedDescending;
    }];
    for (BSEventView *eventView in sortedArray) {
        [_contentScrollView bringSubviewToFront:eventView];
    }
}

- (void)view_removeAllEventsViewsFromPanel {
    for (BSEventView *eventView in eventsViewsArray) {
        [eventView removeFromSuperview];
    }
    [eventsViewsArray removeAllObjects];
}

- (void)view_drawAllDayEventAtIndex:(NSInteger)originX withEvent:(id)event attachToTop:(BOOL)attach {
    CGFloat originY = (attach)?0:originalYForStartDay;
    CGFloat height = (attach)?kALWeekPanelTimeStampAllDaySize:(24 * (kALWeekPanelTimeStampGapSize + kALWeekPanelTimeStampLabelHeight));
    BSEventView *eventView = [[BSEventView alloc] initWithFrame:CGRectMake(originX * oneWeekDayWidth + 1,
                                                                           originY + 1,
                                                                           oneWeekDayWidth - 2,
                                                                           height - 2) andEvent:event];
    [self view_setTapRecognizerOnEventView:eventView];
    [_contentScrollView addSubview:eventView];
    [eventsViewsArray addObject:eventView];
}

- (void)view_setTapRecognizerOnEventView:(BSEventView*)eventView {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(eventViewTapped:)];
    [eventView addGestureRecognizer:singleTap];
}

#pragma mark - User tapped on event view
- (void)eventViewTapped:(UITapGestureRecognizer*)gestureRecognizer {
    
    UIView *view = gestureRecognizer.view;
    CGPoint tapLocation = [gestureRecognizer locationInView:view];
    BSEventView *eventView = (BSEventView*)[view hitTest:tapLocation withEvent:nil];
    
    if ([_weekPanelDelegate respondsToSelector:@selector(weekPanelEventSelected:)]) {
        [_weekPanelDelegate weekPanelEventSelected:eventView.event];
    }
}

#pragma mark - User requested to load another week
- (void)weekChooserElementTapped:(UITapGestureRecognizer*)gestureRecognizer {
    
    UIView *view = gestureRecognizer.view;
    CGPoint tapLocation = [gestureRecognizer locationInView:view];
    BSWeekChooserElement *weekElement = (BSWeekChooserElement*)[view hitTest:tapLocation withEvent:nil];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"d LLLL"];
    
    layoutFlag = YES;
    parseWeekFromSelectedDay = NO;
    monday = weekElement.monday;
    sunday = weekElement.sunday;
    
    // Update
    if ([_weekPanelDelegate respondsToSelector:@selector(weekPanelIsReadyToSetEventsForFirstDay:andLastDate:)]) {
        [_weekPanelDelegate weekPanelIsReadyToSetEventsForFirstDay:monday andLastDate:sunday];
    }
    // Update ui
    [self setNeedsLayout];
}

#pragma mark - Calendar Math
- (NSInteger)math_indexForDate:(NSDate*)date {
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitWeekday fromDate:date];
    NSInteger index = (dateComponents.weekday == 1)?6:(dateComponents.weekday - 2);
    
    return index;
}

- (CGFloat)math_originYFromDate:(NSDate*)date {
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    CGFloat hourY = dateComponents.hour * (kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampGapSize);
    CGFloat restY = (dateComponents.minute / 60.0f) * (kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampGapSize);
    
    return hourY + restY;
}

- (CGFloat)math_distanceBetweenStartDate:(NSDate*)start andEndDate:(NSDate*)end {
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:start toDate:end options:0];
    CGFloat hours = dateComponents.hour * (kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampGapSize);
    CGFloat restY = (dateComponents.minute / 60.0f) * (kALWeekPanelTimeStampLabelHeight + kALWeekPanelTimeStampGapSize);
    
    return hours + restY;
}

- (NSDate*)math_startOfDay:(NSDate*)day {
    NSDateComponents *dayComponents = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:day];
    dayComponents.hour = 0;
    dayComponents.minute = 0;
    
    return [calendar dateFromComponents:dayComponents];
}

- (NSDate*)math_endOfSunday {
    NSDateComponents *sundayComponents = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:sunday];
    sundayComponents.hour = 23;
    sundayComponents.minute = 59;
    sundayComponents.second = 59;
    
    return [calendar dateFromComponents:sundayComponents];
}

- (NSDate*)math_mondayOfTheWeekWithSelectedDay {
    // Find Monday
    NSDateComponents *componentsFromSelectedDate = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitWeekday) fromDate:_selectedDayOfWeek];
    NSDate *firstDayOfWeek = _selectedDayOfWeek;
    if (componentsFromSelectedDate.weekday > 2) {
        NSInteger difference = componentsFromSelectedDate.weekday - 2;
        NSDateComponents *roadToMondayComponents = [[NSDateComponents alloc] init];
        roadToMondayComponents.day = -difference;
        firstDayOfWeek = [calendar dateByAddingComponents:roadToMondayComponents toDate:_selectedDayOfWeek options:0];
    } else if (componentsFromSelectedDate.weekday == 1){
        NSDateComponents *roadToMondayComponents = [[NSDateComponents alloc] init];
        roadToMondayComponents.day = -6;
        firstDayOfWeek = [calendar dateByAddingComponents:roadToMondayComponents toDate:_selectedDayOfWeek options:0];
    }
    
    return firstDayOfWeek;
}

#pragma mark - Updating
- (void)refetch {
    if (!monday || !sunday) return; // In case user didn't flip the phone and frame was not set
    
    if ([_weekPanelDelegate respondsToSelector:@selector(weekPanelIsReadyToSetEventsForFirstDay:andLastDate:)]) {
        [_weekPanelDelegate weekPanelIsReadyToSetEventsForFirstDay:monday andLastDate:sunday];
    }
}

#pragma mark - Setting events
- (void)setEventsArray:(NSArray*)eventsArray {
    weekEventsArray = eventsArray;
    
    [self view_createAndPlaceEventsViewOnContentPanel];
}

#pragma mark - Scroll View Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Sync scroll views
    if ([scrollView isEqual:_weekStampScrollView]) {
        [_contentScrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, _contentScrollView.contentOffset.y)];
    }
    
    else if ([scrollView isEqual:_contentScrollView]) {
        [_weekStampScrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, _weekStampScrollView.contentOffset.y)];
        [_timeStampScrollView setContentOffset:CGPointMake(_timeStampScrollView.contentOffset.x, scrollView.contentOffset.y)];
    }
}

#pragma mark - Custom setter for date property
- (void)setSelectedDayOfWeek:(NSDate *)selectedDayOfWeek {
    if (_selectedDayOfWeek) {
        // Don't mess with massive layoutSubviews calling! :)
        NSDateComponents *selected = [calendar components:NSCalendarUnitSecond fromDate:selectedDayOfWeek toDate:_selectedDayOfWeek options:0];
        if (selected.second < 2) return;
    }
    
    _selectedDayOfWeek = [selectedDayOfWeek copy];
    // Flags
    layoutFlag = YES;
    parseWeekFromSelectedDay = YES;
}
@end
