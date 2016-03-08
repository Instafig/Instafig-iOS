//
//  ViewController.m
//  InstafigSDKDemo
//
//  Created by shy on 16/3/8.
//  Copyright © 2016年 AppTao. All rights reserved.
//

#import "ViewController.h"
#import "AWInstafig.h"

static NSString *const AWInstafigLoadingHint = @"Loading Configuration...";
static NSString *const AWInstafigLoadedHint = @"Load Configuration Succeed";
static NSString *const AWInstafigLoadFailed = @"Load Configuration Failed";
static NSString *const AWInstafigConfCellIdentifier = @"AWInstafigConfCellIdentifier";

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *loadHint;
@property (nonatomic, strong) NSArray *confList;
@property (nonatomic, strong) UITextField *appKeyField;

@end

@implementation ViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printConf:) name:AWInstafigConfLoadSucceedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(losdConfFailed:) name:AWInstafigConfLoadFailedNotification object:nil];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor colorWithRed:237/255. green:237/255. blue:247/255. alpha:1.];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableHeaderView = [self createTableHeaderView];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:AWInstafigConfCellIdentifier];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)printConf:(NSNotification *)notification {
    if (notification.object && [notification.object isKindOfClass:[NSDictionary class]]) {
        [self filterConfData:notification.object];
        [self.tableView reloadData];
    }
    self.loadHint.text = AWInstafigLoadedHint;
}

- (void)losdConfFailed:(NSNotification *)notification {
    self.loadHint.text = AWInstafigLoadFailed;
}

- (void)filterConfData:(NSDictionary *)dic {
    NSMutableArray *confsList = [[NSMutableArray alloc] init];
    for (NSString *key in [dic allKeys]) {
        NSMutableArray *list = [[NSMutableArray alloc] init];
        if (dic[key] && [dic[key] isKindOfClass:[NSDictionary class]]) {
            for (NSString *innerKey in dic[key]) {
                NSString *content = nil;
                if (dic[key][innerKey] && ([dic[key][innerKey] isKindOfClass:[NSString class]] || [dic[key][innerKey] isKindOfClass:[NSNumber class]])) {
                    content = [NSString stringWithFormat:@"%@: %@", innerKey, dic[key][innerKey]];
                }
                [list addObject:content];
            }
        } else if (dic[key] && [dic[key] isKindOfClass:[NSString class]]) {
            [list addObject:dic[key]];
        } else if (dic[key] && [dic[key] isKindOfClass:[NSArray class]]) {
            [list addObjectsFromArray:dic[key]];
        }
        [confsList addObject:@{@"title": key, @"list": list}];
    }
    self.confList = [NSArray arrayWithArray:confsList];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.confList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dic = self.confList[section];
    
    return [dic[@"list"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AWInstafigConfCellIdentifier forIndexPath:indexPath];
    NSDictionary *dic = self.confList[[indexPath section]];
    NSArray *list = dic[@"list"];
    cell.textLabel.text = list[[indexPath row]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, CGRectGetWidth(tableView.bounds) - 10, 30)];
    title.backgroundColor = [UIColor colorWithRed:237/255. green:237/255. blue:247/255. alpha:1.];
    title.textAlignment = NSTextAlignmentLeft;
    title.textColor = [UIColor colorWithRed:89/255. green:89/255. blue:89/255. alpha:1];
    title.font = [UIFont systemFontOfSize:16];
    NSDictionary *dic = self.confList[section];
    title.text = [NSString stringWithFormat:@"    %@", dic[@"title"]];
    
    return title;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text && textField.text.length) {
        [[AWInstafig sharedInstance] startWithAppKey:textField.text];
        self.loadHint.text = AWInstafigLoadingHint;
        [textField resignFirstResponder];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Create View

- (UIView *)createTableHeaderView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 100)];
    headerView.backgroundColor = [UIColor whiteColor];
    
    CGFloat x = 0;
    CGFloat y = 0;
    self.loadHint = [[UILabel alloc] initWithFrame:CGRectMake(x, y, CGRectGetWidth(headerView.bounds), 50)];
    self.loadHint.backgroundColor = [UIColor whiteColor];
    self.loadHint.font = [UIFont boldSystemFontOfSize:16];
    self.loadHint.textColor = [UIColor colorWithRed:89/255. green:89/255. blue:89/255. alpha:1];
    self.loadHint.textAlignment = NSTextAlignmentCenter;
    self.loadHint.text = AWInstafigLoadingHint;
    [headerView addSubview:self.loadHint];
    
    x = (CGRectGetWidth(headerView.bounds) - 240)/2;
    y = 60;
    self.appKeyField = [[UITextField alloc] initWithFrame:CGRectMake(x, y, 240, 30)];
    self.appKeyField.delegate = self;
    self.appKeyField.textAlignment = NSTextAlignmentCenter;
    self.appKeyField.textColor = [UIColor colorWithRed:89/255. green:89/255. blue:89/255. alpha:1];
    self.appKeyField.font = [UIFont systemFontOfSize:16];
    self.appKeyField.placeholder = @"Insert Your AppKey";
    [headerView addSubview:self.appKeyField];
    
    return headerView;
}

@end
