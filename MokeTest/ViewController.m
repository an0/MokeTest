//
//  ViewController.m
//  MokeTest
//
//  Created by Ling Wang on 2/6/15.
//  Copyright (c) 2015 Moke. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    NSArray *_URLs;
    NSMutableSet *_connections;
    UIBackgroundTaskIdentifier _bgTask;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _URLs = @[
                  @"https://api.weibo.com/2/statuses/home_timeline.json?&count=50",
                  @"https://api.weibo.com/2/statuses/count.json?&ids=3817139716823737",
                  @"https://api.weibo.com/2/statuses/repost_timeline.json?id=3817139716823737&count=50",
                  @"https://api.weibo.com/2/comments/show.json?id=3817139716823737&count=50",
                  @"https://api.weibo.com/2/users/show.json?screen_name=an00na",
                  @"https://api.weibo.com/2/statuses/user_timeline.json?screen_name=an00na&count=50",
                  @"https://api.weibo.com/2/remind/unread_count.json?unread_message=1",
                  ];
    
    _connections = [NSMutableSet set];
    _bgTask = UIBackgroundTaskInvalid;
    
    [self sendRequests];
}

- (void)sendRequests {
    [self sendRequest:_URLs.count - 1];
    NSUInteger index = arc4random_uniform((u_int32_t)(_URLs.count - 1));
    [self sendRequest:index];
}

- (void)sendRequest:(NSUInteger)index {
    NSString *urlStr = _URLs[index];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
#warning 请指定 access token
    NSString *accessToken = @"";
    NSString *value = [NSString stringWithFormat:@"OAuth2 %@", accessToken];
    [request setValue:value forHTTPHeaderField:@"Authorization"];

    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    [_connections addObject:connection];
    
    if (_bgTask == UIBackgroundTaskInvalid) {
        _bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (_bgTask != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
                _bgTask = UIBackgroundTaskInvalid;
            }
        }];
    }
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    NSLog(@"Response %@ received", response);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Request didFailWithError: %@", error);
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorTimedOut) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    [_connections removeObject:connection];
    if (_connections.count == 0) {
        if (_bgTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
        }
        [self performSelector:@selector(sendRequests) withObject:nil afterDelay:5];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"Request didFinishLoading: %@", connection.originalRequest.URL.path);
    [_connections removeObject:connection];
    if (_connections.count == 0) {
        if (_bgTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
        }
        [self performSelector:@selector(sendRequests) withObject:nil afterDelay:10];
    }
}

@end
