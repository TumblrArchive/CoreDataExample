//
//  TMDashboardViewController.m
//  CoreDataExample
//
//  Created by Bryan Irace on 6/2/14.
//  Copyright (c) 2014 Tumblr. All rights reserved.
//

#import "TMDashboardViewController.h"
#import "TMFetchedResultsControllerDelegate.h"
#import "TMPost.h"
#import "TMAPIClient.h"
#import "TMCoreDataController.h"

@interface TMDashboardViewController()

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) TMFetchedResultsControllerDelegate *fetchedResultsControllerDelegate;

@end

@implementation TMDashboardViewController

- (id)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        self.title = @"Dashboard";
    }
    
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    self.fetchedResultsControllerDelegate = [[TMFetchedResultsControllerDelegate alloc] initWithTableView:self.tableView];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[TMPost allPostsFetchRequest]
                                                                        managedObjectContext:[TMCoreDataController sharedInstance].mainContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    self.fetchedResultsController.delegate = self.fetchedResultsControllerDelegate;

    [self.fetchedResultsController performFetch:nil];
    
    [self refresh];
}

#pragma mark - Actions

- (void)refresh {
    [[TMAPIClient sharedInstance] dashboard:nil callback:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[TMCoreDataController sharedInstance] performBackgroundBlockAndWait:^(NSManagedObjectContext *context) {
                // Delete all existing posts
                
                NSArray *cachedPosts = [context executeFetchRequest:[TMPost allPostsFetchRequest] error:nil];
                
                for (TMPost *cachedPost in [cachedPosts reverseObjectEnumerator]) {
                    [context deleteObject:cachedPost];
                }
                
                // Create new posts out of API response
                
                NSArray *responsePostDictionaries = response[@"posts"];
                
                for (NSDictionary *responsePostDictionary in responsePostDictionaries) {
                    [context insertObject:[TMPost postFromDictionary:responsePostDictionary inContext:context]];
                }
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
            });
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    TMPost *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = post.blogName;
    cell.detailTextLabel.text = post.postID;
    
    return cell;
}

@end
