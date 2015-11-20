//
//  ViewController.m
//  ContactMgr2
//
//  Created by Josh Gray on 5/19/14.
//  Copyright (c) 2014 msse650. All rights reserved.
//

#import "ViewController.h"

#import "Contact.h"
//#import "ContactSvcCache.h"
//#import "ContactSvcArchive.h"
//#import "ContactSvcSQLite.h"
#import "ContactSvcCoreData.h"

@interface ViewController ()

@end

@implementation ViewController

//ContactSvcCache * contactSvc = nil;
//ContactSvcArchive * contactSvc = nil;
//ContactSvcSQLite *contactSvc = nil;
ContactSvcCoreData *contactSvc = nil;




- (void)viewDidLoad
{
    [super viewDidLoad];
	//contactSvc = [[ContactSvcCache alloc] init];
    //contactSvc = [[ContactSvcArchive alloc] init];
    //contactSvc = [[ContactSvcSQLite alloc] init];
    contactSvc = [[ContactSvcCoreData alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveContact:(id)sender {
    NSLog(@"saveContact: entering");
    
    [self.view endEditing:YES];
    
    NSLog(@"saveContact: 1");
    //Contact *contact = [[Contact alloc] init];
    //Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:moc];
    Contact *contact = [contactSvc createManagedContact];
    NSLog(@"saveContact: 2");
    contact.name = _name.text;
    NSLog(@"saveContact: 3");
    contact.phone = _phone.text;
    NSLog(@"saveContact: 4");
    contact.email = _email.text;
    NSLog(@"saveContact: 5");
    
    
    
    NSLog(@"saveContact: Creating %@" , contact.name);
    
    //[contactSvc createContact:contact];
    
    [self.tableView reloadData];
    NSLog(@"saveContact: contact saved");
}



-(UITableViewCell *) GetCellFromTableView:(UITableView*)tableView Sender:(id)sender {
    CGPoint pos = [sender convertPoint:CGPointZero toView:tableView];
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:pos];
    return [tableView cellForRowAtIndexPath:indexPath];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[contactSvc retrieveAllContacts] count];
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIndentifier = @"SimpleTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIndentifier];
    if (cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIndentifier];
        
    }
    
    Contact *contact = [[contactSvc retrieveAllContacts] objectAtIndex:indexPath.row];
    
    
    //JKG mistake in example code here
    //cell.textLabel.text = contact.name;
    cell.textLabel.font = [UIFont systemFontOfSize:22];
    //cell.textLabel.text = contact.description;
    cell.textLabel.text = contact.name;
    return cell;
}

- (IBAction)deleteContact:(id)sender {
    NSLog(@"deleteContact: entering");
    //Contact *contact = sender;
    [self.view endEditing:YES];
    //NSLog(@"%d" , _lastClickedRow);
    
    

    UIView *senderButton = (UIView*) sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell: (UITableViewCell*)[[senderButton superview]superview]];
    Contact *contact = [[contactSvc retrieveAllContacts] objectAtIndex:indexPath.row];
    [contactSvc deleteContact:contact];
    
    NSLog(@"deleteContact: Deleting %@" , contact.name);
    [self.tableView reloadData];
    NSLog(@"deleteContact: contact deleted");
    
}

@end
