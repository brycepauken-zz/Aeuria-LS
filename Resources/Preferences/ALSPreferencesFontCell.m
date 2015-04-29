#import "ALSPreferencesFontCell.h"

#import "ALSPreferencesFontPicker.h"

@interface ALSPreferencesFontCell()

@property (nonatomic, strong) UILabel *fontLabel;
@property (nonatomic, strong) ALSPreferencesFontPicker *fontPicker;

@end

@implementation ALSPreferencesFontCell

static const int kLabelFontSize = 17;
static const int kLabelSpacing = 40;

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil specifier:specifier];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if(self) {
        _fontLabel = [[UILabel alloc] init];
        [_fontLabel setTextAlignment:NSTextAlignmentRight];
        
        [self addSubview:_fontLabel];
    }
    return self;
}

- (void)handlePress:(UILongPressGestureRecognizer*)sender {
    [super handlePress:sender];
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self showFontPicker];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    //find the normal label and position our custom label to not conflict with it
    for(UIView *immediateSubview in self.subviews) {
        for(UIView *view in immediateSubview.subviews) {
            if([view isKindOfClass:[UILabel class]] && view!=self.fontLabel) {
                [self.fontLabel setFrame:CGRectMake(view.frame.origin.x+view.frame.size.width+kLabelSpacing, 0, self.bounds.size.width-kLabelSpacing-view.frame.size.width-view.frame.origin.x*2, self.bounds.size.height)];
            }
        }
    }
}

- (void)setValue:(id)value {
    [super setValue:value];
    
    [self.fontLabel setFont:[UIFont fontWithName:value size:kLabelFontSize]];
    [self.fontLabel setText:value];
    
}

- (void)showFontPicker {
    self.fontPicker = [[ALSPreferencesFontPicker alloc] initWithParentView:self.parentTableView.superview];
    __weak ALSPreferencesFontPicker *weakFontPicker = self.fontPicker;
    __weak ALSPreferencesFontCell *weakSelf = self;
    [self.fontPicker setCompletionBlock:^(NSString *fontName) {
        [weakFontPicker dismiss];
        if(fontName) {
            [weakSelf setValue:fontName];
            [weakSelf savePreferenceValue:fontName];
        }
    }];
    [self.fontPicker setFontName:self.internalValue];
    [self.fontPicker show];
}

@end