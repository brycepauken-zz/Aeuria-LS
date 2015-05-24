@interface PSSpecifier : NSObject {
    @public SEL action;
}

typedef enum PSCellType {
    PSGroupCell,
    PSLinkCell,
    PSLinkListCell,
    PSListItemCell,
    PSTitleValueCell,
    PSSliderCell,
    PSSwitchCell,
    PSStaticTextCell,
    PSEditTextCell,
    PSSegmentCell,
    PSGiantIconCell,
    PSGiantCell,
    PSSecureEditTextCell,
    PSButtonCell,
    PSEditTextViewCell,
} PSCellType;

- (NSString *)identifier;
+ (id)preferenceSpecifierNamed:(NSString*)title target:(id)target set:(SEL)set get:(SEL)get detail:(Class)detail cell:(PSCellType)cell edit:(Class)edit;
- (NSMutableDictionary *)properties;
- (id)propertyForKey:(NSString*)key;
- (void)setProperty:(id)property forKey:(NSString*)key;
- (NSArray *)values;

@end