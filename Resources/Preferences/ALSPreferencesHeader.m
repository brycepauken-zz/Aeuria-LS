#import "ALSPreferencesHeader.h"

#import "PSSpecifier.h"
#import "SBWallpaperController.h"

@interface ALSPreferencesHeader()

@property (nonatomic, strong) UIView *filledOverlay;
@property (nonatomic, strong) CAShapeLayer *filledOverlayMask;
@property (nonatomic, strong) UIImage *lockscreenWallpaper;
@property (nonatomic, strong) UIImageView *wallpaperView;

@end

@implementation ALSPreferencesHeader

//static const int kBorderThickness = 10;
static const CGFloat kCircleInnerRadiusProportion = 0.25;
static const CGFloat kCircleOuterRadiusProportion = 0.3;
static const CGFloat kLSTextScale = 0.9;
static const CGFloat kLSTextShift = 0.9;
static const int kMiddlePadding = 8;

static NSString *kALSPreferencesResourcesPath = @"/Library/PreferenceBundles/AeuriaLSPreferences.bundle/";
static CGFloat _wallpaperViewHeight;

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ALSPreferencesHeader" specifier:specifier];
    if(self) {
        //called to initialize _wallpaperViewHeight if we haven't already
        [self preferredHeightForWidth:0];
        
        //create a container to hold (and clip) our header's subviews
        UIView *subviewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, -44, self.bounds.size.width, _wallpaperViewHeight)];
        [subviewContainer setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [subviewContainer setClipsToBounds:YES];
        
        //create the wallpaper view
        _wallpaperView = [[UIImageView alloc] initWithFrame:subviewContainer.bounds];
        [_wallpaperView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_wallpaperView setContentMode:UIViewContentModeScaleAspectFill];
        [subviewContainer addSubview:_wallpaperView];
        
        //get the user's current lock screen wallpaper
        NSData *lockscreenWallpaperData = [NSData dataWithContentsOfFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"];
        if(lockscreenWallpaperData) {
            //freed near-immediately
            CFDataRef lockscreenWallpaperDataRef = CFDataCreate(NULL, lockscreenWallpaperData.bytes, lockscreenWallpaperData.length);
            //this is a declaration for the method used in the following statement, not a call
            CFArrayRef CPBitmapCreateImagesFromData(CFDataRef cpbitmap, void*, int, void*);
            //freed after if statement
            CFArrayRef wallpaperArray = CPBitmapCreateImagesFromData(lockscreenWallpaperDataRef, NULL, 1, NULL);
            CFRelease(lockscreenWallpaperDataRef);
            if(CFArrayGetCount(wallpaperArray) > 0) {
                CGImageRef lockscreenWallpaperRef = (CGImageRef)CFArrayGetValueAtIndex(wallpaperArray, 0);
                _lockscreenWallpaper = [UIImage imageWithCGImage:lockscreenWallpaperRef];
                [_wallpaperView setImage:_lockscreenWallpaper];
            }
            CFRelease(wallpaperArray);
        }
        
        //create the filled overlay that shows the title and circle
        _filledOverlay = [[UIView alloc] initWithFrame:subviewContainer.bounds];
        [_filledOverlay setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_filledOverlay setBackgroundColor:[UIColor whiteColor]];
        _filledOverlayMask = [[CAShapeLayer alloc] init];
        [_filledOverlayMask setFillColor:[[UIColor blackColor] CGColor]];
        [_filledOverlayMask setFillRule:kCAFillRuleEvenOdd];
        [_filledOverlay.layer setMask:_filledOverlayMask];
        [subviewContainer addSubview:_filledOverlay];
        
        //create views outside of the subviewContainer to cast a shadow inside
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGFloat shadowCastingViewWidth = MAX(screenBounds.size.width, screenBounds.size.height)*2;
        for(int i=0;i<2;i++) {
            UIView *shadowCastingView = [[UIView alloc] initWithFrame:CGRectMake(-20, (i==0?-20:subviewContainer.bounds.size.height), shadowCastingViewWidth+40, 20)];
            [shadowCastingView setBackgroundColor:[UIColor blackColor]];
            [shadowCastingView.layer setMasksToBounds:NO];
            [shadowCastingView.layer setShadowOffset:CGSizeMake(0, 0)];
            [shadowCastingView.layer setShadowOpacity:0.5];
            [shadowCastingView.layer setShadowRadius:2];
            [subviewContainer addSubview:shadowCastingView];
        }
         
        [self updateFilledOverlay];
        [self addSubview:subviewContainer];
    }
    
    return self;
}

- (void)layoutSubviews {
    //check if wallpaperView size changed
    CGSize filledOverlaySize = self.filledOverlay.bounds.size;
    [super layoutSubviews];
    if(!CGSizeEqualToSize(filledOverlaySize, self.filledOverlay.bounds.size)) {
        [self updateFilledOverlay];
    }
}

+ (CGPathRef)pathForAeuriaText {
    static CGPathRef path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        path = [self pathFromFile:@"AeuriaPath.dat"];
    });
    return path;
}

+ (CGPathRef)pathForLSText {
    static CGPathRef path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        path = [self pathFromFile:@"LSPath.dat"];
    });
    return path;
}

/*
 Returns a CGPathRef given by an array of types and coordinates stored in the given file.
 */
+ (CGPathRef)pathFromFile:(NSString *)file {
    //not freed; owned by caller
    CGPathRef path;
    //freed at end of method
    CGMutablePathRef mutablePath = CGPathCreateMutable();
    CGFloat s = 1000;
    NSData *LSPathData = [NSData dataWithContentsOfFile:[kALSPreferencesResourcesPath stringByAppendingString:file]];
    NSArray *LSPathInfo;
    if(LSPathData) {
        LSPathInfo = [NSKeyedUnarchiver unarchiveObjectWithData:LSPathData];
    }
    if(LSPathInfo.count) {
        for(int i=0;i<LSPathInfo.count;i++) {
            int numPoints;
            switch ([LSPathInfo[i] intValue]) {
                case kCGPathElementMoveToPoint:
                    numPoints = 1;
                    CGPathMoveToPoint(mutablePath, NULL,
                        [LSPathInfo[i+1] intValue]/s, [LSPathInfo[i+2] intValue]/s
                    );
                    break;
                case kCGPathElementAddLineToPoint:
                    numPoints = 1;
                    CGPathAddLineToPoint(mutablePath, NULL,
                        [LSPathInfo[i+1] intValue]/s, [LSPathInfo[i+2] intValue]/s
                    );
                    break;
                case kCGPathElementAddQuadCurveToPoint:
                    numPoints = 2;
                    CGPathAddQuadCurveToPoint(mutablePath, NULL,
                        [LSPathInfo[i+1] intValue]/s, [LSPathInfo[i+2] intValue]/s,
                        [LSPathInfo[i+3] intValue]/s, [LSPathInfo[i+4] intValue]/s
                    );
                    break;
                case kCGPathElementAddCurveToPoint:
                    numPoints = 3;
                    CGPathAddCurveToPoint(mutablePath, NULL,
                        [LSPathInfo[i+1] intValue]/s, [LSPathInfo[i+2] intValue]/s,
                        [LSPathInfo[i+3] intValue]/s, [LSPathInfo[i+4] intValue]/s,
                        [LSPathInfo[i+5] intValue]/s, [LSPathInfo[i+6] intValue]/s
                    );
                    break;
                case kCGPathElementCloseSubpath:
                    numPoints = 0;
                    CGPathCloseSubpath(mutablePath);
                    break;
                default:
                    numPoints = 0;
                    break;
            }
            i += numPoints*2;
        }
        path = CGPathCreateCopy(mutablePath);
    }
    else {
        path = CGPathCreateWithRect(CGRectMake(0, 0, 0, 0), NULL);
    }
    CGPathRelease(mutablePath);
    return path;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    static CGFloat preferredHeight;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        _wallpaperViewHeight = ceilf(sqrtf(MIN(screenBounds.size.width, screenBounds.size.height)*30));
        
        preferredHeight = _wallpaperViewHeight+100;
    });
    return preferredHeight;
}

- (void)updateFilledOverlay {
    //create the beginning of our mask
    UIBezierPath *mask = [UIBezierPath bezierPath];
    
    //get our large text paths, which we'll scale down
    CGPathRef aeuriaPath = [[self class] pathForAeuriaText];
    CGSize aeuriaPathSize = CGPathGetPathBoundingBox(aeuriaPath).size;
    CGPathRef lsPath = [[self class] pathForLSText];
    CGSize lsPathSize = CGPathGetPathBoundingBox(lsPath).size;
    
    //find inner and outer circle radius for our current height
    CGFloat innerCircleRadius = self.filledOverlay.bounds.size.height*kCircleInnerRadiusProportion;
    CGFloat outerCircleRadius = self.filledOverlay.bounds.size.height*kCircleOuterRadiusProportion;
    
    //scale the LS path to fit within the inner circle radius
    CGFloat lsHeight = innerCircleRadius*lsPathSize.height/sqrt(lsPathSize.width/2*lsPathSize.width/2+lsPathSize.height/2*lsPathSize.height/2);
    CGFloat lsScale = (lsHeight/lsPathSize.height)*kLSTextScale;
    
    //scale the Aeuria path to the same height as the LS path
    CGFloat aeuriaScale = lsHeight/aeuriaPathSize.height;
    CGFloat aeuriaWidth = (aeuriaPathSize.width*aeuriaScale);
    
    //find the horizontal offset of the group (Aeuria text, then middle padding, then circle)
    CGFloat horizontalOffset = ((self.filledOverlay.bounds.size.width-aeuriaWidth-kMiddlePadding)/2-outerCircleRadius);
    
    //transform and append the LS path
    CGAffineTransform lsTransform = CGAffineTransformMakeScale(lsScale, lsScale);
    lsTransform = CGAffineTransformTranslate(lsTransform, (horizontalOffset+aeuriaWidth+kMiddlePadding+outerCircleRadius-(lsPathSize.width*lsScale)*kLSTextShift/2)/lsScale, ((self.filledOverlay.bounds.size.height-(lsPathSize.height*lsScale))/2)/lsScale);
    CGPathRef scaledLSPath = CGPathCreateCopyByTransformingPath(lsPath, &lsTransform);
    [mask appendPath:[UIBezierPath bezierPathWithCGPath:scaledLSPath]];
    CGPathRelease(scaledLSPath);
    
    //transform and append the Aeuria path
    CGAffineTransform aeuriaTransform = CGAffineTransformMakeScale(aeuriaScale, aeuriaScale);
    aeuriaTransform = CGAffineTransformTranslate(aeuriaTransform, horizontalOffset/aeuriaScale, ((self.filledOverlay.bounds.size.height+(lsPathSize.height*lsScale))/2-(aeuriaPathSize.height*aeuriaScale))/aeuriaScale);
    CGPathRef scaledAeuriaPath = CGPathCreateCopyByTransformingPath(aeuriaPath, &aeuriaTransform);
    [mask appendPath:[UIBezierPath bezierPathWithCGPath:scaledAeuriaPath]];
    CGPathRelease(scaledAeuriaPath);
    
    //add circle to mask
    [mask appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(horizontalOffset+aeuriaWidth+kMiddlePadding, self.filledOverlay.bounds.size.height/2-outerCircleRadius, outerCircleRadius*2, outerCircleRadius*2) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(outerCircleRadius, outerCircleRadius)]];
    
    [self.filledOverlayMask setPath:mask.CGPath];
}

@end