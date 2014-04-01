//
//  DemoViewController.m
//  CollectionViewDragOperation
//
//  Created by FFF on 14-3-31.
//  Copyright (c) 2014年 Liu Zhuang. All rights reserved.
//

#import "DemoViewController.h"

@interface DemoViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray   *items;
@property (nonatomic, strong) NSMutableArray   *categories;

@property (nonatomic, assign) CGPoint   sourcePosition;

@property (nonatomic, strong) UIView *sideView;

@end

@implementation DemoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.items = [[NSMutableArray alloc] init];
    for (int i = 0; i < 100; i++) {
        
        [self.items addObject:@(i)];
        
    }
    self.view.backgroundColor = [UIColor whiteColor];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(80, 80);
    flowLayout.sectionInset = UIEdgeInsetsMake(4, 4, 4, 4);
    flowLayout.minimumLineSpacing = 8;
    flowLayout.minimumInteritemSpacing = 4;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 200, self.view.frame.size.height) collectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [self.view addSubview:_collectionView];
    
    self.sideView = [[UIView alloc] initWithFrame:CGRectMake(200, 0, 120, self.view.frame.size.height)];
    self.sideView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.sideView];
    
    self.categories = [NSMutableArray array];
    CGSize itemSize = CGSizeMake(100, 100);
    for (int i = 0; i < 5; i ++) {
        NSInteger x = 10;
        NSInteger y = 10 + i * (itemSize.height + 10);
        CGRect itemFrame = {x, y, itemSize};
        UIView *item = [[UIView alloc] initWithFrame:itemFrame];
        item.backgroundColor = [UIColor redColor];
        [self.sideView addSubview:item];
        
        [self.categories addObject:item];
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.collectionView addGestureRecognizer:longPress];
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.collectionView];
    NSUInteger state = gesture.state;
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    
    static UIView *snapshot = nil;
    static NSIndexPath *sourceIndexPath = nil;

    switch (state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath) {
                sourceIndexPath = indexPath;
                UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
                _sourcePosition = [self.view convertPoint:cell.center fromView:self.collectionView];
                NSLog(@"sourceCenter = %@", NSStringFromCGPoint(cell.center));
                CGPoint center = [self.view convertPoint:cell.center fromView:self.collectionView];
                snapshot = [self customSnapshotInView:cell];
                snapshot.alpha = 0.0;
                snapshot.center = center;
                [self.view addSubview:snapshot];
                [self.view bringSubviewToFront:snapshot];
                
                [UIView animateWithDuration:0.25 animations:^{
                    snapshot.center = [self.view convertPoint:location fromView:self.collectionView];
                    snapshot.alpha = 0.8;
                    snapshot.transform = CGAffineTransformMakeScale(1.1, 1.1);
                }];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            snapshot.center = [self.view convertPoint:location fromView:self.collectionView];
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:sourceIndexPath];
            NSLog(@"Center : %@", NSStringFromCGPoint([self.view convertPoint:cell.center fromView:self.collectionView]));
            NSLog(@"ACenter : %@", NSStringFromCGPoint(snapshot.center));
            break;
        }
        case UIGestureRecognizerStateEnded: {
            //inWhichCategory
            UIView *targetCategory = [self targetCategoryForTheItem:snapshot];
            if (targetCategory) {
                NSLog(@"yes");
                //shakeThatCategory
                [self shakenAView:targetCategory];
                [self remove:sourceIndexPath];
                snapshot.alpha = 0;
                [snapshot removeFromSuperview];
                //数据处理
            } else {
                NSLog(@"NO");

                [UIView animateWithDuration:0.25 animations:^{
                    snapshot.center = _sourcePosition;
//                    snapshot.alpha = 0;
                    snapshot.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                    [snapshot removeFromSuperview];
                }];
            }
            break;
        }
            
        default:
            break;
    }
}

-(void)remove:(NSIndexPath *)indexPath {
    
    __weak typeof(self) bself = self;
    [self.collectionView performBatchUpdates:^{
        __strong DemoViewController *wself = bself;
        [wself.items removeObjectAtIndex:indexPath.item];
        [wself.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)shakenAView:(UIView *)view {
    
    CGPoint leftPoint = CGPointMake(view.center.x - 3, view.center.y);
    CGPoint rightPoint = CGPointMake(view.center.x + 3, view.center.y);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, view.center.x, view.center.y);
    CGPathAddLineToPoint(path, NULL, leftPoint.x, leftPoint.y);
    CGPathAddLineToPoint(path, NULL, rightPoint.x, rightPoint.y);
    CGPathAddLineToPoint(path, NULL, leftPoint.x, rightPoint.y);
    CGPathAddLineToPoint(path, NULL, view.center.x, view.center.y);
    
    CAKeyframeAnimation *shakeAni = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    shakeAni.path = path;
    shakeAni.duration = 0.3;
    
    
    [view.layer addAnimation:shakeAni forKey:nil];
}
- (UIView *)customSnapshotInView:(UIView *)inview {
    UIView *snapshot = [inview snapshotViewAfterScreenUpdates:YES];
    snapshot.layer.shadowColor = [UIColor grayColor].CGColor;
    snapshot.layer.shadowOffset = CGSizeMake(3, 3);
    snapshot.layer.shadowRadius = 3;
    snapshot.layer.cornerRadius = 0;
    snapshot.layer.shadowOpacity = 0.5;
    
    return inview;
}

- (UIView *)targetCategoryForTheItem:(UIView *)item {
    __block UIView *targetView = nil;
    [self.categories enumerateObjectsUsingBlock:^(UIView *category, NSUInteger idx, BOOL *stop) {
        CGRect frame = [self.view convertRect:category.frame fromView:self.sideView];
        if (CGRectContainsPoint(frame, item.center)) {
            targetView = category;
            *stop = YES;
        }
    }];
    
    return targetView;
}


#pragma mark - UICollectionViewDelegate & UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor blackColor];
    
    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
