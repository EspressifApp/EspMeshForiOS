//
//  ESPNewWebViewController.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/27.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPNewWebViewController.h"

#import "ESPFBYDataBase.h"

#import "ESPFBYLocalAPI.h"
#import "ESPFBYAliyunAPI.h"
#import "FBYBallLoading.h"

@interface ESPNewWebViewController ()<UIWebViewDelegate,ESPFBYLocalAPIDelegate,ESPFBYAliyunAPIDelegate> {
    
    NSString* username;
    BabyBluetooth *babys;
}
@property (weak,nonatomic) UIWebView *webView;
@property (strong,nonatomic) JSContext *context;
@property (strong, nonatomic)JSValue *callbacks;

@end

@implementation ESPNewWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self settingUi];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self functionInit];
    });
}

- (void)functionInit {
    ESPFBYLocalAPI *espLocalAPI = [ESPFBYLocalAPI share];
    espLocalAPI.delegate = self;
    ESPFBYAliyunAPI *espAliyunAPI = [ESPFBYAliyunAPI share];
    espAliyunAPI.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layOutControllerViews) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    //设备状态变化监视
    [espLocalAPI deviceStatusChangeMonitoring];
}

- (void)layOutControllerViews {
    NSString *htmlName = @"WebUI/app";
    NSString *pageName = [ESPDataConversion fby_getNSUserDefaults:@"mainPageLoad"];
    if (![ESPDataConversion isNull:pageName]) {
        htmlName = [NSString stringWithFormat:@"WebUI/%@",pageName];
    }
    [self webViewLoadingVC:htmlName];
}

#pragma mark - 自定义方法
- (void)settingUi
{
    username=@"guest";
    [ESPFBYDataBase espDataBaseInit:username];
    self.view.backgroundColor = [UIColor whiteColor];
    NSString *htmlName = @"WebUI/app";
    NSString *pageName = [ESPDataConversion fby_getNSUserDefaults:@"mainPageLoad"];
    if (![ESPDataConversion isNull:pageName]) {
        htmlName = [NSString stringWithFormat:@"WebUI/%@",pageName];
    }
    [self webViewLoadingVC:htmlName];
    
}

- (void)webViewLoadingVC:(NSString *)htmlName {
    CGRect rectOfStatusbar = [[UIApplication sharedApplication] statusBarFrame];
    UIWebView * webView;
    if (rectOfStatusbar.size.height == 44) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-34)];
    }else {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    }
    webView.backgroundColor = [UIColor colorWithRed:62/255.0 green:194/255.0 blue:252/255.0 alpha:1];
    webView.delegate = self;
    webView.scrollView.bounces=false;
    [self.view addSubview:webView];
    [_webView removeFromSuperview];
    _webView=webView;
    _webView.scrollView.scrollEnabled = NO;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:htmlName ofType:@"html"]]]];
    [FBYBallLoading showInView:self.view];
}
//发送消息给JS
- (void)sendMsg:(NSString *)methodName param:(id)params {
    if ([methodName isEqualToString:@"(null)"]) {
        return;
    }
    if (![methodName  isEqual: @"onScanBLE"]) {
        NSLog(@"app---->JS method:%@,params:%@",methodName,params);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        JSValue *callback = self.context[methodName];
        NSMutableArray *resultArr = [NSMutableArray arrayWithCapacity:0];
        [resultArr addObject:params];
        [callback callWithArguments:resultArr];
    });
}

#pragma mark - <UIWebViewDelegate>代理方法
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //从webview上获取相应的JSContext。
    self.context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    //设置异常处理
    self.context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        [JSContext currentContext].exception = exception;
        NSLog(@"context JS异常:%@",exception);
    };
    self.context = [[ESPFBYLocalAPI share] getLocalJSContext:_context withLocalVC:self];
    self.context = [[ESPFBYAliyunAPI share] getAliyunJSContext:_context withAliyunVC:self];
}

#pragma mark - <ESPFBYLocalAPIDelegate>代理方法
- (void)hideGuidePageView {
    dispatch_async(dispatch_get_main_queue(), ^(){
        [FBYBallLoading hideInView:self.view];
    });
}
- (void)sendLocalMsg:(NSString *)methodName param:(id)params {
    [self sendMsg:methodName param:params];
}
- (void)webViewLoadMainPage:(NSString *)loadPageName {
    NSString *htmlName = [NSString stringWithFormat:@"WebUI/%@",loadPageName];
    [self webViewLoadingVC:htmlName];
}

#pragma mark - <ESPFBYAliyunAPIDelegate>代理方法
- (void)sendAliyunMsg:(NSString *)methodName param:(id)params {
    [self sendMsg:methodName param:params];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:true];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:false];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
