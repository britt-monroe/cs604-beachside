//
//  ContactSvcCoreData.m
//  ContactMgr2
//
//  Created by Josh Gray on 6/20/14.
//  Copyright (c) 2014 msse650. All rights reserved.
//

#import "ContactSvcCoreData.h"

@implementation ContactSvcCoreData

NSManagedObjectModel *model = nil;
NSPersistentStoreCoordinator *psc = nil;
NSManagedObjectContext *moc = nil;


- (id)  init {
    NSLog(@"init ENTERED");
    if(self = [super init]) {
        [self initializeCoreData];
        return self;
    }
    return nil;
}

- (Contact *) createContact:(Contact *)contact {
    NSLog(@"createContact ENTERED");
    Contact *managedContact = [self createManagedContact];
    /*
    NSManagedObject *managedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:moc];
    [managedObject setValue:contact.name forKey:@"name"];
    [managedObject setValue:contact.phone forKey:@"phone"];
    [managedObject setValue:contact.email forKey:@"email"];
     */
    managedContact.name = contact.name;
    managedContact.phone = contact.phone;
    managedContact.email = contact.email;
    
    NSError *error;
    if (![moc save:&error]) {
        NSLog(@"createContact ERROR: %@", [error localizedDescription]);
    }
    
    return managedContact;
}

- (NSArray *) retrieveAllContacts {
    NSLog(@"retrieveAllContacts ENTERED");
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    NSError *error;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
    
    /*
    NSMutableArray *contacts = [NSMutableArray arrayWithCapacity:fetchedObjects.count];
    for (NSManagedObject *managedObject in fetchedObjects) {
        Contact *contact = [[Contact alloc] init];
        contact.name = [managedObject valueForKey:@"name"];
        contact.phone = [managedObject valueForKey:@"phone"];
        contact.email = [managedObject valueForKey:@"email"];
        NSLog(@"contact: %@ ", [contact description]);
        [contacts addObject:contact];
        
        
        
    }
    return contacts;
    */
}

- (Contact *) updateContact:(Contact *)contact {
    NSLog(@"updateContact ENTERED");
    NSError *error;
    if (![moc save:&error]) {
        NSLog(@"updateContact ERROR: %@", [error localizedDescription]);
    }
    
    /*
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@ AND phone = %@ AND email = %@", contact.name, contact.phone, contact.email];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    */
    return contact;
}

- (Contact *) deleteContact:(Contact *)contact {
    NSLog(@"deleteContact ENTERED");
    [moc deleteObject:contact];
    
    /*
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@ AND phone = %@ AND email = %@", contact.name, contact.phone, contact.email];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    
    if ([fetchedObjects count] == 1)
    {
        NSManagedObject *managedObject = [fetchedObjects objectAtIndex:0];
        [moc deleteObject:managedObject];
        
    }
    */
    
    return contact;
}

- (void) initializeCoreData
{
    NSLog(@"initializeCoreData ENTERED");
    
    // initialize (load) the schema model
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    // initialize the persistent store coordinator with the model
    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"ContactsMgr.sqlite"];
    NSError *error = nil;
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    if ([psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        //initialize the managed object context
        moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
               [moc setPersistentStoreCoordinator:psc];
          NSLog(@"initializeCoreData GOOD");
        
    } else {
        NSLog(@"initializeCoreData FAILED with error: %@", error);
                   
    }
         
         
    
}

- (Contact *) createManagedContact {
    NSLog(@"createManagedContact ENTERED");
    Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:moc];
    return contact;
    
}


@end
