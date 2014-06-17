//
//  TMCoreDataController.m
//  CoreDataExample
//
//  Created by Bryan Irace on 6/2/14.
//  Copyright (c) 2014 Bryan Irace. All rights reserved.
//

#import "TMCoreDataController.h"

static NSString * const ManagedObjectModelResourceName = @"CoreDataExample";
static NSString * const ManagedObjectModelExtension = @"momd";
static NSString * const PersistentStorePath = @"Tumblr.sqlite";

@interface TMCoreDataController()

@property (nonatomic, strong) NSManagedObjectContext *masterContext;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;

@end

@implementation TMCoreDataController

#pragma mark - Initialization

+ (instancetype)sharedInstance {
    static TMCoreDataController *instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (void)setUp {
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:
                                                [[NSBundle mainBundle] URLForResource:ManagedObjectModelResourceName
                                                                        withExtension:ManagedObjectModelExtension]];
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    
    _masterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _masterContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    _masterContext.persistentStoreCoordinator = persistentStoreCoordinator;
    
    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainContext.parentContext = _masterContext;

    NSURL *persistentStoreURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]
                                  firstObject]
                                 URLByAppendingPathComponent:PersistentStorePath];
    
    [self addPersistentStoreAtURL:persistentStoreURL toCoordinator:persistentStoreCoordinator requiringCompatabilityWithModel:managedObjectModel];
    
    void (^registerToSaveMainContextWhenObservingNotificationWithName)(NSString *) = ^(NSString *notificationName) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveMainContext) name:notificationName object:nil];
    };
    registerToSaveMainContextWhenObservingNotificationWithName(UIApplicationDidEnterBackgroundNotification);
    registerToSaveMainContextWhenObservingNotificationWithName(UIApplicationWillTerminateNotification);
}

#pragma mark - Private

/**
 *  Add a persistent store to a coordinator. If a store already exists on disk, reuse it iff it is compatable with the 
 *  provided managed object model. Otherwise, delete the store on disk and create a new one.
 */
- (NSPersistentStore *)addPersistentStoreAtURL:(NSURL *)persistentStoreURL
                                 toCoordinator:(NSPersistentStoreCoordinator *)coordinator
               requiringCompatabilityWithModel:(NSManagedObjectModel *)model {
    BOOL storeWasRecreated = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[persistentStoreURL path]]) {
        NSError *storeMetadataError = nil;
        NSDictionary *storeMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                                 URL:persistentStoreURL
                                                                                               error:&storeMetadataError];
        
        // If store is incompatible with the managed object model, remove the store file
        if (storeMetadataError || ![model isConfiguration:nil compatibleWithStoreMetadata:storeMetadata]) {
            storeWasRecreated = YES;
            
            NSError *removeStoreError = nil;
            
            if (![[NSFileManager defaultManager] removeItemAtURL:persistentStoreURL error:&removeStoreError]) {
                NSLog(@"Error removing store file at URL '%@': %@, %@", persistentStoreURL, removeStoreError, [removeStoreError userInfo]);
            }
        }
    }
    
    NSError *addStoreError = nil;
    NSPersistentStore *store = [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:persistentStoreURL
                                                               options:nil error:&addStoreError];

    if (!store) {
        NSLog(@"Unable to add store: %@, %@", addStoreError, [addStoreError userInfo]);
    }
    
    return store;
}

/**
 *  Save the provided managed object context as well as its parent context(s) (recursively)
 */
- (void)saveContext:(NSManagedObjectContext *)context {
    if ([context hasChanges]) {
        NSError *error;
        
        if (![context save:&error]) {
            NSLog(@"Error saving context: %@ %@ %@", self, error, [error userInfo]);
        }
        
        [self saveContext:context.parentContext];
    }
}

/**
 *  Save the main queue's context as well as its parent context(s) (recursively)
 */
- (void)saveMainContext {
    [self saveContext:self.mainContext];
}

#pragma mark - Block operations

/**
 *  Perform a block on a new context (with private queue concurrency type), and then save the context as well as its 
 *  parent context(s) (recursively).
 */
- (void)performBackgroundBlockAndWait:(TMCoreDataControllerBlock)block {
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = self.mainContext;
    
    if (block) {
        [backgroundContext performBlockAndWait:^{
            block(backgroundContext);
            
            [self saveContext:backgroundContext];
        }];
    }
}

/**
 *  Perform a block on the main queue's context, and then save the context as well as its parent context(s) (recursively).
 */
- (void)performMainContextBlock:(TMCoreDataControllerBlock)block {
    if (block) {
        block(self.mainContext);
        
        [self saveMainContext];
    }
}

@end
