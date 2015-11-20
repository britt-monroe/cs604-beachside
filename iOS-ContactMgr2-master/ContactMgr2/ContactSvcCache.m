//
//  ContactSvcCache.m
//  ContactMgr2
//
//  Created by Josh Gray on 5/19/14.
//  Copyright (c) 2014 msse650. All rights reserved.
//

#import "ContactSvcCache.h"

@implementation ContactSvcCache

NSMutableArray *contacts = nil;

- (id) init {
    if (self = [super init]) {
        contacts = [NSMutableArray array];
        return self;
    }
    return nil;
}

- (Contact *) createContact:(Contact *)contact {
    [contacts addObject: contact];
    return contact;
}

- (NSMutableArray *) retrieveAllContacts {
    return contacts;
}

- (Contact *) updateContact:(Contact *) contact {
    return contact;
}

- (Contact *) deleteContact:(Contact *) contact {
    [contacts removeObject: contact]; //JKG
    return contact;
}


@end
