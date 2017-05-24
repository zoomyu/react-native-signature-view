//
//  RCTSignatureViewManager.m
//  RCTSignatureView
//
//  Created by admin on 2017/5/23.
//  Copyright © 2017年 m. All rights reserved.
//


#import "RCTSignatureViewManager.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>

@implementation RCTSignatureViewManager

@synthesize bridge = _bridge;
@synthesize signView;

RCT_EXPORT_MODULE()
RCT_EXPORT_VIEW_PROPERTY(watermarkString, NSString)
RCT_EXPORT_VIEW_PROPERTY(watermarkLineSpacing, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(watermarkWordSpacing, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(watermarkAngle, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(watermarkSize, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(watermarkColor, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(signatureColor, NSNumber)

-(dispatch_queue_t) methodQueue{
    return dispatch_get_main_queue();
}

-(UIView *) view{
    self.signView = [[RCTSignatureView alloc] init];
    self.signView.manager = self;
    return signView;
}
RCT_EXPORT_METHOD(saveSignature:(nonnull NSNumber *)reactTag) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.signView saveImage];
    });
}

RCT_EXPORT_METHOD(resetSignature:(nonnull NSNumber *)reactTag) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.signView erase];
    });
}

-(void) publishSaveImageEvent:(NSString *) aTempPath withEncoded: (NSString *) aEncoded {
    [self.bridge.eventDispatcher
     sendDeviceEventWithName:@"onSaveEvent"
     body:@{
            @"pathName": aTempPath,
            @"encoded": aEncoded
            }];
}

-(void) publishDraggedEvent {
    [self.bridge.eventDispatcher
     sendDeviceEventWithName:@"onDragEvent"
     body:@{@"dragged": @YES}];
}

@end
