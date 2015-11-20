//
//  ContactSvcArchive.m
//  ContactMgr2
//
//  Created by Josh Gray on 6/5/14.
//  Copyright (c) 2014 msse650. All rights reserved.
//

#import "ContactSvcArchive.h"

@implementation ContactSvcArchive

NSString *filePath;

NSMutableArray *contacts;

- (id) init {
    //NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *docsDir = [dirPaths objectAtIndex:0];
    filePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: @"Contacts.archive"] ];
    NSLog(@"init: log path is %@", filePath);
    [self readArchive];
    return self;
}

- (void) readArchive {
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    
    
    if ([filemgr fileExistsAtPath: filePath])
    {
        contacts = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        NSLog(@"ContactSvcArchive.readArchive - file exists");
    }
    else
    {
        contacts = [NSMutableArray array];
        NSLog(@"ContactSvcArchive.readArchive - file does not exists");
    }
}

- (void) writeArchive {
    [NSKeyedArchiver archiveRootObject: contacts toFile:filePath];
    NSLog(@"ContactSvcArchive.writeArchive - wrote archive");
    
}


- (Contact *) createContact: (Contact *) contact {
    NSLog(@"ContactSvcArchive.createContact: %@", [contact description]);
    [contacts addObject:contact];
    //[self writeArchive];
    [NSKeyedArchiver archiveRootObject: contacts toFile:filePath];
    return contact;
}

- (NSMutableArray *) retrieveAllContacts {
    
    return contacts;
}

- (Contact *) updateContact: (Contact *) contact {
    return contact;
}



- (Contact *) deleteContact: (Contact *) contact {
    [contacts removeObject: contact]; //JKG
    [NSKeyedArchiver archiveRootObject: contacts toFile:filePath];
    return contact;
}

@end
