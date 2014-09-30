//
//  GalleryCell.m
//  e-Hentai
//
//  Created by Jack on 2014/9/4.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import "GalleryCell.h"
#import "UIImageView+WebCache.h"
#import "CategoryTitle.h"
#import "RatingStar.h"

@implementation GalleryCell



#pragma mark -

//設定資料
- (void)setGalleryDict:(NSDictionary *)dataDict {
	self.cellLabel.text = dataDict[@"title"];
	self.cellLabel.lineBreakMode = NSLineBreakByWordWrapping;
	self.cellLabel.numberOfLines = 0;
	self.cellDate.text = dataDict[@"posted"];
	self.cellPage.text = [NSString stringWithFormat:@"%@ /%@", dataDict[@"filecount"], dataDict[@"filesize"]];

	BOOL enableImageMode = [dataDict[imageMode] boolValue];

	NSString *imgUrl = @"http://i.imgur.com/1gzbPf1.jpg"; //貓貓圖(公司用)

	if (enableImageMode) {
		imgUrl = dataDict[@"thumb"]; //(真的H縮圖)
	}

	[self.cellImageView sd_setImageWithURL:[NSURL URLWithString:imgUrl]
						  placeholderImage:nil
								   options:SDWebImageRefreshCached];

	[self.cellCategory setCategoryStr:dataDict[@"category"]];
	[self.cellStar setStar:dataDict[@"rating"]];
}

- (void)layoutSubviews {
	//Fit並置中
	self.cellImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.cellImageView.clipsToBounds = YES;
	self.cellImageView.center = CGPointMake(self.cellImageView.center.x, CGRectGetMidY(self.bounds));
	self.layer.cornerRadius = CGRectGetHeight(self.cellCategory.frame) / 4;
}

@end
