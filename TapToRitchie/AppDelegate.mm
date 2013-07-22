//
//  AppDelegate.m
//  TapToRitchie
//
//  Created by Michael Ferenduros on 21/07/2013.
//  Copyright (c) 2013 Michael Ferenduros. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

@implementation AppDelegate



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	srand( [[NSDate date] timeIntervalSince1970] );

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[UIApplication sharedApplication].statusBarHidden = YES;

	self.viewController = [[ViewController alloc] init];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
