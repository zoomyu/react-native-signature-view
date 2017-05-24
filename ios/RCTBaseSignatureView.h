//
//  RCTBaseSignatureView.h
//  RCTSignatureView
//
//  Created by admin on 2017/5/23.
//  Copyright © 2017年 m. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class RCTSignatureViewManager;
@class RCTSignatureView;

@interface RCTBaseSignatureView : GLKView

@property (assign, nonatomic) UIColor *strokeColor;
@property (assign, nonatomic) BOOL hasSignature;
@property (strong, nonatomic) UIImage *signatureImage;
@property (nonatomic, strong) RCTSignatureViewManager *manager;
@property (nonatomic, strong) RCTSignatureView *signatureView;
@property (nonatomic, strong) NSNumber *signatureColor;

- (void)erase;

- (UIImage *) signatureImage;
- (UIImage *) signatureImage: (BOOL) rotatedImage;
- (UIImage *) signatureImage: (BOOL) rotatedImage withSquare:(BOOL)square;

@end
