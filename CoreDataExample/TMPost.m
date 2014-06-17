//
//  TMPost.m
//  CoreDataExample
//
//  Created by Bryan Irace on 6/2/14.
//  Copyright (c) 2014 Tumblr. All rights reserved.
//

#import "TMPost.h"

@implementation TMPost

@dynamic postID;
@dynamic blogName;

+ (instancetype)postFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context {
    TMPost *post = [[[self class] alloc] initWithEntity:[NSEntityDescription entityForName:@"Post" inManagedObjectContext:context]
                             insertIntoManagedObjectContext:context];
    post.postID = [dictionary[@"id"] stringValue];
    post.blogName = dictionary[@"blog_name"];
    
    return post;
}

+ (NSFetchRequest *)allPostsFetchRequest {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Post"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"postID != nil"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"postID" ascending:NO]];
    
    return fetchRequest;
}

@end
