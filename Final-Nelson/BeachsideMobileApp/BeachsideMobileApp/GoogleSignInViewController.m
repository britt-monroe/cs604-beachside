//
//  GoogleSignInViewController.m
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import "GoogleSignInViewController.h"

// VIEW: Google sign in button
#import "GooglePlusSDK/GPPSignInButton.h"

// Model: Authentication
#import "GooglePlus OpenSource/GTMOAuth2Authentication.h"

// Model: Sign In
#import "GooglePlusSDK/GPPSignIn.h"

// Model: Calendar
#import "BSCalendarModel.h"

@interface GoogleSignInViewController () <UITableViewDelegate, UITableViewDataSource, GPPSignInDelegate>
{
    NSDictionary *status;
}
@end

@implementation GoogleSignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [GPPSignInButton class];
    
    [self setUpBadStatus];
    
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.delegate = self;
    signIn.shouldFetchGoogleUserEmail = YES;
    [signIn setScopes:@[@"https://www.googleapis.com/auth/plus.login",
                        @"https://www.googleapis.com/auth/calendar"]];
    [signIn trySilentAuthentication];
}

#pragma mark - GPPSignInDelegate

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
    if (error) {
        [self setUpBadStatus];
        return;
    } else {
        [self reportAuthStatus];
    }
}

- (void)didDisconnectWithError:(NSError *)error {
    if (error) {
        [self setUpBadStatus];
        // handle error
    }
}

- (void)signOut {
    [[GPPSignIn sharedInstance] signOut];
}

- (void)reportAuthStatus {
    if ([GPPSignIn sharedInstance].authentication) {
        NSString *email = [GPPSignIn sharedInstance].authentication.userEmail;
        if (email) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            dictionary[@"Email"] = email;
            
            status = nil;
            status = [NSDictionary dictionaryWithDictionary:dictionary];
            
            [self.googleInfoTableView reloadData];
            
            [[BSCalendarModel sharedManager] setAuthorised:YES];
        }
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Check your Internet connection" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (void)setUpBadStatus {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"Email"] = @"Not authenticated";
    
    status = nil;
    status = [NSDictionary dictionaryWithDictionary:dictionary];
    
    [self.googleInfoTableView reloadData];
    
    [[BSCalendarModel sharedManager] setAuthorised:NO];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"GoogleInfoCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // Configure the cell...
    if (indexPath.section == 0) {
        cell.textLabel.text = status[@"Email"];
    }
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"User e-mail";
    }
    
    return @"";
}
@end
