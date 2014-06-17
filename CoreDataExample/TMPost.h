//
//  TMPost.h
//  CoreDataExample
//
//  Created by Bryan Irace on 6/2/14.
//  Copyright (c) 2014 Tumblr. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface TMPost : NSManagedObject

@property (nonatomic, copy) NSString *postID;
@property (nonatomic, copy) NSString *blogName;

+ (instancetype)postFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

+ (NSFetchRequest *)allPostsFetchRequest;

@end
