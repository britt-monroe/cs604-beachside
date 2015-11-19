//
//  GoogleSignInViewController.h
//  BeachsideMobileApp
//
//  Created by Nelson Gonzalez (@Nelson-Cyberpig)
//  Copyright (c) 2015 Nel. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GPPSignInButton;

//#import <GoogleSignIn/GoogleSignIn.h>

@interface GoogleSignInViewController : UIViewController

@property (weak, nonatomic) IBOutlet GPPSignInButton *signInButton;
@property (weak, nonatomic) IBOutlet UITableView *googleInfoTableView;
@end
