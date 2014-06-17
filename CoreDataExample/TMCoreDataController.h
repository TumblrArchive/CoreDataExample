//
//  TMCoreDataController.h
//  CoreDataExample
//
//  Created by Bryan Irace on 6/2/14.
//  Copyright (c) 2014 Bryan Irace. All rights reserved.
//

typedef void (^TMCoreDataControllerBlock)(NSManagedObjectContext *context);

/**
 *  Encapsulates an entire [Core Data stack](http://floriankugler.com/blog/2013/4/2/the-concurrent-core-data-stack)
 *  and exposes methods necessary to perform operations on managed object contexts associated with both the main queue
 *  and a private queue.
 */
@interface TMCoreDataController : NSObject

/**
 *  Context associated with the main queue. Can be passed directly to read-only methods that require a context but don't
 *  require the context to be saved afterwards (in which case `performMainContextBlock:` would be a better option).
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *mainContext;

+ (instancetype)sharedInstance;

- (void)setUp;

/**
 *  Provides a block with a private queue context and performs the block on the aforementioned queue, synchronously.
 *  Saves the context (and any ancestor contexts, recursively) afterwards.
 *
 *  @param block Block provided with a private queue context and performed on the aforementioned queue.
 */
- (void)performBackgroundBlockAndWait:(TMCoreDataControllerBlock)block;

/**
 *  Provides a block with the main queue context and performs the block on the main queue, synchronously.
 *  Saves the context (and any ancestor contexts, recursively) afterwards.
 *
 *  @param block Block provided with the main queue context and performed on the main queue.
 */
- (void)performMainContextBlock:(TMCoreDataControllerBlock)block;

@end
