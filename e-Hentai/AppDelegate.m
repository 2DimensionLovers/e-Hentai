//
//  AppDelegate.m
//  e-Hentai
//
//  Created by 啟倫 陳 on 2014/8/27.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

	///區分iPad
	NSString *deviceType = [UIDevice currentDevice].model;
	NSLog(@"deviceType=[%@]",deviceType);

	///測試用裝置
	deviceType = [[UIDevice currentDevice] name];
	NSLog(@"deviceType=[%@]",deviceType);

	HentaiNavigationController *hentaiNavigation;
	if ([deviceType isEqualToString:@"elver's NiPad"]) {
		hentaiNavigation = [[HentaiNavigationController alloc] initWithRootViewController:[Pad_Main_VCLR new]];
	}else {
		hentaiNavigation = [[HentaiNavigationController alloc] initWithRootViewController:[MainViewController new]];
		hentaiNavigation.hentaiMask = UIInterfaceOrientationMaskPortrait;
	}
	self.window.rootViewController = hentaiNavigation;
	[self.window makeKeyAndVisible];
	return YES;


	
}

@end
