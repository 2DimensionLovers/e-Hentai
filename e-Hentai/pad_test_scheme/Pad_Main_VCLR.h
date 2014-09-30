//
//  Pad_Main_VCLR.h
//  e-Hentai
//
//  Created by elver2 on 2014/9/6.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HentaiParser.h"
#import "GalleryCell.h"
#import "HentaiNavigationController.h"
#import "ComicViewController.h"
#import "PhotoViewController.h"
#import "FakeViewController.h"

@interface Pad_Main_VCLR : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UISearchBarDelegate>

@property (nonatomic, retain) UICollectionView *listCollectionView;

@end
