//
//  TabletMainViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "TabletMainViewController.h"

// Year view
#import "TabletYearViewController.h"
// Week view
#import "TabletWeekViewController.h"
// Settings
#import "SettingsViewController.h"

typedef enum {
    TabletMainViewOptionWeekPanel,
    TabletMainViewOptionYearPanel
} TabletMainViewOption;

@interface TabletMainViewController ()
{
    UIView *navigationContainer;
    UIImageView *weekView;
    UIImageView *yearView;
    UIImageView *settingsView;
    //
    UIView *contentView;
    //
    TabletYearViewController *yearViewController;
    TabletWeekViewController *weekViewController;
    //
    TabletMainViewOption selectedOption;
}
@end

@implementation TabletMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Navigation
    navigationContainer = [[UIView alloc] init];
    navigationContainer.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    [self view_addNavigationButtonsOnPanel];
    [self.view addSubview:navigationContainer];
    // Content
    contentView = [[UIView alloc] init];
    [self.view addSubview:contentView];
    // Year view
    yearViewController = [[TabletYearViewController alloc] init];
    // Week view
    weekViewController = [[TabletWeekViewController alloc] init];
    
    // Initially - year
    [self nav_userSelectedWeekPanel];
}

- (void)view_addNavigationButtonsOnPanel {
    weekView = [[UIImageView alloc] init];
    UITapGestureRecognizer *tapWeek = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nav_userSelectedWeekPanel)];
    [weekView addGestureRecognizer:tapWeek];
    weekView.contentMode = UIViewContentModeScaleToFill;
    weekView.backgroundColor = [UIColor clearColor];
    weekView.userInteractionEnabled = YES;
    [navigationContainer addSubview:weekView];
    //
    yearView = [[UIImageView alloc] init];
    UITapGestureRecognizer *tapYear = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nav_userSelectedYearPanel)];
    [yearView addGestureRecognizer:tapYear];
    yearView.contentMode = UIViewContentModeScaleToFill;
    yearView.backgroundColor = [UIColor clearColor];
    yearView.userInteractionEnabled = YES;
    [navigationContainer addSubview:yearView];
    //
    settingsView = [[UIImageView alloc] init];
    UITapGestureRecognizer *tapSettings = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nav_userSelectedSettings)];
    settingsView.contentMode = UIViewContentModeScaleToFill;
    [settingsView addGestureRecognizer:tapSettings];
    settingsView.backgroundColor = [UIColor clearColor];
    settingsView.userInteractionEnabled = YES;
    [navigationContainer addSubview:settingsView];
}

- (void)viewWillLayoutSubviews {
    CGRect viewRect = self.view.bounds;
    CGFloat navPanelSize = 100.0f;
    //
    CGRect navigationRect = CGRectMake(0, 0, navPanelSize, CGRectGetHeight(viewRect));
    navigationContainer.frame = navigationRect;
    navigationContainer.layer.masksToBounds = YES;
    CGFloat gap = 20.0f;
    CGRect weekNavRect = CGRectMake(gap, 20 + gap, CGRectGetWidth(navigationRect) - 2*gap, CGRectGetWidth(navigationRect) - 2 * gap);
    weekView.frame = weekNavRect;
    weekView.image = [UIImage imageNamed:@"week_black.png"];
    CGRect yearNavRect = CGRectMake(gap, CGRectGetMaxY(weekNavRect) + gap, CGRectGetWidth(weekNavRect), CGRectGetHeight(weekNavRect));
    yearView.frame = yearNavRect;
    yearView.image = [UIImage imageNamed:@"year_black.png"];
    CGRect settingsNavRect = CGRectMake(gap, CGRectGetMaxY(viewRect) - gap - CGRectGetHeight(weekNavRect), CGRectGetWidth(weekNavRect), CGRectGetHeight(weekNavRect));
    settingsView.frame = settingsNavRect;
    settingsView.image = [UIImage imageNamed:@"settings_black.png"];
    //
    CGRect contentRect = CGRectMake(CGRectGetMaxX(navigationRect), 0, CGRectGetWidth(viewRect) - CGRectGetWidth(navigationRect), CGRectGetHeight(viewRect));
    contentView.frame = contentRect;
    contentView.layer.masksToBounds = YES;
    //
}

- (void)nav_userSelectedWeekPanel {
    selectedOption = TabletMainViewOptionWeekPanel;
    //
    for (UIView *view in [NSArray arrayWithArray:[contentView subviews]]) {
        [view removeFromSuperview];
    }
    
    //
    weekViewController.view.frame = contentView.bounds;
    [contentView addSubview:weekViewController.view];
    [weekViewController didMoveToParentViewController:self];
    
    [self addChildViewController:weekViewController];
}

- (void)nav_userSelectedYearPanel {
    selectedOption = TabletMainViewOptionYearPanel;
    //
    for (UIView *view in [NSArray arrayWithArray:[contentView subviews]]) {
        [view removeFromSuperview];
    }
    //
    yearViewController.view.frame = contentView.bounds;
    [contentView addSubview:yearViewController.view];
    [yearViewController didMoveToParentViewController:self];
    [yearViewController removeFromParentViewController];
    [self addChildViewController:yearViewController];
}

- (void)nav_userSelectedSettings {
    SettingsViewController *settingsController = [[SettingsViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}
@end
