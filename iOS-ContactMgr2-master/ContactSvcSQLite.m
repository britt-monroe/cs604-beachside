//
//  ContactSvcSQLite.m
//  ContactMgr2
//
//  Created by Josh Gray on 6/12/14.
//  Copyright (c) 2014 msse650. All rights reserved.
//

#import "ContactSvcSQLite.h"
#import <sqlite3.h>

@implementation ContactSvcSQLite
NSString *databasePath = nil;
sqlite3 *database = nil;

- (id)init {
    if ((self = [super init])) {
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDir = [documentPaths objectAtIndex:0];
        databasePath = [documentsDir stringByAppendingPathComponent:@"contact.sqlite3"];
        
        if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
            NSLog(@"database is open");
            NSLog(@"database file path: %@", databasePath);
            
            NSString *createSQL = @"create table if not exists contact (id integer primary key autoincrement, name varchar(30), phone varchar(12), email varchar(20))";
            
            char *errMsg;
            if (sqlite3_exec(database, [createSQL UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                NSLog(@"Failed to create table %s", errMsg);
            }
                
                             
        } else {
            NSLog(@"*** Failed to open database!");
            NSLog(@"*** SQL error: %s\n", sqlite3_errmsg(database));
        
        
        }
                                                                     
    }
    return self;
    
}

- (Contact *) createContact: (Contact *)contact {
    sqlite3_stmt *statement;
    NSString *insertSQL = [NSString stringWithFormat: @"INSERT INTO contact (name, phone, email) VALUES (\"%@\", \"%@\", \"%@\")", contact.name, contact.phone, contact.email];
    if (sqlite3_prepare_v2(database, [insertSQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_DONE) {
            
            //contact.id = sqlite3_last_insert_rowid(database);
            long long myID = sqlite3_last_insert_rowid(database);
            //contact.id = (int)myID;
            contact.id = @(myID).intValue;
            
            
            NSLog(@"*** Contact added");
        } else {
            NSLog(@"*** Contact NOT ADDED");
            NSLog(@"*** SQL error %s\n", sqlite3_errmsg(database));
        }
        sqlite3_finalize(statement);
        
        
    }
    
    
    return contact;
}

- (NSMutableArray *) retrieveAllContacts {
    NSMutableArray *contacts = [NSMutableArray array];
    NSString *selectSQL = [NSString stringWithFormat:@"SELECT * FROM contact ORDER BY name"];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [selectSQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        NSLog(@"*** Contacts retrieved");
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int id = sqlite3_column_int(statement, 0);
            char *nameChars = (char *)sqlite3_column_text(statement, 1);
            char *phoneChars = (char *)sqlite3_column_text(statement, 2);
            char *emailChars = (char *)sqlite3_column_text(statement, 3);
            
            Contact *contact = [[Contact alloc] init];
            contact.id = id;
            contact.name = [[NSString alloc] initWithUTF8String:nameChars];
            contact.phone = [[NSString alloc] initWithUTF8String:phoneChars];
            contact.email = [[NSString alloc] initWithUTF8String:emailChars];
            [contacts addObject:contact];
            
            
            
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"*** Contacts NOT retrieved");
        NSLog(@"*** SQL error: %s\n", sqlite3_errmsg(database));
    }
    return contacts;
}

- (Contact *) updateContact:(Contact *)contact {
    NSString *updateSQL = [NSString stringWithFormat:@"UPDATE contact SET name=\"%@\", phone=\"%@\", email=\"%@\" WHERE id = %i ", contact.name, contact.phone, contact.email, contact.id];
    
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [updateSQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"*** Contact updated");
        } else {
            NSLog(@"*** Contact NOT updated");
            NSLog(@"*** SQL error: %s\n", sqlite3_errmsg(database));
            
        }
        sqlite3_finalize(statement);
    }
    
    
    return contact;
}

- (Contact *) deleteContact:(Contact *)contact {
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM contact WHERE id = %i ", contact.id];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [deleteSQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"*** Contact deleted");
        
        } else {
            NSLog(@"*** Contact NOT deleted");
            NSLog(@"*** SQL error: %s\n", sqlite3_errmsg(database));
                  
        }
        sqlite3_finalize(statement);
        
    }
    return contact;
}

- (void)dealloc {
    sqlite3_close(database);
}
@end
