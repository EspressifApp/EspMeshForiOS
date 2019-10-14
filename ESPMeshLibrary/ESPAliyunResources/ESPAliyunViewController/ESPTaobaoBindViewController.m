//
//  ESPTaobaoBindViewController.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/10/9.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "ESPTaobaoBindViewController.h"
#import <WebKit/WebKit.h>

@interface ESPTaobaoBindViewController ()<WKUIDelegate, WKNavigationDelegate>

@end

@implementation ESPTaobaoBindViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self viewUI];
}

- (void)viewUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGRect rectOfStatusbar = [[UIApplication sharedApplication] statusBarFrame];
    WKWebView * webView;
    if (rectOfStatusbar.size.height == 40) {
        webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-20)];
    }else {
        webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    }
    webView.navigationDelegate = self;//代理：WKNavigationDelegate
    [self.view addSubview:webView];
    NSString *appKey = @"26045889";
    NSString *blockUrl = @"https://www.espressif.com/en/products/software/esp-mesh/overview";
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://oauth.taobao.com/authorize?response_type=code&client_id=%@&redirect_uri=%@&view=wap", appKey,blockUrl]]]];
    
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSRange range = [navigationAction.request.URL.absoluteString rangeOfString:@"https://www.espressif.com/en/products/software/esp-mesh/overview"];
    NSLog(@"%@",navigationAction.request.allHTTPHeaderFields);
    NSLog(@"%lu",(unsigned long)range.location);
    if (range.location){
        //允许跳转
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        //不允许跳转
        decisionHandler(WKNavigationActionPolicyCancel);
        NSURLComponents *components = [NSURLComponents componentsWithString:navigationAction.request.URL.absoluteString];
        
        for (NSURLQueryItem *item in components.queryItems){
            if ([item.name isEqualToString:@"code"]){
                //用户绑定淘宝ID请求
                [IMSTmallSpeakerApi bindTaobaoIdWithParams:@{@"authCode":item.value} completion:^(NSError *err, NSDictionary *result) {
                    NSLog(@"err: %@\n result: %@",err, result);
                    [self.delegate userTaobaoBindWithResult:result error:err];
                    //                    if (self.completion){
                    //                        self.completion(err, result);
                    //                    }
                    [self.navigationController popViewControllerAnimated:YES];
                }];
                break;
            }
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
