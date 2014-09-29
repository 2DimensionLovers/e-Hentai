//
//  AppDelegate.m
//  e-Hentai
//
//  Created by 啟倫 陳 on 2014/8/27.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	//區分iPad
	HentaiNavigationController *hentaiNavigation;
	if ([[UIDevice currentDevice].model isEqualToString:@"iPad"]) {
		hentaiNavigation = [[HentaiNavigationController alloc] initWithRootViewController:[Pad_Main_VCLR new]];
	}
	else {
		hentaiNavigation = [[HentaiNavigationController alloc] initWithRootViewController:[MainViewController new]];
	}
	hentaiNavigation.autorotate = NO;
	hentaiNavigation.hentaiMask = UIInterfaceOrientationMaskPortrait;
	self.window.rootViewController = hentaiNavigation;
	[self.window makeKeyAndVisible];
	return YES;
}

@end
