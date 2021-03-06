//
//  WTUserNotificationViewController.m
//  v2ex
//
//  Created by 无头骑士 GJ on 16/7/25.
//  Copyright © 2016年 无头骑士 GJ. All rights reserved.
//  通知控制器

#import "WTUserNotificationViewController.h"
#import "NetworkTool.h"
#import "WTRefreshAutoNormalFooter.h"
#import "WTRefreshNormalHeader.h"
#import "WTLoginViewController.h"
#import "WTNotificationCell.h"
#import "WTTopicViewModel.h"
#import "WTTopicDetailViewController.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import "WTAccountViewModel.h"
#import "WTNotificationViewModel.h"


static NSString * const ID = @"notificationCell";

@interface WTUserNotificationViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, WTNotificationCellDelegate>
/** 回复消息ViewModel */
@property (nonatomic, strong) WTNotificationViewModel          *notificationVM;
/** 请求地址 */
@property (nonatomic, strong) NSString                         *urlString;
/** 页数*/
@property (nonatomic, assign) NSInteger                        page;

@end

@implementation WTUserNotificationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.title = @"提醒";
    
    self.tableView.tableFooterView = [UIView new];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // iOS8 以后 self-sizing
    self.tableView.estimatedRowHeight = 96;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    // 注册cell
    [self.tableView registerNib: [UINib nibWithNibName: NSStringFromClass([WTNotificationCell class]) bundle: nil] forCellReuseIdentifier: ID];
    
    self.notificationVM = [WTNotificationViewModel new];
    
    // 1、添加下拉刷新、上拉刷新
    self.tableView.mj_header = [WTRefreshNormalHeader headerWithRefreshingTarget: self refreshingAction: @selector(loadNewData)];
    self.tableView.mj_footer = [WTRefreshAutoNormalFooter footerWithRefreshingTarget: self refreshingAction: @selector(loadOldData)];
    
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    // 2、登陆过
    if ([[WTAccountViewModel shareInstance] isLogin])
    {
        // 2、开始下拉刷新
        [self.tableView.mj_header beginRefreshing];
    }
}

#pragma mark - 加载数据
#pragma mark 加载最新的数据
- (void)loadNewData
{
    
    self.notificationVM.page = 1;
    
    [self.notificationVM getUserNotificationsSuccess:^{
        
        [self.tableView reloadData];
        
        [self.tableView.mj_header endRefreshing];
        
    } failure:^(NSError *error) {
        [self.tableView.mj_header endRefreshing];
    }];
}

#pragma mark 加载旧的数据
- (void)loadOldData
{
    if (self.notificationVM.isNextPage)
    {
        self.notificationVM.page ++;
        
        [self.notificationVM getUserNotificationsSuccess:^{
            
            [self.tableView reloadData];
            
            [self.tableView.mj_footer endRefreshing];
            
        } failure:^(NSError *error) {
            [self.tableView.mj_footer endRefreshing];
        }];
    }
    else
    {
        [self.tableView.mj_footer endRefreshing];
    }
}
#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notificationVM.notificationItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    WTNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier: ID];
    
    cell.noticationItem = self.notificationVM.notificationItems[indexPath.row];
    
    cell.delegate = self;
    
    return cell;
}

#pragma mark - Table view data source
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WTTopicDetailViewController *topDetailVC = [WTTopicDetailViewController new];
    topDetailVC.topicDetailUrl = self.notificationVM.notificationItems[indexPath.row].detailUrl;
    [self.navigationController pushViewController: topDetailVC animated: YES];
}

#pragma mark - WTNotificationCellDelegate
- (void)notificationCell:(WTNotificationCell *)notificationCell didClickWithNoticationItem:(WTNotificationItem *)noticationItem
{
    __weak typeof(self) weakSelf = self;
    // 删除通知
    [self.notificationVM deleteNotificationByNoticationItem: noticationItem success:^{
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow: [weakSelf.notificationVM.notificationItems indexOfObject: noticationItem] inSection: 0];
        
        [weakSelf.notificationVM.notificationItems removeObject: noticationItem];
        [weakSelf.tableView deleteRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationMiddle];
        
//        if (weakSelf.notificationVM.notificationItems.count == 0)
//        {
//            [weakSelf.tableView reloadData];
//        }
        
    } failure:^(NSError *error) {
        
    }];
}

#pragma mark - DZNEmptyDataSetSource
- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"icon"];
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject: [UIColor greenColor] forKey: NSForegroundColorAttributeName];
    
    return [[NSAttributedString alloc] initWithString: @"登录" attributes: dict];
}

#pragma mark - DZNEmptyDataSetDelegate
- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button
{
    [self presentViewController: [WTLoginViewController new] animated: YES completion: nil];
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    if ([[WTAccountViewModel shareInstance] isLogin])
    {
        return false;
    }
    return true;
}

@end
