//
//  RCTSignatureView.m
//  RCTSignatureView
//
//  Created by admin on 2017/5/23.
//  Copyright © 2017年 m. All rights reserved.
//


#import "RCTSignatureView.h"
#import <React/RCTConvert.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "RCTBaseSignatureView.h"
#import "RCTSignatureViewManager.h"

@implementation  RCTSignatureView{
    CAShapeLayer *_border;
    BOOL _loaded;
    EAGLContext *_context;
    BOOL _rotateClockwise;
    BOOL _square;
    BOOL _isBackGroud;//为true时,生成的图片包含水印层信息。
    UIImage *waterBackGroud;

}

@synthesize sign;
@synthesize manager;

- (instancetype)init{
    if ((self = [super init])) {
        _border = [CAShapeLayer layer];
        _border.strokeColor = [UIColor clearColor].CGColor;
        _border.fillColor = nil;
        _border.lineDashPattern = @[@4, @2];
        [self.layer addSublayer:_border];
    }
    return self;
}
- (void) didRotate:(NSNotification *)notification {
    int ori=1;
    UIDeviceOrientation currOri = [[UIDevice currentDevice] orientation];
    if ((currOri == UIDeviceOrientationLandscapeLeft) || (currOri == UIDeviceOrientationLandscapeRight)) {
        ori=0;
    }
}
- (void)layoutSubviews{
    [super layoutSubviews];
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    [user setObject:_signatureColor forKey:@"signatureColor"];
    if (!_loaded) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:)
                                                     name:UIDeviceOrientationDidChangeNotification object:nil];
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        CGSize screen = self.bounds.size;
        [self addSubview:[self waterLayout]];
        sign = [[RCTBaseSignatureView alloc]
                initWithFrame: CGRectMake(0, 0, screen.width, screen.height)
                context: _context];
        sign.manager = manager;
        [self addSubview:sign];
    }
    _loaded = true;
    _border.path = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
    _border.frame = self.bounds;
}
#pragma mark -- get方法获取js交互数值
-(void)setWatermarkString:(NSString *)watermarkString{
    _watermarkString = watermarkString;
}
-(void)setWatermarkLineSpacing:(NSNumber *)watermarkLineSpacing{
    _watermarkLineSpacing = watermarkLineSpacing;
}
-(void)setWatermarkWordSpacing:(NSNumber *)watermarkWordSpacing{
    _watermarkWordSpacing = watermarkWordSpacing;
}
-(void)setWatermarkAngle:(NSNumber *)watermarkAngle{
    _watermarkAngle = watermarkAngle;
}
-(void)setWatermarkSize:(NSNumber *)watermarkSize{
    _watermarkSize = watermarkSize;
}
-(void)setWatermarkColor:(NSNumber *)watermarkColor{
    _watermarkColor = watermarkColor;
}
-(void)setSignatureColor:(NSNumber *)signatureColor{
    _signatureColor = signatureColor;
}
#pragma mark -- 保存签名照片
-(void)saveImage {
    UIImage *signImage = [self.sign signatureImage: false withSquare:false];
    UIImage *combineImage = [self combinePicWithImage:(UIImage*)signImage];
    NSError *error;

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *tempPath = [documentsDirectory stringByAppendingFormat:@"/signature.png"];
    NSLog(@"tempPath:%@",tempPath);

    if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:&error];
        if (error) {
            NSLog(@"Error: %@", error.debugDescription);
        }
    }
    NSData *imageData = UIImagePNGRepresentation(combineImage);
    BOOL isSuccess = [imageData writeToFile:tempPath atomically:YES];
    if (isSuccess) {
        NSString *base64Encoded = [imageData base64EncodedStringWithOptions:0];
        [self.manager publishSaveImageEvent: tempPath withEncoded:base64Encoded];
    }
}
-(UIImage*)combinePicWithImage:(UIImage*)signImage{
    UIView *containView = [[UIView alloc]initWithFrame:self.bounds];
    UIImageView *backImageV = [[UIImageView alloc]initWithFrame:containView.bounds];
    backImageV.image = waterBackGroud;
    [containView addSubview:backImageV];
    containView.backgroundColor = [UIColor whiteColor];

    UIImageView *imageV = [[UIImageView alloc]initWithFrame:self.bounds];
    imageV.backgroundColor = [UIColor clearColor];
    imageV.image = signImage;

    [containView addSubview:imageV];

    return [self shotScreen:containView Rect:imageV.bounds];
}
-(UIImage*)shotScreen:(UIView*)view Rect:(CGRect)purposeRect{
    UIGraphicsBeginImageContext(view.bounds.size);     //设置截屏大小
    [[view layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRef imageRef = viewImage.CGImage;
    CGRect rect = purposeRect;//这里可以设置想要截图的区域
    CGImageRef imageRefRect =CGImageCreateWithImageInRect(imageRef, rect);
    UIImage *sendImage = [[UIImage alloc] initWithCGImage:imageRefRect];
    return sendImage;
}

#pragma mark -- 配置水印UIImageView
-(UIImageView*)waterLayout{
    UIView *disPlayView;
    UIView *contentView;
    UIImageView *backImgView = [[UIImageView alloc]initWithFrame:self.bounds];
    int Width = self.bounds.size.width;
    int Height = self.bounds.size.height;
    _isBackGroud = true;
    if (_isBackGroud) {
        disPlayView = [[UIView alloc]initWithFrame:CGRectMake(-Width, Height, Height*2, Height*2)];
        [self addWhiteBackView:disPlayView];
        [self getDegree:disPlayView];
        contentView = [[UIView alloc]initWithFrame:disPlayView.bounds];
        //        contentView.backgroundColor = backColor;
        [contentView addSubview:disPlayView];
    }else{
        disPlayView = [[UIView alloc]initWithFrame:CGRectMake(-Width, -Height, Height*2, Height*2)];
        [self addWhiteBackView:disPlayView];
        [self getDegree:disPlayView];
        [backImgView addSubview:disPlayView];
        //        backImgView.backgroundColor = backColor;
    }
    CGRect rect = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.bounds.size.height);
    waterBackGroud = [self shotScreen:contentView Rect:rect];
    backImgView.clipsToBounds = YES;
    backImgView.image = waterBackGroud;
    return backImgView;

}
-(void)getDegree: (UIView *)view{
    CGAffineTransform transform;
    float angle;
    int tiltAngle;
    if (_watermarkAngle.intValue == 0) {
        tiltAngle = 45;
    }else tiltAngle = _watermarkAngle.intValue;
    int degree = tiltAngle % 360;
    if (degree == 0) {
        angle = 0;
    }else {
        if (tiltAngle > 360) {
            angle = 180.0/degree;
        }else {
            angle = 180.0/tiltAngle;
        }
        transform = CGAffineTransformMakeRotation(M_PI/angle);
        view.transform = transform;
    }
}
-(void)addWhiteBackView:(UIView *)view{
    int watermarkSize;
    if (_watermarkSize.intValue) {
        watermarkSize = _watermarkSize.intValue;
    }else watermarkSize = 14;
    UIFont *font = [UIFont systemFontOfSize:watermarkSize];
    CGRect rectString = [_watermarkString boundingRectWithSize:CGSizeMake(200, 0) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil];
    int resultAY = self.bounds.size.height*2;
    UIColor *backColor;
    NSNumber *watermarkColor;
    if (_watermarkColor) {
        watermarkColor = _watermarkColor;
        NSString *watermarkColorStr = [self ToHex:_watermarkColor.unsignedLongLongValue];
        backColor = [self colorWithHexString:watermarkColorStr alpha:1];
    }else{
        backColor = [self colorWithHexString:@"#888888" alpha:1];
    }

    int watermarkLineSpacing;
    if (_watermarkLineSpacing.intValue == 0) {
        watermarkLineSpacing = rectString.size.height * 3;
    }else{
        if (_watermarkLineSpacing.intValue <= 5) {
            watermarkLineSpacing = 5;
        }else watermarkLineSpacing = _watermarkLineSpacing.intValue;
    }
    int watermarkWordSpacing;
    if (_watermarkWordSpacing.intValue == 0) {
        watermarkWordSpacing = rectString.size.width/2;
    }else{
        if (_watermarkWordSpacing.intValue <= 5) {
            watermarkWordSpacing = 5;
        }else watermarkWordSpacing = _watermarkWordSpacing.intValue;
    }
    for (int i = 0; i < (resultAY/rectString.size.width); i ++) {
        for (int j = 0; j < (resultAY/rectString.size.height); j ++) {
            CGFloat x;
            if (j % 2 == 0) {
                x = 0;
            }else{
                x = rectString.size.width/2 + watermarkWordSpacing/2;
            }


            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(x + i*(rectString.size.width+watermarkWordSpacing),j*(rectString.size.height+watermarkLineSpacing), rectString.size.width, rectString.size.height)];
            lab.text = _watermarkString;
            lab.textColor = backColor;
            lab.font = [UIFont systemFontOfSize:watermarkSize];
            [view addSubview:lab];
        }
    }

}

#pragma mark -- 处理js层传输过来的颜色数据
-(NSString *)ToHex:(long long int)tmpid{
    NSString *nLetterValue;
    NSString *str =@"";
    long long int ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:nLetterValue=[[NSString alloc]initWithFormat:@"%i",ttmpig];

        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    return str;
}
- (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha{
    //删除字符串中的空格
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6){
        return [UIColor clearColor];
    }
    //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"]){
        cString = [cString substringFromIndex:2];
    }
    //如果是FF开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"FF"]){
        cString = [cString substringFromIndex:2];
    }
    //如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
    if ([cString hasPrefix:@"#"]){
        cString = [cString substringFromIndex:1];
    }
    if ([cString length] != 6){
        return [UIColor clearColor];
    }

    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];

    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:alpha];
}
-(void) erase {
    [self.sign erase];
}

@end
