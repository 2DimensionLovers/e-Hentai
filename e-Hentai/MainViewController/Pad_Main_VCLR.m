//
//  Pad_Main_VCLR.m
//  e-Hentai
//
//  Created by elver2 on 2014/9/6.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import "Pad_Main_VCLR.h"

@interface Pad_Main_VCLR ()

@property (nonatomic, assign) NSUInteger listIndex;
@property (nonatomic, strong) NSMutableArray *listArray;


@end

@implementation Pad_Main_VCLR


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


- (void)viewDidLoad {
	[super viewDidLoad];
	self.listIndex = 0;
	self.listArray = [NSMutableArray array];
	[self zMethDoListCollectionView];
}



#pragma mark - UI
-(void)zMethDoListCollectionView{
	NSLog(@"Do Ui");
	if (!self.listCollectionView) {
		UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
		self.listCollectionView=[[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen]bounds].size.width, [[UIScreen mainScreen]bounds].size.height) collectionViewLayout:layout];
		self.listCollectionView.delegate=self;
		self.listCollectionView.dataSource=self;

//    [self.listCollectionView registerClass:[GalleryCell class] forCellWithReuseIdentifier:@"GalleryCell"];

		[self.listCollectionView registerNib:[UINib nibWithNibName:@"GalleryCell" bundle:nil] forCellWithReuseIdentifier:@"GalleryCell"];

		[HentaiParser requestListAtIndex:self.listIndex completion: ^(HentaiParserStatus status, NSArray *listArray) {
			[self.listArray addObjectsFromArray:listArray];
			[self.listCollectionView reloadData];
		}];

	}

	[self.view addSubview:self.listCollectionView];
}

-(void)zMethMethChangeFrame{

}

#pragma mark - UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.listArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	//無限滾
	if (indexPath.row >= [self.listArray count]-15 && [self.listArray count] == (self.listIndex+1)*25) {
		self.listIndex++;
		[HentaiParser requestListAtIndex:self.listIndex completion: ^(HentaiParserStatus status, NSArray *listArray) {
			[self.listArray addObjectsFromArray:listArray];
			[self.listCollectionView reloadData];
		}];
	}
	GalleryCell *cell = (GalleryCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"GalleryCell" forIndexPath:indexPath];
	NSDictionary *hentaiInfo = self.listArray[indexPath.row];
	[cell setGalleryDict:hentaiInfo];
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
//	NSLog(@"do[%f][%f]",[[UIScreen mainScreen]bounds].size.width,[[UIScreen mainScreen]bounds].size.height);
	return CGSizeMake(140, 200);
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *hentaiInfo = self.listArray[indexPath.row];
	[SVProgressHUD show];
	[HentaiParser requestImagesAtURL:hentaiInfo[@"url"] atIndex:0 completion: ^(HentaiParserStatus status, NSArray *images) {
		NSLog(@"%@", images);
		HentaiNavigationController *hentaiNavigation = (HentaiNavigationController*)self.navigationController;
//		hentaiNavigation.hentaiMask = UIInterfaceOrientationMaskLandscape;

		FakeViewController *fakeViewController = [FakeViewController new];
		fakeViewController.BackBlock = ^() {
			[hentaiNavigation pushViewController:[PhotoViewController new] animated:YES];
		};
		[self presentViewController:fakeViewController animated:NO completion:^{
			[fakeViewController onPresentCompletion];
		}];

		[SVProgressHUD dismiss];
	}];
}




@end
