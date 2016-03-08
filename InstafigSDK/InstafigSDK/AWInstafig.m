//
//  AWInstafig.m
//  InstafigSDK
//
//  Created by shy on 16/3/4.
//  Copyright © 2016年 AppTao. All rights reserved.
//

#import "AWInstafig.h"
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>

#pragma mark - Default Server Host
static NSString * const AWIDefaultServerHost = @"http://beijing5.appdao.com:17070";

#pragma mark - key
static NSString * const keyAWIAppKey = @"keyAWIAppKey";
static NSString * const keyAWIDataSign = @"keyAWIDataSign";
static NSString * const keyAWIAppConfig = @"keyAWIAppConfig";
static NSString * const keyAWINodes = @"keyAWINodes";
static NSString *const keyAWInstafigLastUpdateDate = @"keyAWInstafigLastUpdateDate";

NSString *const AWInstafigConfLoadSucceedNotification = @"AWInstafigConfLoadSucceedNotification";
NSString *const AWInstafigConfLoadFailedNotification = @"AWInstafigConfLoadFailedNotification";

@interface AWInstafig ()

@property (strong, nonatomic) NSDictionary *configDict;
@property (nonatomic, strong) NSMutableArray *nodeList;
@property (nonatomic, strong) NSUserDefaults *instafigDefaults;
@property (nonatomic, assign) NSUInteger currentTryCount;
@property (nonatomic, assign) NSUInteger maxRetryCount;

@end

@implementation AWInstafig

+ (AWInstafig *)sharedInstance {
    static AWInstafig *sharedInstafig = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        sharedInstafig = [[AWInstafig alloc] init];
    });
    
    return sharedInstafig;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.instafigDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"AWIInstafigDefaults"];
        self.maxRetryCount = 2;
        self.currentTryCount = 0;
    }
    return self;
}

- (void)startWithAppKey:(NSString*)appKey {
    if (appKey && appKey.length) {
        [self.instafigDefaults setObject:appKey forKey:keyAWIAppKey];
        [self.instafigDefaults synchronize];
    }
    [self retryUpdateConf];
}

- (NSDate *)lastUpdateTime {
    double time  = [self.instafigDefaults doubleForKey:keyAWInstafigLastUpdateDate];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    
    return date;
}

- (void)update {
    [self retryUpdateConf];
}

- (void)getAppConfigurationWithServerHost:(NSString *)serverHost {
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    __weak typeof(self) wself = self;
    NSURLSessionDataTask *task = [session dataTaskWithURL:[self confUrlWithServerHost:serverHost] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [wself performSelector:@selector(retryUpdateConf) withObject:nil afterDelay:5];
        } else {
            NSDate *now = [NSDate date];
            NSTimeInterval timeNow = [now timeIntervalSince1970];
            [wself.instafigDefaults setObject:@(timeNow) forKey:keyAWInstafigLastUpdateDate];
            [wself.instafigDefaults synchronize];
            if (data) {
                id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                if (result && [result isKindOfClass:[NSDictionary class]] && result[@"data"] && [result[@"data"] isKindOfClass:[NSDictionary class]]) {
                    [wself saveConfiguration:result[@"data"]];
                    wself.currentTryCount = 0;
                    [[NSNotificationCenter defaultCenter] postNotificationName:AWInstafigConfLoadSucceedNotification object:result[@"data"]];
                }
            }
        }
    }];
    [task resume];
}

- (void)retryUpdateConf {
    if (!(self.nodeList && self.nodeList.count) && self.currentTryCount < self.maxRetryCount) {
        self.currentTryCount ++;
        NSArray *nodes = [self.instafigDefaults objectForKey:keyAWINodes];
        if (nodes && [nodes count]) {
            self.nodeList = [NSMutableArray arrayWithArray:nodes];
        } else {
            self.nodeList = [@[AWIDefaultServerHost] mutableCopy];
        }
    }
    NSString *server = [self serverHostWithHttpScheme:[self.nodeList firstObject]];
    if (!(server && [server length])) {
        self.currentTryCount = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:AWInstafigConfLoadFailedNotification object:nil];
        return;
    }
    [self getAppConfigurationWithServerHost:server];
    if (self.nodeList.count) {
        [self.nodeList removeObjectAtIndex:0];
    }
}

- (NSString *)stringForKey:(NSString *)key default:(NSString *)defaultValue {
    id obj = [self objectForKey:key];
    if (obj && obj != nil && [obj isKindOfClass:[NSString class]]) {
        return (NSString *)obj;
    }
    
    return defaultValue;
}

- (long)integerForKey:(NSString *)key default:(long)defaultValue {
    id obj = [self objectForKey:key];
    if (obj && ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]])) {
        return [obj longValue];
    }
    
    return defaultValue;
}

- (double)doubleForKey:(NSString *)key default:(double)defaultValue {
    id obj = [self objectForKey:key];
    if (obj && ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]])) {
        return [obj doubleValue];
    }
    
    return defaultValue;
}

#pragma mark - Private method

- (void)saveConfiguration:(NSDictionary *)confDic {
    if (confDic[@"configs"] && [confDic[@"configs"] isKindOfClass:[NSDictionary class]] && [confDic[@"configs"] count]) {
        [self.instafigDefaults setObject:confDic[@"configs"] forKey:keyAWIAppConfig];
    }
    if (confDic[@"data_sign"] && [confDic[@"data_sign"] isKindOfClass:[NSString class]] && [confDic[@"data_sign"] length]) {
        [self.instafigDefaults setObject:confDic[@"data_sign"] forKey:keyAWIDataSign];
    }
    if (confDic[@"nodes"] && [confDic[@"nodes"] isKindOfClass:[NSArray class]] && [confDic[@"nodes"] count]) {
        NSArray *nodes = [NSArray arrayWithArray:confDic[@"nodes"]];
        [self randamArry:nodes];
        [self.instafigDefaults setObject:nodes forKey:keyAWINodes];
    }
    
    [self.instafigDefaults synchronize];
}

- (id)objectForKey:(NSString *)key
{
    if (self.configDict == nil) {
        NSUserDefaults *userDefaults = self.instafigDefaults;
        id dict_obj = [userDefaults objectForKey:keyAWIAppConfig];
        if (dict_obj && [dict_obj isKindOfClass:[NSDictionary class]]) {
            self.configDict = (NSDictionary *)dict_obj;
        }
    }
    
    if (self.configDict) {
        return [self.configDict objectForKey:key];
    }
    
    return nil;
}

- (NSURL *)confUrlWithServerHost:(NSString *)serverHost {
    NSString *dataSign = [self.instafigDefaults objectForKey:keyAWIDataSign];
    NSString *appKey = [self.instafigDefaults objectForKey:keyAWIAppKey];
    NSString *deviceType = @"ios";
    NSString *deviceVersion = [[UIDevice currentDevice] systemVersion];
    NSString *appVersion = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSString *language = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];
    NSString *deviceID = ([self isVersionSupport:@"6.0"] && [[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) ? [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString] : @"NA";
    NSString *urlString = [NSString stringWithFormat:@"%@/client/config?data_sign=%@&app_key=%@&os_type=%@&os_version=%@&app_version=%@&lang=%@&device_id=%@", serverHost, dataSign, appKey, deviceType, deviceVersion, appVersion, language, deviceID];
    return [NSURL URLWithString:urlString];
}

- (void)randamArry:(NSArray *)arry
{
    arry = [arry sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        int seed = arc4random_uniform(2);
        
        if (seed) {
            return [str1 compare:str2];
        } else {
            return [str2 compare:str1];
        }
    }];
}

- (NSString *)serverHostWithHttpScheme:(NSString *)serverHost {
    if (serverHost && serverHost.length) {
        if (![serverHost containsString:@"http://"]) {
            return [NSString stringWithFormat:@"http://%@", serverHost];
        }
    }
    return serverHost;
}

- (BOOL)isVersionSupport:(NSString *)reqSysVer {
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    return osVersionSupported;
}

@end