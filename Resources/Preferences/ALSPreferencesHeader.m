#import "ALSPreferencesHeader.h"
#import "PSSpecifier.h"
#import "SBWallpaperController.h"

@interface ALSPreferencesHeader()

@property (nonatomic, strong) UIImage *lockscreenWallpaper;
@property (nonatomic, strong) UIImageView *wallpaperView;

@end

@implementation ALSPreferencesHeader

static CGFloat _wallpaperViewHeight;

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ALSPreferencesHeader" specifier:specifier];
    if(self) {
        //called to initialize _wallpaperViewHeight if we haven't already
        [self preferredHeightForWidth:0];
        
        //create the wallpaper view
        _wallpaperView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -44, self.bounds.size.width, _wallpaperViewHeight)];
        [_wallpaperView setClipsToBounds:YES];
        [_wallpaperView setContentMode:UIViewContentModeScaleAspectFill];
        
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
    
        [self addSubview:_wallpaperView];
    }
    
    return self;
}

- (void)layoutSubviews {
    //check if wallpaperView size changed
    CGSize wallpaperViewSize = self.wallpaperView.bounds.size;
    [super layoutSubviews];
    if(!CGSizeEqualToSize(wallpaperViewSize, self.wallpaperView.bounds.size)) {
        [self updateWallpaper];
    }
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    static CGFloat preferredHeight;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        _wallpaperViewHeight = ceilf(sqrtf(MIN(screenBounds.size.width, screenBounds.size.height)*20));
        
        preferredHeight = _wallpaperViewHeight+100;
    });
    return preferredHeight;
}

- (void)updateWallpaper {
    //get wallpaper image and find the needed scale
    //UIImage *wallpaperImage = [[SBWallpaperController sharedInstance] _wallpaperViewForVariant:1];
    
    //crop and position lockscreen wallpaper
    /*if(self.wallpaperView.bounds.size.width && self.lockscreenWallpaper) {
        CGFloat widthScale = self.wallpaperView.bounds.size.width/self.lockscreenWallpaper.size.width;
        CGFloat scaledHeight = self.lockscreenWallpaper.size.height*widthScale;
        
        //draw the image, scaled and cropped
        UIGraphicsBeginImageContextWithOptions(self.wallpaperView.bounds.size, YES, [[UIScreen mainScreen] scale]);
        CGRect wallpaperRect = CGRectMake(0, (self.wallpaperView.bounds.size.height - scaledHeight)/2, self.wallpaperView.bounds.size.width, self.wallpaperView.bounds.size.height);
        [self.lockscreenWallpaper drawInRect:wallpaperRect];
        
        //get the image
        UIImage *sizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self.wallpaperView setImage:sizedImage];
    }*/
    
    //[self.wallpaperView setImage:self.lockscreenWallpaper];
}

@end