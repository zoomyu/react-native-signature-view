//
//  RCTSignatureView.h
//  RCTSignatureView
//
//  Created by admin on 2017/5/23.
//  Copyright © 2017年 m. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTBaseSignatureView.h"

#import <UIKit/UIKit.h>
#import <React/RCTView.h>
#import <React/RCTBridge.h>

@class RCTSignatureViewManager;

@interface RCTSignatureView : RCTView

@property (nonatomic, strong) RCTBaseSignatureView *sign;
@property (nonatomic, strong) RCTSignatureViewManager *manager;
@property (nonatomic, strong) NSString *watermarkString;
@property (nonatomic, strong) NSNumber *watermarkLineSpacing;
@property (nonatomic, strong) NSNumber *watermarkWordSpacing;
@property (nonatomic, strong) NSNumber *watermarkAngle;
@property (nonatomic, strong) NSNumber *watermarkSize;
@property (nonatomic, strong) NSNumber *watermarkColor;
@property (nonatomic, strong) NSNumber *signatureColor;


-(void) saveImage;
-(void) erase;

@end
