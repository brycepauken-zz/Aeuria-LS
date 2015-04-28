#import "ALSPreferencesColorPicker.h"

#import "ALSColorGradient.h"
#import "ALSColorPanGestureRecognizer.h"
#import "ALSColorPickerInnerShadow.h"

@interface ALSPreferencesColorPicker()

@property (nonatomic, strong) UIView *backgroundOverlay;
@property (nonatomic, strong) ALSColorGradient *colorGradient;
@property (nonatomic, copy) void (^completionBlock)(NSString *hexColor);
@property (nonatomic, strong) UIScrollView *colorGradientContainer;
@property (nonatomic, strong) UIView *colorPreview;
@property (nonatomic, strong) UIImageView *huePicker;
@property (nonatomic, strong) CAShapeLayer *huePickerIndicatorLayer;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *textField;

@end

@implementation ALSPreferencesColorPicker

static const int kButtonImageLineLength = 16;
static const int kButtonImageLineThickness = 2;
static const int kButtonMargins = 8;
static const int kButtonSize = 30;
static const int kColorPickerWindowPadding = 20;
static const int kColorPickerWindowWidth = 280;
static const int kColorPointerHeightToCenter = 40;
static const int kColorPointerPreviewRadius = 16;
static const int kColorPointerRadius = 20;
static const int kColorPointerShadowRadius = 21;
static const int kHuePickerHeight = 18;
static const int kHuePickerIndicatorHeight = 28;
static const int kHuePickerIndicatorMargin = 4;
static const int kTextFieldHeight = 30;

- (instancetype)initWithParentView:(UIView *)parentView {
    self = [super init];
    if(self) {
        //create an overlay that darkens the window
        _backgroundOverlay = [[UIView alloc] initWithFrame:parentView.bounds];
        [_backgroundOverlay setAlpha:0];
        [_backgroundOverlay setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [_backgroundOverlay setBackgroundColor:[UIColor blackColor]];
        [parentView addSubview:_backgroundOverlay];
        
        //create a container to house the color gradient
        CGFloat colorPickerSize = (kColorPickerWindowWidth-kColorPickerWindowPadding*2);
        CGFloat colorGradientSize = colorPickerSize*2;
        _colorGradientContainer = [[UIScrollView alloc] initWithFrame:CGRectMake(kColorPickerWindowPadding, kColorPickerWindowPadding, colorPickerSize, colorPickerSize)];
        [_colorGradientContainer setBounces:NO];
        [_colorGradientContainer setClipsToBounds:YES];
        [_colorGradientContainer setContentSize:CGSizeMake(colorGradientSize, colorGradientSize)];
        [_colorGradientContainer setDelegate:self];
        [_colorGradientContainer setShowsHorizontalScrollIndicator:NO];
        [_colorGradientContainer setShowsVerticalScrollIndicator:NO];
        [_colorGradientContainer.layer setCornerRadius:4];
        
        //create the color gradient
        _colorGradient = [[ALSColorGradient alloc] initWithFrame:CGRectMake(0, 0, colorGradientSize, colorGradientSize)];
        [_colorGradient setAccessibleSize:colorPickerSize];
        [_colorGradient setHue:0];
        [_colorGradientContainer addSubview:_colorGradient];
        
        //create the view pointing to the center of the gradient
        UIView *colorPointer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kColorPointerRadius*2, kColorPointerHeightToCenter+kColorPointerRadius)];
        [colorPointer setBackgroundColor:[UIColor colorWithWhite:0.95 alpha:1]];
        [colorPointer setUserInteractionEnabled:NO];
        
        //create a view to preview the selected color
        _colorPreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kColorPointerPreviewRadius*2, kColorPointerPreviewRadius*2)];
        [_colorPreview setBackgroundColor:[UIColor redColor]];
        [_colorPreview.layer setCornerRadius:kColorPointerPreviewRadius];
        [colorPointer addSubview:_colorPreview];
        //create an inner shadow for the color preview
        ALSColorPickerInnerShadow *colorPreviewInnerShadow = [[ALSColorPickerInnerShadow alloc] initWithFrame:_colorPreview.bounds];
        CGPathRef colorPreviewInnerShadowPath = CGPathCreateWithEllipseInRect(colorPreviewInnerShadow.bounds, NULL);
        [colorPreviewInnerShadow setPath:colorPreviewInnerShadowPath];
        CGPathRelease(colorPreviewInnerShadowPath);
        [_colorPreview addSubview:colorPreviewInnerShadow];
        
        //create the path for the pointer view
        CGFloat distanceToCircleEdge = sqrt(kColorPointerHeightToCenter*kColorPointerHeightToCenter - kColorPointerRadius*kColorPointerRadius);
        CGFloat intersectionY = (kColorPointerHeightToCenter*kColorPointerHeightToCenter - kColorPointerRadius*kColorPointerRadius + distanceToCircleEdge*distanceToCircleEdge)/(2*kColorPointerHeightToCenter);
        CGFloat intersectionX = sqrt(kColorPointerRadius*kColorPointerRadius - (intersectionY-kColorPointerHeightToCenter)*(intersectionY-kColorPointerHeightToCenter));
        intersectionY = kColorPointerHeightToCenter+kColorPointerRadius - intersectionY;
        CGMutablePathRef maskPath = CGPathCreateMutable();
        CGPathAddArc(maskPath, NULL, kColorPointerRadius, kColorPointerRadius, kColorPointerRadius, -M_PI/2+0.1, M_PI*3/2-0.1, NO);
        CGPathMoveToPoint(maskPath, NULL, kColorPointerRadius+intersectionX, intersectionY);
        CGPathAddLineToPoint(maskPath, NULL, kColorPointerRadius, kColorPointerRadius+kColorPointerHeightToCenter);
        CGPathAddLineToPoint(maskPath, NULL, kColorPointerRadius-intersectionX, intersectionY);
        CGPathCloseSubpath(maskPath);
        
        //create the path for the pointer view's shadow
        CGFloat shadowDistanceToCircleEdge = sqrt(kColorPointerHeightToCenter*kColorPointerHeightToCenter - kColorPointerShadowRadius*kColorPointerShadowRadius);
        CGFloat shadowIntersectionY = (kColorPointerHeightToCenter*kColorPointerHeightToCenter - kColorPointerShadowRadius*kColorPointerShadowRadius + shadowDistanceToCircleEdge*shadowDistanceToCircleEdge)/(2*kColorPointerHeightToCenter);
        CGFloat shadowIntersectionX = sqrt(kColorPointerShadowRadius*kColorPointerShadowRadius - (shadowIntersectionY-kColorPointerHeightToCenter)*(shadowIntersectionY-kColorPointerHeightToCenter));
        shadowIntersectionY = kColorPointerHeightToCenter+kColorPointerShadowRadius - shadowIntersectionY;
        CGMutablePathRef shadowMaskPath = CGPathCreateMutable();
        CGPathAddArc(shadowMaskPath, NULL, kColorPointerShadowRadius, kColorPointerShadowRadius, kColorPointerShadowRadius, -M_PI/2+0.1, M_PI*3/2-0.1, NO);
        CGPathMoveToPoint(shadowMaskPath, NULL, kColorPointerShadowRadius+shadowIntersectionX, shadowIntersectionY);
        CGPathAddLineToPoint(shadowMaskPath, NULL, kColorPointerShadowRadius, kColorPointerShadowRadius+kColorPointerHeightToCenter);
        CGPathAddLineToPoint(shadowMaskPath, NULL, kColorPointerShadowRadius-shadowIntersectionX, shadowIntersectionY);
        CGPathCloseSubpath(shadowMaskPath);
        
        //create the layer to mask the color pointer
        CAShapeLayer *colorPointerMaskLayer = [[CAShapeLayer alloc] init];
        [colorPointerMaskLayer setContentsScale:[UIScreen mainScreen].scale];
        [colorPointerMaskLayer setFillColor:[[UIColor blackColor] CGColor]];
        [colorPointerMaskLayer setPath:maskPath];
        CGPathRelease(maskPath);
        [colorPointer.layer setMask:colorPointerMaskLayer];
        
        //create an inner shadow for the color gradient view
        ALSColorPickerInnerShadow *colorGradientInnerShadow = [[ALSColorPickerInnerShadow alloc] initWithFrame:_colorGradientContainer.frame];
        CGPathRef colorGradientInnerShadowPath = CGPathCreateWithRoundedRect(_colorGradientContainer.bounds, 4, 4, NULL);
        [colorGradientInnerShadow setPath:colorGradientInnerShadowPath];
        CGPathRelease(colorGradientInnerShadowPath);
        
        //create the view that allows the user to choose the hue
        _huePicker = [[UIImageView alloc] initWithFrame:CGRectMake(kColorPickerWindowPadding, colorPickerSize+kHuePickerIndicatorHeight+kHuePickerIndicatorMargin*2+kColorPickerWindowPadding, colorPickerSize, kHuePickerHeight)];
        [_huePicker setImage:[ALSColorGradient imageForHuePickerWithSize:_huePicker.bounds.size]];
        [_huePicker setUserInteractionEnabled:YES];
        [_huePicker.layer setCornerRadius:4];
        [_huePicker.layer setMasksToBounds:YES];
        ALSColorPanGestureRecognizer *hueDragRecognizer = [[ALSColorPanGestureRecognizer alloc] initWithTarget:self action:@selector(hueBarDragged:)];
        [_huePicker addGestureRecognizer:hueDragRecognizer];
        
        //create the hue picker indicator
        UIView *huePickerIndicator = [[UIView alloc] initWithFrame:CGRectMake(kColorPickerWindowPadding, colorPickerSize+kColorPickerWindowPadding+kHuePickerIndicatorMargin, colorPickerSize, kHuePickerIndicatorHeight)];
        _huePickerIndicatorLayer = [CAShapeLayer layer];
        _huePickerIndicatorLayer.path = [[self class] pathForHueIndicatorOfSize:huePickerIndicator.bounds.size atPercentage:0.5].CGPath;
        [_huePickerIndicatorLayer setFillColor:[UIColor clearColor].CGColor];
        [_huePickerIndicatorLayer setLineWidth:1];
        [_huePickerIndicatorLayer setStrokeColor:[UIColor colorWithWhite:0.66 alpha:1].CGColor];
        [huePickerIndicator.layer addSublayer:_huePickerIndicatorLayer];
        
        //create an inner shadow for the hue picker
        ALSColorPickerInnerShadow *huePickerInnerShadow = [[ALSColorPickerInnerShadow alloc] initWithFrame:_huePicker.bounds];
        CGPathRef huePickerInnerShadowPath = CGPathCreateWithRoundedRect(huePickerInnerShadow.bounds, 4, 4, NULL);
        [huePickerInnerShadow setPath:huePickerInnerShadowPath];
        CGPathRelease(huePickerInnerShadowPath);
        [_huePicker addSubview:huePickerInnerShadow];
        
        //create the accept and cancel buttons
        
        UIButton *firstButton;
        UIButton *secondButton;
        for(int i=0;i<2;i++) {
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(kColorPickerWindowWidth-kColorPickerWindowPadding-(i==0?kButtonMargins+kButtonSize*2:kButtonSize), colorPickerSize+kHuePickerIndicatorHeight+kHuePickerIndicatorMargin*2+kHuePickerHeight+kColorPickerWindowPadding*2, kButtonSize, kButtonSize)];
            [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
            [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [button setBackgroundColor:[UIColor whiteColor]];
            [button setTag:i];
            [button.layer setCornerRadius:kButtonSize/2];
            
            CAShapeLayer *buttonImage = [[CAShapeLayer alloc] init];
            [buttonImage setFillColor:[UIColor darkGrayColor].CGColor];
            UIBezierPath *buttonImagePath = [[UIBezierPath alloc] init];
            if(i==0) {
                firstButton = button;
                [buttonImagePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(-kButtonImageLineLength/2, kButtonImageLineLength/2-kButtonImageLineThickness, kButtonImageLineLength/2, kButtonImageLineThickness)]];
                [buttonImagePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(-kButtonImageLineThickness/2, -kButtonImageLineLength/2, kButtonImageLineThickness, kButtonImageLineLength)]];
                [buttonImagePath applyTransform:CGAffineTransformMakeRotation(M_PI/4)];
                [buttonImagePath applyTransform:CGAffineTransformMakeTranslation(kButtonSize/2*1.2, kButtonSize/2*1.1)];
            }
            else {
                secondButton = button;
                [buttonImagePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(-kButtonImageLineLength/2, -kButtonImageLineThickness/2, kButtonImageLineLength, kButtonImageLineThickness)]];
                [buttonImagePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(-kButtonImageLineThickness/2, -kButtonImageLineLength/2, kButtonImageLineThickness, kButtonImageLineLength)]];
                [buttonImagePath applyTransform:CGAffineTransformMakeRotation(M_PI/4)];
                [buttonImagePath applyTransform:CGAffineTransformMakeTranslation(kButtonSize/2, kButtonSize/2)];
            }
            [buttonImage setPath:buttonImagePath.CGPath];
            [button.layer addSublayer:buttonImage];
            
            [button.layer setShadowColor:[UIColor colorWithWhite:0.1 alpha:1].CGColor];
            [button.layer setShadowOffset:CGSizeMake(0, 2)];
            [button.layer setShadowOpacity:0.5];
            [button.layer setShadowRadius:2];
        }
        
        //create the text field
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(kColorPickerWindowPadding, firstButton.frame.origin.y+kButtonSize/2-kTextFieldHeight/2, firstButton.frame.origin.x-kColorPickerWindowPadding-kButtonMargins, kTextFieldHeight)];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [_textField setBackgroundColor:[UIColor whiteColor]];
        [_textField setDelegate:self];
        [_textField setFont:[UIFont fontWithName:@"Menlo-Regular" size:14]];
        [_textField setText:@"#FFFFFF"];
        [_textField setTextAlignment:NSTextAlignmentCenter];
        [_textField setTextColor:[UIColor colorWithWhite:0.2 alpha:1]];
        [_textField setTintColor:[UIColor colorWithWhite:0.2 alpha:1]];
        [_textField.layer setCornerRadius:4];
        
        UIView *textFieldShadowCaster = [[UIView alloc] initWithFrame:_textField.frame];
        [textFieldShadowCaster setUserInteractionEnabled:NO];
        [textFieldShadowCaster.layer setShadowColor:[UIColor colorWithWhite:0.1 alpha:1].CGColor];
        [textFieldShadowCaster.layer setShadowOffset:CGSizeMake(0, 2)];
        [textFieldShadowCaster.layer setShadowOpacity:0.5];
        [textFieldShadowCaster.layer setShadowPath:[UIBezierPath bezierPathWithRoundedRect:textFieldShadowCaster.bounds cornerRadius:4].CGPath];
        [textFieldShadowCaster.layer setShadowRadius:2];
        
        //set general information
        [self setAlpha:0];
        [self setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin];
        [self setBackgroundColor:[UIColor colorWithWhite:0.95 alpha:1]];
        [self setFrame:CGRectMake(0, 0, kColorPickerWindowWidth, colorPickerSize+kHuePickerHeight+kHuePickerIndicatorHeight+kHuePickerIndicatorMargin*2+kButtonSize+kColorPickerWindowPadding*3)];
        //[self setFrame:CGRectMake(0, 0, kColorPickerWindowWidth, 280+kColorPickerWindowPadding*3)];
        [self setUserInteractionEnabled:NO];
        [self setCenter:CGPointMake(parentView.bounds.size.width/2, parentView.bounds.size.height*3/2)];
        [self.layer setCornerRadius:4];
        
        //create the holding scrollView
        _scrollView = [[UIScrollView alloc] initWithFrame:parentView.bounds];
        [_scrollView setContentOffset:CGPointMake(0, parentView.bounds.size.height)];
        [_scrollView setContentSize:CGSizeMake(parentView.bounds.size.width, parentView.bounds.size.height*3)];
        [_scrollView setScrollEnabled:NO];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        [_scrollView setShowsVerticalScrollIndicator:NO];
        
        //create shadow behind color pointer
        UIView *colorPointerShadowCaster = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kColorPointerShadowRadius*2, kColorPointerHeightToCenter+kColorPointerShadowRadius)];
        [colorPointerShadowCaster setUserInteractionEnabled:NO];
        [colorPointerShadowCaster.layer setShadowColor:[UIColor colorWithWhite:0.1 alpha:1].CGColor];
        [colorPointerShadowCaster.layer setShadowOffset:CGSizeMake(0, kColorPointerShadowRadius-kColorPointerRadius+2)];
        [colorPointerShadowCaster.layer setShadowOpacity:0.5];
        [colorPointerShadowCaster.layer setShadowPath:shadowMaskPath];
        [colorPointerShadowCaster.layer setShadowRadius:1];
        CGPathRelease(shadowMaskPath);
        
        //position color picker
        [colorPointer setCenter:CGPointMake(self.bounds.size.width/2, (kColorPickerWindowPadding+colorPickerSize-kColorPointerHeightToCenter-kColorPointerRadius)/2)];
        [colorPointerShadowCaster setCenter:CGPointMake(self.bounds.size.width/2, (kColorPickerWindowPadding+colorPickerSize-kColorPointerHeightToCenter-kColorPointerShadowRadius)/2)];
        [_colorPreview setCenter:CGPointMake(kColorPointerRadius, kColorPointerRadius)];
        
        //add to the window
        [self addSubview:_colorGradientContainer];
        [self addSubview:colorGradientInnerShadow];
        [self addSubview:colorPointerShadowCaster];
        [self addSubview:colorPointer];
        [self addSubview:_huePicker];
        [self addSubview:huePickerIndicator];
        [self addSubview:textFieldShadowCaster];
        [self addSubview:_textField];
        [self addSubview:firstButton];
        [self addSubview:secondButton];
        [_scrollView addSubview:self];
        [parentView addSubview:_scrollView];
    }
    return self;
}

static void RGB_TO_HSL(CGFloat r, CGFloat g, CGFloat b, CGFloat *outH, CGFloat *outS, CGFloat *outL)
{
    CGFloat h,s,l,v,m,vm,r2,g2,b2;
    
    h = 0; s = 0;
    
    v = MAX(r, g);
    v = MAX(v, b);
    m = MIN(r, g);
    m = MIN(m, b);
    
    l = (m+v)/2.0f;
    
    if (l <= 0.0) {
        if(outH)
            *outH = h;
        if(outS)
            *outS = s;
        if(outL)
            *outL = l;
        return;
    }
    
    vm = v - m;
    s = vm;
    
    if (s > 0.0f) {
        s/= (l <= 0.5f) ? (v + m) : (2.0 - v - m);
    } else {
        if(outH)
            *outH = h;
        if(outS)
            *outS = s;
        if(outL)
            *outL = l;
        return;
    }
    
    r2 = (v - r)/vm;
    g2 = (v - g)/vm;
    b2 = (v - b)/vm;
    
    if (r == v){
        h = (g == m ? 5.0f + b2 : 1.0f - g2);
    }else if (g == v){
        h = (b == m ? 1.0f + r2 : 3.0 - b2);
    }else{
        h = (r == m ? 3.0f + g2 : 5.0f - r2);
    }
    
    h/=6.0f;
    
    if(outH)
        *outH = h;
    if(outS)
        *outS = s;
    if(outL)
        *outL = l;
}

- (void)buttonDown:(UIButton *)button {
    [button setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:1]];
    [button.layer setShadowOpacity:0.25];
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    for(CALayer *layer in button.layer.sublayers) {
        [layer setTransform:CATransform3DMakeTranslation(0, 1, 0)];
    }
    [CATransaction commit];
}

- (void)buttonTapped:(UIButton *)button {
    [button setBackgroundColor:[UIColor whiteColor]];
    [button.layer setShadowOpacity:0.5];
    if(self.completionBlock) {
        self.completionBlock(button.tag?nil:self.textField.text);
    }
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    for(CALayer *layer in button.layer.sublayers) {
        [layer setTransform:CATransform3DIdentity];
    }
    [CATransaction commit];
}

+ (UIColor *)colorFromHexString:(NSString *)string {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dismiss {
    [self setUserInteractionEnabled:NO];
    [self.backgroundOverlay setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.2 animations:^{
        [self.backgroundOverlay setAlpha:0];
        [self setAlpha:0];
        [self setTransform:CGAffineTransformMakeScale(0.5, 0.5)];
    } completion:^(BOOL finished) {
        [self.backgroundOverlay removeFromSuperview];
        [self.scrollView removeFromSuperview];
        [self removeFromSuperview];
    }];
}

+ (NSString *)hexStringFromColor:(UIColor *)color {
    static const CGFloat scale = 255.0f;
    CGFloat red, green, blue;
    [color getRed:&red green:&green blue:&blue alpha:NULL];
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(red*scale), lroundf(green*scale), lroundf(blue*scale)];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if(view != self.textField) {
        [self.textField endEditing:YES];
    }
    return view;
}

- (void)hueBarDragged:(UIPanGestureRecognizer *)recognizer {
    CGFloat huePercent = [recognizer locationInView:self.huePicker].x/self.huePicker.bounds.size.width;
    huePercent = MAX(0, MIN(1, huePercent));
    [self updateHue:huePercent];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    [UIView animateWithDuration:0.25 animations:^{
        [self.scrollView setContentOffset:CGPointMake(0, self.window.bounds.size.height)];
    }];
}

- (void)keyboardWillShow:(NSNotification*)notification {
    CGFloat keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    [UIView animateWithDuration:0.25 animations:^{
        [self.scrollView setContentOffset:CGPointMake(0, self.window.bounds.size.height+keyboardHeight)];
    }];
}

+ (UIBezierPath *)pathForHueIndicatorOfSize:(CGSize)size atPercentage:(CGFloat)percentage {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(size.width*percentage, size.height)];
    [path addCurveToPoint:CGPointMake(size.width, 0) controlPoint1:CGPointMake(size.width*(percentage), (size.height)*0.2) controlPoint2:CGPointMake(size.width, (size.height)*0.8)];
    [path moveToPoint:CGPointZero];
    [path addCurveToPoint:CGPointMake(size.width*percentage, size.height) controlPoint1:CGPointMake(0, (size.height)*0.8) controlPoint2:CGPointMake(size.width*percentage, (size.height)*0.2)];
    [path moveToPoint:CGPointMake(size.width*percentage, size.height)];
    [path addLineToPoint:CGPointMake(size.width*percentage, size.height+1)];
    [path closePath];
    return path;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint centerOffset = CGPointMake(scrollView.contentOffset.x+scrollView.bounds.size.width/2, scrollView.contentOffset.y+scrollView.bounds.size.height/2);
    UIColor *color = [_colorGradient colorAtPoint:centerOffset];
    [self.colorPreview setBackgroundColor:color];
    [self.textField setText:[[self class] hexStringFromColor:color]];
}

- (void)setHexColor:(NSString *)hexColor {
    UIColor *newColor = [[self class] colorFromHexString:hexColor];
    CGFloat r, g, b, hue, saturation, lightness;
    [newColor getRed:&r green:&g blue:&b alpha:NULL];
    RGB_TO_HSL(r, g, b, &hue, &saturation, &lightness);
    [self.colorGradientContainer setContentOffset:CGPointMake((self.colorGradientContainer.contentSize.width-self.colorGradientContainer.bounds.size.width)*saturation/2, (self.colorGradientContainer.contentSize.height-self.colorGradientContainer.bounds.size.height)*(1-lightness))];
    [self updateHue:hue];
    [self.textField setText:hexColor];
}

- (void)show {
    [UIView animateWithDuration:0.3 animations:^{
        [self.backgroundOverlay setAlpha:0.5];
        [self setAlpha:1];
    } completion:^(BOOL finished) {
        [self setUserInteractionEnabled:YES];
    }];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
    CATransform3D scale2 = CATransform3DMakeScale(1.1, 1.1, 1);
    CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
    CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
    
    NSArray *frameValues = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:scale1],[NSValue valueWithCATransform3D:scale2],[NSValue valueWithCATransform3D:scale3],[NSValue valueWithCATransform3D:scale4],nil];
    [animation setValues:frameValues];
    
    NSArray *frameTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],[NSNumber numberWithFloat:0.5],[NSNumber numberWithFloat:0.9],[NSNumber numberWithFloat:1.0],nil];
    [animation setKeyTimes:frameTimes];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = .3;
    
    [self.layer addAnimation:animation forKey:@"popup"];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    static NSCharacterSet *invalidCharacters;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"] invertedSet];
    });
    
    string = [[[string uppercaseString] componentsSeparatedByCharactersInSet:invalidCharacters] componentsJoinedByString:@""];
    
    [self.textField setText:[self.textField.text stringByReplacingCharactersInRange:range withString:string]];
    if(!self.textField.text.length || [self.textField.text characterAtIndex:0]!='#') {
        [self.textField setText:[@"#" stringByAppendingString:self.textField.text]];
    }
    if(self.textField.text.length>7) {
        [self.textField setText:[textField.text substringToIndex:7]];
    }
    
    //add self.textField.text.length == 4 to include 3 digit codes
    if(self.textField.text.length == 7) {
        NSString *previousText = self.textField.text;
        NSString *fullText = previousText;
        
        if(self.textField.text.length == 4) {
            NSString *hexCode = [self.textField.text substringFromIndex:1];
            fullText = [NSString stringWithFormat:@"#%@%@",hexCode,hexCode];
        }
        
        UIColor *newColor = [[self class] colorFromHexString:fullText];
        CGFloat r, g, b, hue, saturation, lightness;
        [newColor getRed:&r green:&g blue:&b alpha:NULL];
        RGB_TO_HSL(r, g, b, &hue, &saturation, &lightness);
        [self.colorGradientContainer setContentOffset:CGPointMake((self.colorGradientContainer.contentSize.width-self.colorGradientContainer.bounds.size.width)*saturation/2, (self.colorGradientContainer.contentSize.height-self.colorGradientContainer.bounds.size.height)*(1-lightness))];
        [self updateHue:hue];
        [self.textField setText:previousText];
    }
    
    return NO;
}

- (void)updateHue:(CGFloat)hue {
    [self.colorGradient setHue:hue];
    [self.huePickerIndicatorLayer setPath:[[self class] pathForHueIndicatorOfSize:self.huePickerIndicatorLayer.superlayer.bounds.size atPercentage:hue].CGPath];
    [self scrollViewDidScroll:(UIScrollView *)self.colorGradient.superview];
}

@end