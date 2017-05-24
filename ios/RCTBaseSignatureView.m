//
//  RCTBaseSignatureView.m
//  RCTSignatureView
//
//  Created by admin on 2017/5/23.
//  Copyright © 2017年 m. All rights reserved.
//

#import "RCTBaseSignatureView.h"
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES1/gl.h>
#import "RCTSignatureViewManager.h"
#import "RCTSignatureView.h"

#define QUADRATIC_DISTANCE_TOLERANCE 3.0   // Minimum distance to make a curve

#define             MAXIMUM_VERTECES 100000
static GLKVector3 StrokeColor = { 0, 0, 0 };
static float clearColor[4] = { 1, 1, 1, 0 };

struct PCTSignaturePoint
{
    GLKVector3		vertex;
    GLKVector3		color;
};
typedef struct PCTSignaturePoint PCTSignaturePoint;

static const int maxLength = MAXIMUM_VERTECES;

static inline void addVertex(uint *length, PCTSignaturePoint v) {
    if ((*length) >= maxLength) {
        return;
    }

    GLvoid *data = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    memcpy(data + sizeof(PCTSignaturePoint) * (*length), &v, sizeof(PCTSignaturePoint));
    glUnmapBufferOES(GL_ARRAY_BUFFER);

    (*length)++;
}

static inline CGPoint QuadraticPointInCurve(CGPoint start, CGPoint end, CGPoint controlPoint, float percent) {
    double a = pow((1.0 - percent), 2.0);
    double b = 2.0 * percent * (1.0 - percent);
    double c = pow(percent, 2.0);

    return (CGPoint) {
        a * start.x + b * controlPoint.x + c * end.x,
        a * start.y + b * controlPoint.y + c * end.y
    };
}

static float generateRandom(float from, float to) { return random() % 10000 / 10000.0 * (to - from) + from; }
static float clamp(float min, float max, float value) { return fmaxf(min, fminf(max, value)); }

static GLKVector3 perpendicular(PCTSignaturePoint p1, PCTSignaturePoint p2) {
    GLKVector3 ret;
    ret.x = p2.vertex.y - p1.vertex.y;
    ret.y = -1 * (p2.vertex.x - p1.vertex.x);
    ret.z = 0;
    return ret;
}

static PCTSignaturePoint ViewPointToGL(CGPoint viewPoint, CGRect bounds, GLKVector3 color) {

    return (PCTSignaturePoint) {
        {
            (viewPoint.x / bounds.size.width * 2.0 - 1),
            ((viewPoint.y / bounds.size.height) * 2.0 - 1) * -1,
            0
        },
        color
    };
}
@interface RCTBaseSignatureView () {
    // OpenGL state
    EAGLContext *context;
    GLKBaseEffect *effect;

    GLuint vertexArray;
    GLuint vertexBuffer;
    GLuint dotsArray;
    GLuint dotsBuffer;

    PCTSignaturePoint SignatureVertexData[maxLength];
    uint length;

    PCTSignaturePoint SignatureDotsData[maxLength];
    uint dotsLength;

    float penThickness;
    float previousThickness;

    CGPoint previousPoint;
    CGPoint previousMidPoint;
    PCTSignaturePoint previousVertex;
    PCTSignaturePoint currentVelocity;
}

@end

@implementation RCTBaseSignatureView

@synthesize manager;
#pragma mark -- 初始化
- (void)commonInit {
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    _signatureColor = [ user objectForKey:@"signatureColor"];
    if (context) {

        time(NULL);
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;

        self.context = context;
        self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        self.enableSetNeedsDisplay = YES;

        // Turn on antialiasing
        self.drawableMultisample = GLKViewDrawableMultisample4X;//解决锯齿问题

        [self setupGL];

        // Capture touches
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        pan.maximumNumberOfTouches = pan.minimumNumberOfTouches = 1;// 最多手指个数
        pan.cancelsTouchesInView = YES;
        [self addGestureRecognizer:pan];

        // For dotting your i's
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        tap.cancelsTouchesInView = YES;
        [self addGestureRecognizer:tap];

        // Erase with long press
        UILongPressGestureRecognizer *longer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        longer.cancelsTouchesInView = YES;
        [self addGestureRecognizer:longer];
    }
    else
        [NSException raise:@"NSOpenGLES2ContextException" format:@"Failed to create OpenGL ES2 context"];
}
- (void)setupGL{
    [EAGLContext setCurrentContext:context];

    effect = [[GLKBaseEffect alloc] init];

    [self updateStrokeColor];


    glDisable(GL_DEPTH_TEST);//关闭深度测试
    previousThickness = 0.01;
    penThickness = 0.01;

    // Signature Lines
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);

    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SignatureVertexData), SignatureVertexData, GL_DYNAMIC_DRAW);
    [self bindShaderAttributes];


    // Signature Dots
    glGenVertexArraysOES(1, &dotsArray);
    glBindVertexArrayOES(dotsArray);

    glGenBuffers(1, &dotsBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, dotsBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SignatureDotsData), SignatureDotsData, GL_DYNAMIC_DRAW);
    [self bindShaderAttributes];


    glBindVertexArrayOES(0);


    // Perspective
    GLKMatrix4 ortho = GLKMatrix4MakeOrtho(-1, 1, -1, 1, 0.1f, 2.0f);
    effect.transform.projectionMatrix = ortho;

    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.0f);
    effect.transform.modelviewMatrix = modelViewMatrix;

    length = 0;
    previousPoint = CGPointMake(-100, -100);
}
- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)ctx{
    if (self = [super initWithFrame:frame context:ctx]) [self commonInit];
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) [self commonInit];
    return self;
}
//绘图准备
- (void)drawRect:(CGRect)rect{

    glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3]);
    glClear(GL_COLOR_BUFFER_BIT);

    [effect prepareToDraw];

    if (length > 2) {
        glBindVertexArrayOES(vertexArray);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, length);//length:顶点数量
    }

    if (dotsLength > 0) {
        glBindVertexArrayOES(dotsArray);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, dotsLength);
    }
}


#pragma mark - Gesture Recognizers

//绘点
- (void)tap:(UITapGestureRecognizer *)t {
    CGPoint l = [t locationInView:self];

    if (t.state == UIGestureRecognizerStateRecognized) {
        glBindBuffer(GL_ARRAY_BUFFER, dotsBuffer);

        PCTSignaturePoint touchPoint = ViewPointToGL(l, self.bounds, (GLKVector3){1, 1, 1});
        addVertex(&dotsLength, touchPoint);

        PCTSignaturePoint centerPoint = touchPoint;
        centerPoint.color = StrokeColor;
        addVertex(&dotsLength, centerPoint);

        static int segments = 20;
        GLKVector2 radius = (GLKVector2){
            clamp(0.00001, 0.02, penThickness * generateRandom(0.5, 1.5)),
            clamp(0.00001, 0.02, penThickness * generateRandom(0.5, 1.5))
        };
        GLKVector2 velocityRadius = radius;
        float angle = 0;

        for (int i = 0; i <= segments; i++) {

            PCTSignaturePoint p = centerPoint;
            p.vertex.x += velocityRadius.x * cosf(angle);
            p.vertex.y += velocityRadius.y * sinf(angle);

            addVertex(&dotsLength, p);
            addVertex(&dotsLength, centerPoint);

            angle += M_PI * 2.0 / segments;
        }

        addVertex(&dotsLength, touchPoint);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    [self setNeedsDisplay];
}


- (void)longPress:(UILongPressGestureRecognizer *)lp {
    //	[self erase];
}
//手势绘图
- (void)pan:(UIPanGestureRecognizer *)p {

    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);

    CGPoint v = [p velocityInView:self];
    CGPoint l = [p locationInView:self];

    currentVelocity = ViewPointToGL(v, self.bounds, (GLKVector3){0,0,0});
    float distance = 0.;
    if (previousPoint.x > 0) {
        distance = sqrtf((l.x - previousPoint.x) * (l.x - previousPoint.x) + (l.y - previousPoint.y) * (l.y - previousPoint.y));
    }
    if ([p state] == UIGestureRecognizerStateBegan) {
        previousPoint = l;
        previousMidPoint = l;

        PCTSignaturePoint startPoint = ViewPointToGL(l, self.bounds, (GLKVector3){1, 1, 1});
        previousVertex = startPoint;

        addVertex(&length, startPoint);
        addVertex(&length, previousVertex);

        self.hasSignature = YES;
        [self.manager publishDraggedEvent];

    } else if ([p state] == UIGestureRecognizerStateChanged) {
        CGPoint mid = CGPointMake((l.x + previousPoint.x) / 2.0, (l.y + previousPoint.y) / 2.0);
        if (distance > QUADRATIC_DISTANCE_TOLERANCE) {
            unsigned int i;
            int segments = (int) distance / 1.5;
            for (i = 0; i < segments; i++){
                CGPoint quadPoint = QuadraticPointInCurve(previousMidPoint, mid, previousPoint, (float)i / (float)(segments));
                PCTSignaturePoint v = ViewPointToGL(quadPoint, self.bounds, StrokeColor);
                [self addTriangleStripPointsForPrevious:previousVertex next:v];
                previousVertex = v;
            }
        } else if (distance > 1.0) {
            PCTSignaturePoint v = ViewPointToGL(l, self.bounds, StrokeColor);
            [self addTriangleStripPointsForPrevious:previousVertex next:v];
            previousVertex = v;
        }
        previousPoint = l;
        previousMidPoint = mid;
    } else if (p.state == UIGestureRecognizerStateEnded | p.state == UIGestureRecognizerStateCancelled) {
        PCTSignaturePoint v = ViewPointToGL(l, self.bounds, (GLKVector3){1, 1, 1});
        addVertex(&length, v);

        previousVertex = v;
        addVertex(&length, previousVertex);
    }
    [self setNeedsDisplay];
}


#pragma mark -
- (void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
    [self updateStrokeColor];
}
- (void)updateStrokeColor {
    if (_signatureColor) {
        NSString *sty = [self ToHex:_signatureColor.unsignedLongLongValue];
        NSString *cString = [[sty stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
        //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
        if ([cString hasPrefix:@"0X"]){
            cString = [cString substringFromIndex:2];
        }
        //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
        if ([cString hasPrefix:@"FF"]){
            cString = [cString substringFromIndex:2];
        }
        //如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
        if ([cString hasPrefix:@"#"]){
            cString = [cString substringFromIndex:1];
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

        effect.constantColor = GLKVector4Make(r/255,g/255,b/255,1);
    }else effect.constantColor = GLKVector4Make(0,0,0,1);
}
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
            default:nLetterValue=[[NSString alloc]initWithFormat:@"%lli",ttmpig];

        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }

    }
    return str;
}
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    CGFloat red, green, blue, alpha, white;
    if ([backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha]) {
        clearColor[0] = red;
        clearColor[1] = green;
        clearColor[2] = blue;
    } else if ([backgroundColor getWhite:&white alpha:&alpha]) {
        clearColor[0] = white;
        clearColor[1] = white;
        clearColor[2] = white;
    }
}
- (void)bindShaderAttributes {
    glEnableVertexAttribArray(GLKVertexAttribPosition);//启用指定属性，在顶点着色器中访问逐顶点的属性数据。//启用顶点属性数组
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(PCTSignaturePoint), 0);//建立CPU和GPU之间的逻辑连接，从而实现了CPU数据上传至GPU。
    //    glEnableVertexAttribArray(GLKVertexAttribColor);
    //    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE,  6 * sizeof(GLfloat), (char *)12);
}
- (void)addTriangleStripPointsForPrevious:(PCTSignaturePoint)previous next:(PCTSignaturePoint)next {
    float toTravel = penThickness / 2.0;

    for (int i = 0; i < 2; i++) {
        GLKVector3 p = perpendicular(previous, next);
        GLKVector3 p1 = next.vertex;
        GLKVector3 ref = GLKVector3Add(p1, p);

        float distance = GLKVector3Distance(p1, ref);
        float difX = p1.x - ref.x;
        float difY = p1.y - ref.y;
        float ratio = -1.0 * (toTravel / distance);

        difX = difX * ratio;
        difY = difY * ratio;

        PCTSignaturePoint stripPoint = {
            { p1.x + difX, p1.y + difY, 0.0 },
            StrokeColor
        };
        addVertex(&length, stripPoint);

        toTravel *= -1;
    }
}
#pragma mark -- 撤销-销毁绘图工具
- (void)dealloc{
    self.context = nil;
    [self tearDownGL];
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    context = nil;
}
- (void)erase {
    length = 0;
    dotsLength = 0;
    self.hasSignature = NO;
    [self setNeedsDisplay];
}
- (void)tearDownGL{
    [EAGLContext setCurrentContext:context];

    glDeleteVertexArraysOES(1, &vertexArray);
    glDeleteBuffers(1, &vertexBuffer);

    glDeleteVertexArraysOES(1, &dotsArray);
    glDeleteBuffers(1, &dotsBuffer);

    effect = nil;
}
#pragma mark -- 绘图截图处理
- (UIImage*)imageByCombiningImage:(UIImage*)firstImage withImage:(UIImage*)secondImage {
    UIImage *image = nil;

    CGSize newImageSize = CGSizeMake(MAX(firstImage.size.width, secondImage.size.width), MAX(firstImage.size.height, secondImage.size.height));
    if (&UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(newImageSize, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(newImageSize);
    }
    [firstImage drawAtPoint:CGPointMake(roundf((newImageSize.width-firstImage.size.width)/2),
                                        roundf((newImageSize.height-firstImage.size.height)/2))];
    [secondImage drawAtPoint:CGPointMake(roundf((newImageSize.width-secondImage.size.width)/2),
                                         roundf((newImageSize.height-secondImage.size.height)/2))];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

-(UIImage *) snapshot {
    UIImage *result = [super snapshot];
    return result;
}

- (UIImage*)rotateImage:(UIImage*)sourceImage clockwise:(BOOL)clockwise {
    CGSize size = sourceImage.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.height, size.width));
    [[UIImage imageWithCGImage:[sourceImage CGImage]
                         scale:1.0
                   orientation:clockwise ? UIImageOrientationRight : UIImageOrientationLeft]
     drawInRect:CGRectMake(0,0,size.height ,size.width)];

    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (UIImage*) reduceImage:(UIImage*)image toSize:(CGSize)newSize {
    CGSize scaledSize = newSize;
    float scaleFactor = 1.0;

    if(image.size.width > image.size.height) {
        scaleFactor = image.size.width / image.size.height;
        scaledSize.width = newSize.width;
        scaledSize.height = newSize.height / scaleFactor;
    }
    else {
        scaleFactor = image.size.height / image.size.width;
        scaledSize.height = newSize.height;
        scaledSize.width = newSize.width / scaleFactor;
    }

    NSLog(@"%f x %f", scaledSize.width, scaledSize.height);

    UIGraphicsBeginImageContext(scaledSize);
    CGRect scaledImageRect = CGRectMake( 0.0, 0.0, scaledSize.width, scaledSize.height );
    [image drawInRect:scaledImageRect];

    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return scaledImage;
}

- (UIImage *)signatureImage {
    return [self signatureImage:false withSquare:false];
}
- (UIImage *)signatureImage: (BOOL) rotatedImage {
    return [self signatureImage:rotatedImage withSquare:false];
}
- (UIImage *)signatureImage: (BOOL) rotatedImage withSquare:(BOOL) square {
    if (!self.hasSignature)
        return nil;

    UIImage *signatureImg;
    UIImage *snapshot = [self snapshot];
    [self erase];

    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        //signature
        if (square) {
            signatureImg = [self reduceImage:snapshot toSize: CGSizeMake(400.0f, 400.0f)];
        }
        else {
            signatureImg = snapshot;
        }
    }
    else {
        //rotate iphone signature - iphone's signature screen is always landscape

        if (rotatedImage) {
            if (square) {
                UIImage *rotatedImg = [self rotateImage:snapshot clockwise:false];
                signatureImg = [self reduceImage:rotatedImg toSize: CGSizeMake(400.0f, 400.0f)];
            }
            else {
                UIImage *rotatedImg = [self rotateImage:snapshot clockwise:false];
                signatureImg = rotatedImg;
            }
        }
        else {
            if (square) {
                signatureImg = [self reduceImage:snapshot toSize: CGSizeMake(400.0f, 400.0f)];
            }
            else {
                signatureImg = snapshot;
            }
        }
    }

    return signatureImg;
}


@end
