//
//  ESPLoadHyperlinksViewController.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/5/7.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "ESPLoadHyperlinksViewController.h"
#import<WebKit/WebKit.h>

#define kWidth [[UIScreen mainScreen] bounds].size.width
#define kHeight [[UIScreen mainScreen] bounds].size.height

//#define IS_IPHONE_X (kHeight >= 812.0f) ? YES : NO
//#define StatusBar (IS_IPHONE_X==YES)?44.0f: 20.0f

#define StatusBar [UIApplication sharedApplication].statusBarFrame.size.height


@interface ESPLoadHyperlinksViewController ()
@property(nonatomic,strong)UIWebView *webView;
@end

@implementation ESPLoadHyperlinksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:181/255.0 green:181/255.0 blue:186/255.0 alpha:1];
    
    UIView *tabbarView = [[UIView alloc]initWithFrame:CGRectMake(0, StatusBar, kWidth, 50)];
    tabbarView.backgroundColor = [UIColor colorWithRed:62/255.0 green:194/255.0 blue:252/255.0 alpha:1];
    [self.view addSubview:tabbarView];
    
    UILabel *titLabel = [[UILabel alloc]initWithFrame:CGRectMake(kWidth/2 - 50, 0, 100, 50)];
    titLabel.text = @"ESPRESSIF";
    titLabel.textColor = [UIColor whiteColor];
    titLabel.textAlignment = NSTextAlignmentCenter;
    [tabbarView addSubview:titLabel];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(5, 3, 44, 44);
    [btn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backAction)
  forControlEvents:UIControlEventTouchUpInside];
    btn.titleLabel.font = [UIFont systemFontOfSize:15];
    [btn setTitleColor:[UIColor blackColor]  forState:UIControlStateNormal];
    [tabbarView addSubview:btn];
    
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, StatusBar + 50, kWidth, kHeight - StatusBar - 50)];
    [self.view addSubview:self.webView];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.webURL]]];
}

- (void)backAction{
    [self dismissViewControllerAnimated:YES completion:nil];
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
