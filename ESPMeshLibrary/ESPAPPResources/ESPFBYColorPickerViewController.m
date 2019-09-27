//
//  ESPFBYColorPickerViewController.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/23.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "ESPFBYColorPickerViewController.h"

#import "ESPFBYColorPicker.h"

@interface ESPFBYColorPickerViewController ()

@property(nonatomic, strong) ESPFBYColorPicker *picker;

@property(nonatomic, strong)UIButton *colorBtn;

@property(nonatomic, assign) Byte r;
@property(nonatomic, assign) Byte g;
@property(nonatomic, assign) Byte b;

@end

@implementation ESPFBYColorPickerViewController

/*! 屏幕宽度 */
static inline CGFloat ScreenWidth() {
    return [UIScreen mainScreen].bounds.size.width;
}

/*! 屏幕高度 */
static inline CGFloat ScreenHeight() {
    return [UIScreen mainScreen].bounds.size.height;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    [self showViewUI];
}

- (void)showViewUI {
    
    self.colorBtn = [[UIButton alloc]initWithFrame:CGRectMake(50, ScreenHeight() - 160, ScreenWidth() - 100, 50)];
    [self.colorBtn setTitle:@"色盘定位" forState:0];
    self.colorBtn.backgroundColor = [UIColor colorWithRed:80/255.0 green:93/255.0 blue:70/255.0 alpha:1];
    [self.colorBtn addTarget:self action:@selector(colorBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_colorBtn];
    
//    @weakify(self);
    self.picker = [ESPFBYColorPicker colorPickerWithBubbleWidth:20 completion:^(UIColor *color) {
//        @strongify(self);
        
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        self.b = components[2] * 255;
        self.g = components[1] * 255;
        self.r = components[0] * 255;
        NSLog(@"%@", color);
        NSLog(@"red:%x\ngreen:%x\nblue:%x",_r,_g,_b);
        self.colorBtn.backgroundColor = [UIColor colorWithRed:_r/255.0 green:_g/255.0 blue:_b/255.0 alpha:1];
//        self.view.backgroundColor = color;
    }];
    self.picker.frame = CGRectMake((ScreenWidth() - 300)/2, 100, 300, 300);
    [self.view addSubview:self.picker];
    
}

- (void)colorBtn:(UIButton *)sender {
    UIColor *color = [UIColor colorWithRed:80/255.0 green:93/255.0 blue:70/255.0 alpha:1];
    [self.picker changeColor:color];
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
