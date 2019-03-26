//
//  ViewController.m
//  iOSMultithreadingDemo
//
//  Created by 杨永杰 on 2019/3/25.
//  Copyright © 2019年 杨永杰. All rights reserved.
//

#import "ViewController.h"
#import "GCDController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSArray <NSString *>*titlesArray;

@end

static NSString *cellId = @"cellId";

@implementation ViewController

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.titlesArray = @[@"NSThread", @"GCD", @"NSOperation"];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:cellId];
}


#pragma mark - tableView delegate & datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.titlesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    cell.textLabel.text = self.titlesArray[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GCDController *gcd  = [[GCDController alloc] init];
    [self.navigationController pushViewController:gcd animated:YES];
}
@end
