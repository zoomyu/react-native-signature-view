//
//  RCTSignatureViewManager.h
//  RCTSignatureView
//
//  Created by admin on 2017/5/23.
//  Copyright © 2017年 m. All rights reserved.
//

//#import "RCTViewManager.h"
#import <React/RCTViewManager.h>
#import "RCTSignatureView.h"

@interface RCTSignatureViewManager : RCTViewManager
@property (nonatomic, strong) RCTSignatureView *signView;
-(void) saveSignature:(nonnull NSNumber *)reactTag;
-(void) resetSignature:(nonnull NSNumber *)reactTag;
-(void) publishSaveImageEvent:(NSString *) aTempPath withEncoded: (NSString *) aEncoded;
-(void) publishDraggedEvent;

@end
