//
//  Pad_Main_VCLR.m
//  e-Hentai
//
//  Created by elver2 on 2014/9/6.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import "Pad_Main_VCLR.h"
#import "HentaiSearchFilter.h"
#import "HentaiFilterView.h"

@interface Pad_Main_VCLR ()
{
	BOOL enableH_Image;
	BOOL zBoolNotDownLoadMode;
	NSString *searchWord;
	HentaiFilterView *filterView;
}

@property (nonatomic, assign) NSUInteger listIndex;
@property (nonatomic, strong) NSMutableArray *listArray;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UISearchBar *searchBar;


@end

@implementation Pad_Main_VCLR


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hentaiDownloadSuccess:) name:HentaiDownloadSuccessNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:HentaiDownloadSuccessNotification object:nil];
}

- (void)dealloc {
	self.listCollectionView.dataSource = nil;
	self.listCollectionView.delegate = nil;
	self.searchBar.delegate = nil;
}

#pragma mark - life cycle

- (void)viewDidLoad {
	[super viewDidLoad];
    
	zBoolNotDownLoadMode = NO;
    
	self.listIndex = 0;
	enableH_Image = NO;
	self.listArray = [NSMutableArray array];
	searchWord = @"";
    
    
	[self zMethDoListCollectionView];
	[self zMethCreateNavBarBtn];
	[self zMethDoSearchBar];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - UI

- (void)zMethCreateNavBarBtn {
	UIBarButtonItem *changeModeItem0 = [[UIBarButtonItem alloc] initWithTitle:@"H圖" style:UIBarButtonItemStylePlain target:self action:@selector(changeImageMode0:)];
	UIBarButtonItem *changeModeItem1 = [[UIBarButtonItem alloc] initWithTitle:@"See" style:UIBarButtonItemStylePlain target:self action:@selector(changeImageMode1:)];
    
	self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:changeModeItem0, changeModeItem1, nil];
}

- (void)zMethDoListCollectionView {
	if (!self.listCollectionView) {
		UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
		self.listCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen]bounds].size.width, [[UIScreen mainScreen]bounds].size.height) collectionViewLayout:layout];
		self.listCollectionView.delegate = self;
		self.listCollectionView.dataSource = self;
        
        //    [self.listCollectionView registerClass:[GalleryCell class] forCellWithReuseIdentifier:@"GalleryCell"];
        
		[self.listCollectionView registerNib:[UINib nibWithNibName:@"GalleryCell" bundle:nil] forCellWithReuseIdentifier:@"GalleryCell"];
        
		[HentaiParser requestListAtIndex:self.listIndex completion: ^(HentaiParserStatus status, NSArray *listArray) {
		    [self.listArray addObjectsFromArray:listArray];
		    [self.listCollectionView reloadData];
		}];
	}
    
	[self.view addSubview:self.listCollectionView];
    
	//add refresh control
	self.refreshControl = [[UIRefreshControl alloc]init];
	[self.listCollectionView addSubview:self.refreshControl];
	[self.refreshControl addTarget:self
	                        action:@selector(reloadDatas)
	              forControlEvents:UIControlEventValueChanged];
}

- (void)zMethDoSearchBar {
	//search bar
	self.searchBar = [[UISearchBar alloc] init];
	self.navigationItem.titleView = self.searchBar;
	self.searchBar.delegate = self;
    
	//調整畫面的大小
	CGRect screenSize = [UIScreen mainScreen].bounds;
	self.view.frame = screenSize;
	self.listCollectionView.frame = screenSize;
    
	//調整 filterView 的大小
	CGFloat keyboardHeight = 412;
	CGRect filterFrame = CGRectMake(0, 0, CGRectGetWidth(screenSize), CGRectGetHeight(screenSize) - keyboardHeight - 64);
	filterView = [[HentaiFilterView alloc] initWithFrame:filterFrame];
	self.searchBar.inputAccessoryView = filterView;
}

#pragma mark - Function

- (void)reloadDatas {
	self.listIndex = 0;
	__weak Pad_Main_VCLR *weakSelf = self;
    
	NSString *baseUrlString = [NSString stringWithFormat:@"http://g.e-hentai.org/?page=%d", self.listIndex];
	NSString *filterString = [HentaiSearchFilter searchFilterUrlByKeyword:searchWord filterArray:[filterView filterResult] baseUrl:baseUrlString];
    
	[HentaiParser requestListAtFilterUrl:filterString completion: ^(HentaiParserStatus status, NSArray *listArray) {
	    if (status && weakSelf) {
	        [weakSelf.listArray removeAllObjects];
	        [weakSelf.listArray addObjectsFromArray:listArray];
	        [weakSelf.listCollectionView reloadData];
	        [weakSelf.listCollectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
	        [weakSelf.refreshControl endRefreshing];
		}
	    else {
	        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"錯誤"
	                                                        message:@"讀取失敗"
	                                                       delegate:nil
	                                              cancelButtonTitle:@""
	                                              otherButtonTitles:nil];
	        [alert show];
		}
	}];
}

- (void)zMethCleanImageCache {
	//清除GalleryCell的圖片暫存
	[[SDImageCache sharedImageCache] clearMemory];
	[[SDImageCache sharedImageCache] clearDisk];
}

#pragma mark - Action

- (void)changeImageMode0:(UIBarButtonItem *)sender {
	enableH_Image = !enableH_Image;
    
	if (enableH_Image) {
		sender.title = @"貓圖";
	}
	else {
		sender.title = @"H圖";
	}
    
	[self.listCollectionView reloadData];
}

- (void)changeImageMode1:(UIBarButtonItem *)sender {
	zBoolNotDownLoadMode = !zBoolNotDownLoadMode;
    
	if (zBoolNotDownLoadMode) {
		sender.title = @"Ask";
	}
	else {
		sender.title = @"See";
	}
    
	[self.listCollectionView reloadData];
}

- (void)keyboardWillChange:(NSNotification *)notification {
	CGRect keyboardEndRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	NSLog(@"KeyBoardFrame=[%f][%f][%f][%f]", keyboardEndRect.origin.x, keyboardEndRect.origin.y, keyboardEndRect.size.width, keyboardEndRect.size.height);
}

#pragma mark -  UISearchBarDelegate


- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	self.searchBar.showsCancelButton = YES;
    
	if ([searchBar.text isEqualToString:@""]) {
		[filterView selectAll];
	}
	//always enable search button
	[self enableReturnKeyWithNoText:self.searchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self.searchBar resignFirstResponder];
	searchWord = searchBar.text;
	[self reloadDatas];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	searchWord = searchBar.text;
	self.searchBar.showsCancelButton = NO;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	searchWord = searchBar.text;
	self.searchBar.showsCancelButton = NO;
	[self.searchBar resignFirstResponder];
}

#pragma mark - search bar

- (void)enableReturnKeyWithNoText:(UISearchBar *)searchBar {
	UITextField *searchField = nil;
	for (UIView *subView in searchBar.subviews) {
		for (UIView *childSubview in subView.subviews) {
			if ([childSubview isKindOfClass:[UITextField class]]) {
				searchField = (UITextField *)childSubview;
				break;
			}
		}
	}
    
	if (searchField) {
		searchField.enablesReturnKeyAutomatically = NO;
	}
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [self.listArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	//無限滾
	if (
	    indexPath.row >= [self.listArray count] - 1
        //		&&[self.listArray count] == (self.listIndex+1)*25
	    ) {
		self.listIndex++;
		NSString *baseUrlString = [NSString stringWithFormat:@"http://g.e-hentai.org/?page=%d", self.listIndex];
		NSString *filterString = [HentaiSearchFilter searchFilterUrlByKeyword:searchWord filterArray:[filterView filterResult] baseUrl:baseUrlString];
        
		[HentaiParser requestListAtFilterUrl:filterString completion: ^(HentaiParserStatus status, NSArray *listArray) {
		    [self.listArray addObjectsFromArray:listArray];
		    [self.listCollectionView reloadData];
		}];
	}
	GalleryCell *cell = (GalleryCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"GalleryCell" forIndexPath:indexPath];
	NSDictionary *hentaiInfo = self.listArray[indexPath.row];
	[hentaiInfo setValue:[NSNumber numberWithBool:enableH_Image] forKey:imageMode];
	[cell setGalleryDict:hentaiInfo];
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    //	NSLog(@"do[%f][%f]",[[UIScreen mainScreen]bounds].size.width,[[UIScreen mainScreen]bounds].size.height);
	return CGSizeMake(140, 210);
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *hentaiInfo = self.listArray[indexPath.row];
	BOOL isExist = NO;
    
	for (NSDictionary *eachSavedInfo in HentaiSaveLibraryArray) {
		if ([eachSavedInfo[@"hentaiInfo"][@"url"] isEqualToString:hentaiInfo[@"url"]]) {
			isExist = YES;
			break;
		}
	}
    
	if (isExist) {
		[self zMethPushToNext:hentaiInfo];
	}
	else {
		if (zBoolNotDownLoadMode) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"請問要下載還是直接看" message:@"請搶答~ O3O" delegate:self cancelButtonTitle:@"直接看!" otherButtonTitles:@"下載!", nil];
			alert.tag = indexPath.row;
			[alert show];
		}
		else {
			[self zMethPushToNext:hentaiInfo];
		}
	}
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSDictionary *hentaiInfo = self.listArray[alertView.tag];
	if (buttonIndex) {
		[HentaiDownloadCenter addBook:hentaiInfo];
	}
	else {
		if ([HentaiDownloadCenter isDownloading:hentaiInfo]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"這本你正在抓~ O3O" message:nil delegate:nil cancelButtonTitle:@"好~ O3O" otherButtonTitles:nil];
			[alert show];
		}
		else {
			[self zMethPushToNext:hentaiInfo];
		}
	}
}

- (void)zMethPushToNext:(NSDictionary *)hentaiInfo {
	HentaiNavigationController *hentaiNavigation = (HentaiNavigationController *)self.navigationController;
	hentaiNavigation.autorotate = YES;
	hentaiNavigation.hentaiMask = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
    
	if (zBoolNotDownLoadMode) {
		PhotoViewController *photoViewController = [PhotoViewController new];
		photoViewController.hentaiInfo = hentaiInfo;
        
		[hentaiNavigation pushViewController:photoViewController animated:YES];
	}
	else {
		ComicViewController *comicViewController = [ComicViewController new];
		comicViewController.hentaiInfo = hentaiInfo;
		[hentaiNavigation pushViewController:comicViewController animated:YES];
	}
}

#pragma mark - recv notification

- (void)hentaiDownloadSuccess:(NSNotification *)notification {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"下載完成!" message:notification.object delegate:nil cancelButtonTitle:@"好~ O3O" otherButtonTitles:nil];
	[alert show];
}

@end
