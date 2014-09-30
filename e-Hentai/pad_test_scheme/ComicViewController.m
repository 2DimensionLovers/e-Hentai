//
//  ComicViewController.m
//  TEST_2014_9_2
//
//  Created by 啟倫 陳 on 2014/9/3.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//


#import "ComicViewController.h"
#import "zNsMeth.h"
@interface ComicViewController ()


@property (nonatomic, assign) NSUInteger zIndexPathrow;


//目前漫畫是在網路上的哪一頁
@property (nonatomic, assign) NSUInteger zIntHentaiIndex;

//漫畫每一頁的 url 網址
@property (nonatomic, strong) NSMutableArray *zMuArrayHentaiImageURLs;
//保護[漫畫每一頁的 url 網址]用,避免雙重寫入
@property (nonatomic, assign) BOOL zBoolIsDoingHentaiImageURLs;

//記錄 fail 了幾次
@property (nonatomic, strong) NSMutableDictionary *zMuDictRetryMap;
@property (nonatomic, assign) NSUInteger zIntFailCount;
//放3次失敗的網址,給使用者選擇是否重讀
@property (nonatomic, strong) NSMutableArray *zMuArrayFailHentaiImageURLs;
//只存放已下載好有到Local端的圖檔路徑; Key是圖檔順序 value是圖檔在Local的路徑
//用來讓TableView可以知道用哪張圖
@property (nonatomic, strong) NSMutableDictionary *zMuDictForIndexHentaiImageURLs;

//已經下載好的漫畫結果
//結構 key 是檔案名稱 (url 網址的 lastPathComponent) NSString
//value 是該檔案的高度 NSNumber
@property (nonatomic, strong) NSMutableDictionary *zMuDictHentaiResults;


//從漫畫主頁的網址拆出來一組獨一無二的 key, 用作儲存識別
@property (nonatomic, readonly) NSString *zStrHentaiKey;

//真正可以看到哪一頁 (下載的檔案需要有連續, 數字才會增長)
@property (nonatomic, assign) NSInteger zIntRealDisplayCount;
@property (nonatomic, assign) NSUInteger zIntDownloadKey;
@property (nonatomic, assign) BOOL zBoolIsRemovedHUD;
@property (nonatomic, strong) NSOperationQueue *zOpQueHentaiQueue;
@property (nonatomic, strong) FMStream *hentaiFilesManager;

@property (nonatomic, strong) NSString *zStrHentaiURLString;
@property (nonatomic, strong) NSString *zStrMaxHentaiCount;


//放在section參考用,以後可能會移除
@property (nonatomic, retain) UIView *zViewOnSectionStatus;
@property (nonatomic, retain) UILabel *zLabelOnSectionStatus;

- (void)backActionOnPad;
- (void)saveActionOnPad;
- (void)deleteActionOnPad;
- (void)zMethReCheckOnPad;

- (void)setupInitValues;

- (CGSize)imagePortraitHeight:(CGSize)landscapeSize;
- (void)preloadImages:(NSArray *)images;
- (NSInteger)availableCount;

- (void)waitingOnDownloadFinish;
- (void)checkEndOfFile;
- (void)setupForAlreadyzIntDownloadKey:(NSUInteger)zIntDownloadKey;
- (NSUInteger)foundzIntDownloadKey;

@end

@implementation ComicViewController


#pragma mark - getter

@dynamic zStrHentaiKey;

- (NSString *)zStrHentaiKey {
	return [NSString stringWithFormat:@"%@", [zNsMeth zMethReturnHentaiKey:@"" ForTitle:self.hentaiInfo[@"title"] ForHttpUrl:self.zStrHentaiURLString]];
}

#pragma mark - ibaction

- (IBAction)singleTapScreenAction:(id)sender {
	[self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
	[self setNeedsStatusBarAppearanceUpdate];
	self.zViewOnSectionStatus.hidden = self.navigationController.navigationBarHidden ? YES : NO;
}

- (IBAction)slideGestureGoBack:(id)sender {
	[self backActionOnPad];
}

#pragma mark - navigation bar button action

- (void)backActionOnPad {
	HentaiNavigationController *hentaiNavigation = (HentaiNavigationController *)self.navigationController;
	hentaiNavigation.autorotate = NO;
	hentaiNavigation.hentaiMask = UIInterfaceOrientationMaskPortrait;

	//FakeViewController 是一個硬把畫面轉直的媒介
	FakeViewController *fakeViewController = [FakeViewController new];
	fakeViewController.BackBlock = ^() {
		[hentaiNavigation popViewControllerAnimated:YES];
	};
	[self presentViewController:fakeViewController animated:NO completion: ^{
		[fakeViewController onPresentCompletion];
	}];
}

- (void)saveActionOnPad {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"你想要儲存這本漫畫嗎?" message:@"過程是不能中斷的, 請保持網路順暢." delegate:self cancelButtonTitle:@"不要好了...Q3Q" otherButtonTitles:@"衝吧! O3O", nil];
	[alert show];
}

- (void)deleteActionOnPad {
	[[FilesManager documentFolder] rd:self.zStrHentaiKey];
	[HentaiSaveLibraryArray removeObjectAtIndex:self.zIntDownloadKey];
	[self backActionOnPad];
}

- (void)zMethReCheckOnPad {
	if (self.zMuArrayFailHentaiImageURLs.count > 0) {
		NSString *zStr;
		for (int i = 0; i < self.zMuArrayFailHentaiImageURLs.count; i++) {
			zStr = [NSString stringWithFormat:@"%@", [self.zMuArrayFailHentaiImageURLs objectAtIndex:i]];
			[self createNewOperation:zStr];
			[self.zMuArrayFailHentaiImageURLs removeObject:zStr];
		}
	}
}

#pragma mark - setup inits

- (void)setupInitValues {
	//目前用不到,以後上面可會是一排按鈕
	//	self.title = @"Loading...";

	//navigation bar 上的兩個 button
	UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backActionOnPad)];
	self.navigationItem.leftBarButtonItem = newBackButton;

	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(saveActionOnPad)];

	///TODO:可能有更好的方式來做Recheck
	UIBarButtonItem *changeModeItem1 = [[UIBarButtonItem alloc] initWithTitle:@"ReCheck" style:UIBarButtonItemStylePlain target:self action:@selector(zMethReCheckOnPad)];

	self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:saveButton, changeModeItem1, nil];

	self.zBoolIsDoingHentaiImageURLs = NO;
	//註冊 cell
	[self.hentaiTableView registerClass:[HentaiPhotoCell class] forCellReuseIdentifier:@"HentaiPhotoCell"];

	self.zStrHentaiURLString = self.hentaiInfo[@"url"];
	self.zStrMaxHentaiCount = self.hentaiInfo[@"filecount"];

	//OperationQueue 限制數量為 5
	self.zOpQueHentaiQueue = [NSOperationQueue new];
	[self.zOpQueHentaiQueue setMaxConcurrentOperationCount:5];
	//相關參數初始化
	self.zMuArrayFailHentaiImageURLs = [NSMutableArray array];
	self.zMuArrayHentaiImageURLs = [NSMutableArray array];
	self.zMuDictRetryMap = [NSMutableDictionary dictionary];
	self.zMuDictForIndexHentaiImageURLs = [NSMutableDictionary dictionary];
	if (HentaiCacheLibraryDictionary[self.zStrHentaiKey]) {
		//這邊要多一個判斷, 當 cache 資料夾下如果找不到東西了, 表示圖片已經被清掉
		if ([[[FilesManager cacheFolder] fcd:@"Hentai"] cd:self.zStrHentaiKey]) {
			self.zMuDictHentaiResults = HentaiCacheLibraryDictionary[self.zStrHentaiKey];
		}
		else {
			self.zMuDictHentaiResults = [NSMutableDictionary dictionary];
			[HentaiCacheLibraryDictionary removeObjectForKey:self.zStrHentaiKey];
		}
	}
	else {
		self.zMuDictHentaiResults = [NSMutableDictionary dictionary];
	}
	self.zIntHentaiIndex = 0;
	self.zIntFailCount = 0;
	self.zBoolIsRemovedHUD = NO;
	self.zIntRealDisplayCount = 0;
}

#pragma mark - components

//換算直向的高度
- (CGSize)imagePortraitHeight:(CGSize)landscapeSize {
	CGFloat oldWidth = landscapeSize.width;
	CGFloat scaleFactor = [UIScreen mainScreen].bounds.size.width / oldWidth;
	CGFloat newHeight = landscapeSize.height * scaleFactor;
	CGFloat newWidth = oldWidth * scaleFactor;
	return CGSizeMake(newWidth, newHeight);
}

//計算目前到底可以顯示到哪一個 index
- (NSInteger)availableCount {
	NSInteger returnIndex = -1;
	for (NSInteger i = self.zIntRealDisplayCount; i < [self.zMuArrayHentaiImageURLs count]; i++) {
		NSString *eachImageString = self.zMuArrayHentaiImageURLs[i];
		if (self.zMuDictHentaiResults[[eachImageString lastPathComponent]]) {
			returnIndex = i;
		}
		else {
			break;
		}
	}
	return returnIndex + 1;
}

- (void)createNewOperation:(NSString *)urlString {
	HentaiDownloadImageOperation *newOperation = [HentaiDownloadImageOperation new];
	newOperation.downloadURLString = urlString;
	newOperation.isCacheOperation = YES;
	newOperation.hentaiKey = self.zStrHentaiKey;
	newOperation.delegate = self;
	[self.zOpQueHentaiQueue addOperation:newOperation];
}

#pragma mark - download methods

//將要下載的圖片加到 queue 裡面
- (void)preloadImages:(NSArray *)images {
	for (NSString *eachImageString in images) {
		[self createNewOperation:eachImageString
		 //		  NewOperationQueueLevel:NSOperationQueuePriorityNormal
		 ];
	}
}

//等待圖片下載完成
- (void)waitingOnDownloadFinish {
	__weak ComicViewController *weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		[weakSelf.zOpQueHentaiQueue waitUntilAllOperationsAreFinished];
		if (weakSelf) {
			__strong ComicViewController *strongSelf = weakSelf;
			dispatch_async(dispatch_get_main_queue(), ^{
				[strongSelf checkEndOfFile];
			});
		}
	});
}

//製作要給予下載Meth的的列表清單
- (void)parserRequest:(NSString *)zStrParmer {
	if (!self.zBoolIsDoingHentaiImageURLs) {
		self.zBoolIsDoingHentaiImageURLs = YES;
		__weak ComicViewController *weakSelf = self;
		[HentaiParser requestImagesAtURL:self.zStrHentaiURLString atIndex:self.zIntHentaiIndex completion: ^(HentaiParserStatus status, NSArray *images) {
			if (status && weakSelf) {
				__strong ComicViewController *strongSelf = weakSelf;
				[strongSelf.zMuArrayHentaiImageURLs addObjectsFromArray:images];
				[strongSelf preloadImages:images];
				if ([zStrParmer isEqualToString:@"checkEndOfFile"]) {
					[strongSelf waitingOnDownloadFinish];
				}
				self.zBoolIsDoingHentaiImageURLs = NO;
			}
			else if ([zStrParmer isEqualToString:@"viewDidLoad"]) {
				if (!status && weakSelf) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"讀取失敗囉" message:nil delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil];
					[alert show];
					[SVProgressHUD dismiss];
				}
				else if ([images count] == 0) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"讀取失敗囉" message:nil delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil];
					[alert show];
					[SVProgressHUD dismiss];
				}
				self.zBoolIsDoingHentaiImageURLs = NO;
			}
		}];
	}
}

//檢查是不是還有圖片需要下載
- (void)checkEndOfFile {
	if ([self.zMuArrayHentaiImageURLs count] < [self.zStrMaxHentaiCount integerValue]) {
		self.zIntHentaiIndex++;
		[self parserRequest:NSStringFromSelector(_cmd)];
	}
	else {
		FMStream *saveFolder = [FilesManager documentFolder];
		[self.hentaiFilesManager moveToPath:[saveFolder.currentPath stringByAppendingPathComponent:self.zStrHentaiKey]];
		NSDictionary *saveInfo = @{ @"zStrHentaiKey":self.zStrHentaiKey, @"images":self.zMuArrayHentaiImageURLs, @"hentaiResult":self.zMuDictHentaiResults, @"hentaiInfo":self.hentaiInfo };
		[HentaiSaveLibraryArray addObject:saveInfo];
		self.zIntDownloadKey = [HentaiSaveLibraryArray indexOfObject:saveInfo];
		[self setupForAlreadyzIntDownloadKey:self.zIntDownloadKey];
		[SVProgressHUD dismiss];
	}
}

//設定下載好的相關資料
- (void)setupForAlreadyzIntDownloadKey:(NSUInteger)zIntDownloadKey {
	UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteActionOnPad)];
	self.navigationItem.rightBarButtonItem = deleteButton;
	[self.zMuArrayHentaiImageURLs setArray:HentaiSaveLibraryArray[zIntDownloadKey][@"images"]];
	[self.zMuDictHentaiResults setDictionary:HentaiSaveLibraryArray[zIntDownloadKey][@"hentaiResult"]];
	self.zIntRealDisplayCount = [self.zMuArrayHentaiImageURLs count];
	self.hentaiFilesManager = [[FilesManager documentFolder] fcd:self.zStrHentaiKey];
	//目前只需reload section:0
	[self.hentaiTableView reloadSections:[[NSIndexSet alloc]initWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.hentaiTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.zIndexPathrow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
}

//找尋是不是有下載過
- (NSUInteger)foundzIntDownloadKey {
	for (NSDictionary *eachInfo in HentaiSaveLibraryArray) {
		if ([eachInfo[@"zStrHentaiKey"] isEqualToString:self.zStrHentaiKey]) {
			return [HentaiSaveLibraryArray indexOfObject:eachInfo];
		}
	}
	return NSNotFound;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex) {
		[SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
		[self waitingOnDownloadFinish];
	}
}

#pragma mark - HentaiDownloadImageOperationDelegate

- (void)downloadResult:(NSString *)urlString heightOfSize:(CGFloat)height isSuccess:(BOOL)isSuccess {
	NSInteger zIntPage = [self.zMuArrayHentaiImageURLs indexOfObject:urlString];
	[self changeTitle];
	if (isSuccess) {
		self.zMuDictHentaiResults[[urlString lastPathComponent]] = @(height);

		NSInteger availableCount = [self availableCount];
		//		if (availableCount > self.zIntRealDisplayCount) {
		if (availableCount >= 1 && !self.zBoolIsRemovedHUD) {
			self.zBoolIsRemovedHUD = YES;
			[SVProgressHUD dismiss];
		}
		self.zIntRealDisplayCount = availableCount;
		[self.zMuDictForIndexHentaiImageURLs setObject:urlString forKey:[NSString stringWithFormat:@"%u", zIntPage + 1]];
		//		}
		//改成之接對單一cell改變
		//			[self.hentaiTableView reloadData];
		[self.hentaiTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:zIntPage + 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
		///TODO:會衝突找原因
		//			[self.hentaiTableView reloadSections:[[NSIndexSet alloc]initWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
		//			[self.hentaiTableView  selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.zIndexPathrow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
	}
	else {
		NSNumber *retryCount = self.zMuDictRetryMap[urlString];
		if (retryCount) {
			retryCount = @([retryCount integerValue] + 1);
		}
		else {
			retryCount = @(1);
		}
		self.zMuDictRetryMap[urlString] = retryCount;

		if ([retryCount integerValue] <= 3) {
			[self createNewOperation:urlString];
		}
		else {
			self.zLabelOnSectionStatus.textColor = [UIColor colorWithRed:0.913 green:0.807 blue:0.079 alpha:1.000];
			self.zIntFailCount++;
			[self.zMuDictForIndexHentaiImageURLs setObject:@"Fail" forKey:[NSString stringWithFormat:@"%u", zIntPage + 1]];
			//不刪除,self.zMuArrayHentaiImageURLs內 失敗的url
			//			self.zStrMaxHentaiCount = [NSString stringWithFormat:@"%d", [self.zStrMaxHentaiCount integerValue] - 1];
			//			[self.zMuArrayHentaiImageURLs removeObject:urlString];
			[self.zMuArrayFailHentaiImageURLs insertObject:urlString atIndex:self.zMuArrayFailHentaiImageURLs.count];
		}
	}
	[self changeTitle];
}

//改變Title(修正,目前移到TableView的Section)
- (void)changeTitle {
	// 當前頁數 / ( 可到頁數 / 已下載頁數 / 總共頁數 )已分析數量:佇列數量-錯誤數(已累積錯誤數)
	self.zLabelOnSectionStatus.text = [NSString stringWithFormat:@"當前%lu (可到%ld/ 已下%lu/ 總共%@)已分析%lu/ 佇列%u/ 錯誤%u(累積%u)", (unsigned long)self.zIndexPathrow
									   , (long)self.zIntRealDisplayCount
									   , (unsigned long)[self.zMuDictHentaiResults count]
									   , self.zStrMaxHentaiCount
									   , (unsigned long)self.zMuArrayHentaiImageURLs.count
									   , [self.zOpQueHentaiQueue operationCount]
									   , self.zMuArrayFailHentaiImageURLs.count
									   , self.zIntFailCount
									   ];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	//直接秀最大值
	return [self.zStrMaxHentaiCount integerValue] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	self.zIndexPathrow = indexPath.row;
	[self changeTitle];
	//無限滾
	if (indexPath.row >= [self.zMuArrayHentaiImageURLs count] - 15 //(20改15)
		//		&& ([self.zMuArrayHentaiImageURLs count] + self.zIntFailCount) == (self.zIntHentaiIndex + 1) * 40
		&& [self.zMuArrayHentaiImageURLs count] < [self.zStrMaxHentaiCount integerValue]
		&& self.zOpQueHentaiQueue.operationCount < 10
		) {
		self.zIntHentaiIndex++;
		[self parserRequest:NSStringFromSelector(_cmd)];
	}

	static NSString *cellIdentifier = @"HentaiPhotoCell";
	HentaiPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

	//這段暫定,到時候View會另外做一個import
	if (indexPath.row == 0) {
		cell.hentaiImageView.hidden = YES;
		cell.hentaiPageNumber.hidden = YES;
	}
	else {
		cell.hentaiImageView.hidden = NO;
		cell.hentaiPageNumber.hidden = NO;
		NSString *eachImageString;
		if ([self.zMuDictForIndexHentaiImageURLs objectForKey:[NSString stringWithFormat:@"%u", indexPath.row]]) {
			eachImageString = [self.zMuDictForIndexHentaiImageURLs objectForKey:[NSString stringWithFormat:@"%u", indexPath.row]];
		}
		NSIndexPath *copyIndexPath = [indexPath copy];
		__weak ComicViewController *weakSelf = self;

		//讀取不卡線程
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			UIImage *image;
			if (!eachImageString
				|| [eachImageString isEqualToString:@""]) {
				image = [UIImage imageNamed:@"Images/0.PNG"];
				//				image = [UIImage imageNamed:@"Images/2.jpg"];
			}
			else if ([eachImageString isEqualToString:@"Fail"]
					 || [eachImageString isEqualToString:@"(null)"]) {
				image = [UIImage imageNamed:@"Images/1.jpg"];
			}
			else {
				image = [UIImage imageWithData:[weakSelf.hentaiFilesManager read:[eachImageString lastPathComponent]]];
			}

			if ([[tableView indexPathForCell:cell] compare:copyIndexPath] == NSOrderedSame && weakSelf) {
				dispatch_async(dispatch_get_main_queue(), ^{
					cell.hentaiImageView.image = image;
					cell.hentaiImageView.contentMode = UIViewContentModeScaleAspectFit;
					cell.hentaiPageNumber.text = [NSString stringWithFormat:@"%u%@", indexPath.row, @" "];
				});
			}
		});
	}
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 70;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	self.zViewOnSectionStatus = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen]bounds].size.width, 70)];
	for (UILabel *zLabelIn in self.zViewOnSectionStatus.subviews) {
		if (zLabelIn.tag == 1001) {
			self.zLabelOnSectionStatus = (UILabel *)zLabelIn;
		}
	}
	if (!self.zLabelOnSectionStatus) {
		self.zLabelOnSectionStatus = [[UILabel alloc]initWithFrame:CGRectMake(0, 0,  [[UIScreen mainScreen]bounds].size.width, 70)];
		self.zLabelOnSectionStatus.tag = 1001;
		self.zLabelOnSectionStatus.lineBreakMode = NSLineBreakByWordWrapping;
		self.zLabelOnSectionStatus.numberOfLines = 0;
		self.zLabelOnSectionStatus.textAlignment = NSTextAlignmentCenter;
		self.zLabelOnSectionStatus.backgroundColor = [UIColor colorWithRed:0.484 green:0.582 blue:0.913 alpha:1.000];
		self.zLabelOnSectionStatus.textColor = [UIColor blackColor];
		self.zLabelOnSectionStatus.font = [UIFont systemFontOfSize:20.0f];
	}
	[self.zViewOnSectionStatus addSubview:self.zLabelOnSectionStatus];
	return self.zViewOnSectionStatus;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	[self changeTitle];
	CGSize newSize;
	NSString *eachImageString;
	if ([self.zMuDictForIndexHentaiImageURLs objectForKey:[NSString stringWithFormat:@"%u", indexPath.row]]) {
		eachImageString = [self.zMuDictForIndexHentaiImageURLs objectForKey:[NSString stringWithFormat:@"%u", indexPath.row]];
	}
	if (!eachImageString) {
		newSize.height = [[UIScreen mainScreen]bounds].size.height;
	}
	else if ([eachImageString isEqualToString:@"Fail"]) {
		newSize.height = [[UIScreen mainScreen]bounds].size.height;
	}
	else {
		//如果畫面是直向的時候, 長度要重新算
		if (self.interfaceOrientation == UIDeviceOrientationPortrait) {
			newSize = [self imagePortraitHeight:CGSizeMake([UIScreen mainScreen].bounds.size.height, [self.zMuDictHentaiResults[[eachImageString lastPathComponent]] floatValue])];
		}
		else {
			newSize.height = [self.zMuDictHentaiResults[[eachImageString lastPathComponent]] floatValue];
		}
	}
	if (newSize.height < 1) {
		newSize.height = 100;
	}
	return newSize.height;
}

#pragma mark - Configuring the View’s Layout Behavior

- (BOOL)prefersStatusBarHidden {
	return self.navigationController.navigationBarHidden;
}

#pragma mark - life cycle

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupInitValues];

	self.zIntDownloadKey = [self foundzIntDownloadKey];

	//如果本機有存檔案就用本機的
	if (self.zIntDownloadKey != NSNotFound) {
		self.zLabelOnSectionStatus.backgroundColor = [UIColor colorWithRed:0.375 green:0.838 blue:0.559 alpha:1.000];
		[self setupForAlreadyzIntDownloadKey:self.zIntDownloadKey];
	}
	//否則則從網路上取得
	else {
		self.hentaiFilesManager = [[[FilesManager cacheFolder] fcd:@"Hentai"] fcd:self.zStrHentaiKey];
		[SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
		[self parserRequest:NSStringFromSelector(_cmd)];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (!self.zBoolIsRemovedHUD) {
		[SVProgressHUD dismiss];
	}

	//結束時把 queue 清掉, 並且記錄目前已下載的東西有哪些
	[self.zOpQueHentaiQueue cancelAllOperations];
	if (self.zIntDownloadKey != NSNotFound) {
		[HentaiCacheLibraryDictionary removeObjectForKey:self.zStrHentaiKey];
	}
	else {
		HentaiCacheLibraryDictionary[self.zStrHentaiKey] = self.zMuDictHentaiResults;
	}
	LWPForceWrite();
}

@end
