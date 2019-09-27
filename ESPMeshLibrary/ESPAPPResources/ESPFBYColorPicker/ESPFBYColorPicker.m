//
//  ESPFBYColorPicker.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/23.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "ESPFBYColorPicker.h"

@interface ESPFBYColorPicker ()

@property(nonatomic, copy) CAShapeLayer *bubbleLayer;
@property(nonatomic) CGFloat bubbleWidth;
@property(nonatomic, copy) void (^Complention) (UIColor *color);

@property(nonatomic) CGFloat hue;
@property(nonatomic) CGFloat saturation;

@end

@implementation ESPFBYColorPicker

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        _bubbleLayer = [CAShapeLayer layer];
        _bubbleLayer.strokeColor = [UIColor whiteColor].CGColor;
        _bubbleLayer.lineWidth = 2.f;
        _bubbleLayer.fillColor = [UIColor redColor].CGColor;
        _bubbleLayer.backgroundColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:_bubbleLayer];
    }
    return self;
}

- (void)setBubbleWidth:(CGFloat)bubbleWidth {
    _bubbleWidth = bubbleWidth;
    _bubbleLayer.frame = CGRectMake(0, 0, _bubbleWidth, _bubbleWidth);
    CGPathRef bubblePath = CGPathCreateWithEllipseInRect(CGRectMake(0, 0, _bubbleWidth, _bubbleWidth), 0);
    _bubbleLayer.shadowOffset = CGSizeMake(0, 4);
    _bubbleLayer.shadowColor = UIColor.blackColor.CGColor;
    _bubbleLayer.shadowOpacity = 0.5;
    _bubbleLayer.path = bubblePath;
    CGPathRelease(bubblePath);
}

- (UIColor *)selectedColor {
    return [UIColor colorWithHue:_hue saturation:_saturation brightness:1 alpha:1];
}

- (void)changeColor:(UIColor *)color {
    if (!color) {
        return;
    }
    CGFloat h,s,b;
    if ([color getHue:&h saturation:&s brightness:&b alpha:NULL]) {
        _hue = h;
        _saturation = s;
        [self configBubbleAnimated:YES];
    }
}

+ (instancetype)colorPickerWithBubbleWidth:(CGFloat)bubbleWidth completion:(void (^)(UIColor *))complention {
    ESPFBYColorPicker *picker = ESPFBYColorPicker.new;
    picker.Complention = complention;
    picker.bubbleWidth = bubbleWidth;
    return picker;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self configBubbleAnimated:NO];
}

- (void)configBubbleAnimated:(BOOL)animated {
    CGPoint center = CGPointMake(floorf(self.bounds.size.width / 2.f), floorf(self.bounds.size.height / 2.f));
    CGFloat radius = floorf(self.bounds.size.width / 2.f);
    
    [CATransaction begin];
    if (!animated) {
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    }
    
    CGFloat angle = 2 * M_PI * (1 - _hue);
    CGFloat saturationRadius = radius * _saturation;
    CGPoint point = CGPointMake(center.x + saturationRadius * cosf(angle), center.y + saturationRadius * sinf(angle));
    
    _bubbleLayer.position = CGPointMake(point.x, point.y);
    _bubbleLayer.fillColor = [UIColor colorWithHue:_hue saturation:_saturation brightness:1 alpha:1].CGColor;
    [CATransaction commit];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    [self sendActionForColorAtPoint:[touch locationInView:self]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    [self sendActionForColorAtPoint:[touch locationInView:self]];
}

- (void)sendActionForColorAtPoint:(CGPoint)point {
    CGPoint center = CGPointMake(floorf(self.bounds.size.width/2.0f), floorf(self.bounds.size.height/2.0f));
    CGFloat radius = floorf(self.bounds.size.width/2.0f);
    
    CGFloat dx = point.x - center.x;
    CGFloat dy = point.y - center.y;
    
    CGFloat touchRadius = sqrtf(powf(dx, 2)+powf(dy, 2));
    if (touchRadius > radius) {
        _saturation = 1.f;
    }
    else {
        _saturation = touchRadius / radius;
    }
    
    CGFloat angleRad = atan2f(dx, dy);
    CGFloat angleDeg = (angleRad * (180.0f/M_PI) - 90);
    if (angleDeg < 0.f) {
        angleDeg += 360.f;
    }
    _hue = angleDeg / 360.0f;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self configBubbleAnimated:NO];
    if (self.Complention) {
        self.Complention(self.selectedColor);
    }
}

#pragma mark - 绘制颜色图片及保存到本地
- (NSString *)pathForSize:(CGSize)size {
    NSString *filename = [NSString stringWithFormat:@"SZColorPickerImage_%d_%d@%dx", (int)size.width, (int)size.height, (int)[UIScreen mainScreen].scale];
    filename = [filename stringByAppendingPathExtension:@"png"];
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [cacheDirectory stringByAppendingPathComponent:filename];
}

- (void)saveBackgroundImageForSize:(CGSize)size {
    if ([[[NSFileManager alloc] init] fileExistsAtPath:[self pathForSize:size]]) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [self drawBackgroundInContext:context withSize:size];
        UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
        NSData *pngImage = UIImagePNGRepresentation(backgroundImage);
        [pngImage writeToFile:[self pathForSize:size] atomically:YES];
        UIGraphicsEndImageContext();
    });
}

- (void)drawBackgroundInContext:(CGContextRef)context withSize:(CGSize)size {
    CGPoint center = CGPointMake(floorf(size.width/2.0f), floorf(size.height/2.0f));
    CGFloat radius = floorf(size.width/2.0f);           // draw a bit outside of our bouds. we will clip that back to our bounds.
    // this avoids artifacts at the edge
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextSaveGState(context);
    CGContextAddEllipseInRect(context, CGRectMake(0, 0, size.width, size.height));
    CGContextClip(context);
    
    NSInteger numberOfSegments = 3600;
    for (CGFloat i = 0; i < numberOfSegments; i++) {
        UIColor *color = [UIColor colorWithHue:1-i/(float)numberOfSegments saturation:1 brightness:1 alpha:1];
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        
        CGFloat segmentAngle = 2*M_PI / (float)numberOfSegments;
        CGPoint start = center;
        CGPoint end = CGPointMake(center.x + radius * cosf(i * segmentAngle), center.y + radius * sinf(i * segmentAngle));
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, 0, start.x, start.y);
        
        CGFloat offsetFromMid = 0.5f*(M_PI/180);
        CGPoint end1 = CGPointMake(center.x + radius * cosf(i * segmentAngle-offsetFromMid), center.y + radius * sinf(i * segmentAngle-offsetFromMid));
        CGPoint end2 = CGPointMake(center.x + radius * cosf(i * segmentAngle+offsetFromMid), center.y + radius * sinf(i * segmentAngle+offsetFromMid));
        CGPathAddLineToPoint(path, 0, start.x, start.y);
        CGPathAddLineToPoint(path, 0, end.x, end.y);
        CGPathAddLineToPoint(path, 0, end1.x, end1.y);
        CGPathAddLineToPoint(path, 0, end2.x, end2.y);
        
        CGContextSaveGState(context);
        CGContextAddPath(context, path);
        
        CGPathRelease(path);
        CGContextClip(context);
        
        NSArray *colors = @[(__bridge id)[UIColor colorWithWhite:1 alpha:1].CGColor, (__bridge id)color.CGColor];
        CGGradientRef gradient = CGGradientCreateWithColors(rgbColorSpace, (__bridge CFArrayRef)colors, NULL);
        CGContextDrawLinearGradient(context, gradient, start, end, kCGGradientDrawsBeforeStartLocation|kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(gradient);
        CGContextRestoreGState(context);
    }
    CGColorSpaceRelease(rgbColorSpace);
    
    CGContextRestoreGState(context);
    
    CGContextSetStrokeColorWithColor(context, UIColor.clearColor.CGColor);
    CGContextSetLineWidth(context, 1);
    CGContextStrokeEllipseInRect(context, CGRectMake(0, 0, size.width, size.height));
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIImage *image = [UIImage imageWithContentsOfFile:[self pathForSize:self.bounds.size]];
    if (!image) {
        [self saveBackgroundImageForSize:self.bounds.size];
        image = [UIImage imageWithContentsOfFile:[self pathForSize:self.bounds.size]];
    }
    if (image) {
        [image drawInRect:self.bounds];
    } else {
        [self drawBackgroundInContext:context withSize:self.bounds.size];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
