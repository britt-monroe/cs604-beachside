//
//  ContactSvc.h
//  ContactMgr2
//
//  Created by Josh Gray on 5/19/14.
//  Copyright (c) 2014 msse650. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Contact.h"

@protocol ContactSvc <NSObject>

- (Contact *) createContact: (Contact *) contact;
- (NSArray *) retrieveAllContacts;
- (Contact *) updateContact: (Contact *) contact;
- (Contact *) deleteContact: (Contact *) contact;
- (Contact *) createManagedContact;

@end
