//
//  SettingsViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "SettingsViewController.h"

// CONTROLLER: Calendars
#import "CalendarsListViewController.h"

// CONTROLLER: Google sign in
#import "GoogleSignInViewController.h"

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate>
{
    UITableView *settingsTableView;
}
@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    settingsTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    settingsTableView.dataSource = self;
    settingsTableView.delegate = self;
    [self.view addSubview:settingsTableView];
    
    // Buttons
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeViewController)];
    self.navigationItem.leftBarButtonItem = closeButton;
}

#pragma mark - VC Management
- (void)closeViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Preffered calendars";
    }
    
    else {
        return @"Google";
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"SettingsCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell...
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Configure";
    }
    
    else {
        cell.textLabel.text = @"Configure account";
    }
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        CalendarsListViewController *calendarsViewController = [[CalendarsListViewController alloc] init];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:calendarsViewController];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
    
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        GoogleSignInViewController *googleSignInController = (GoogleSignInViewController*)[storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([GoogleSignInViewController class])];
        [self.navigationController pushViewController:googleSignInController animated:YES];
    }
}
@end
