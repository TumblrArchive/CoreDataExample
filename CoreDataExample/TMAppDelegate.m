//
//  TMAppDelegate.m
//  CoreDataExample
//
//  Created by Bryan Irace on 6/2/14.
//  Copyright (c) 2014 Bryan Irace. All rights reserved.
//

#import "TMAppDelegate.h"
#import "TMDashboardViewController.h"
#import "TMAPIClient.h"
#import "TMCoreDataController.h"

@implementation TMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[TMCoreDataController sharedInstance] setUp];
    
#warning Needs keys/secrets
    /*
     In order for this to work, you need to create a Tumblr API application, which can be done here: https://www.tumblr.com/oauth/apps. 
     You can then use the API console to get a token and token secret: https://api.tumblr.com/console
     */
    [TMAPIClient sharedInstance].OAuthConsumerKey = @"";
    [TMAPIClient sharedInstance].OAuthConsumerSecret = @"";
    [TMAPIClient sharedInstance].OAuthToken = @"";
    [TMAPIClient sharedInstance].OAuthTokenSecret = @"";
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[TMDashboardViewController alloc] init]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
