#import "ALSPMainView.h"

#import "ALSPPreferenceManager.h"
#import "ALSPThemeTableCell.h"

@interface SpringBoard : UIApplication
- (void)_relaunchSpringBoardNow;
@end

@interface ALSPMainView()

@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, copy) void (^didSelectFinish)();
@property (nonatomic, strong) ALSPThemeTableCell *respringCell;
@property (nonatomic) BOOL respringCellEnabled;
@property (nonatomic, strong) NSArray *themeList;
@property (nonatomic, strong) UITableView *themeTableView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation ALSPMainView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _respringCellEnabled = NO;
        
        _titleLabel = [[UILabel alloc] init];
        [_titleLabel setFont:[UIFont fontWithName:@"Avenir-Light" size:28]];
        [_titleLabel setText:@"AeuriaLS"];
        [_titleLabel setTextColor:[UIColor colorWithWhite:0.3 alpha:1]];
        [_titleLabel sizeToFit];
        
        _descriptionLabel = [[UILabel alloc] init];
        [_descriptionLabel setFont:[UIFont systemFontOfSize:14]];
        [_descriptionLabel setNumberOfLines:0];
        [_descriptionLabel setText:@"Select the themes containing icons\nthat you want to be themed\nonly on the home screen.\n\nIf your theme is currently selected in\nWinterboard, it will be deselected\n(with your approval!)"];
        [_descriptionLabel setTextAlignment:NSTextAlignmentCenter];
        [_descriptionLabel setTextColor:[UIColor lightGrayColor]];
        [_descriptionLabel sizeToFit];
        
        _themeTableView = [[UITableView alloc] init];
        [_themeTableView registerClass:[ALSPThemeTableCell class] forCellReuseIdentifier:@"ALSPThemeCell"];
        [_themeTableView setScrollEnabled:NO];
        [_themeTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self addSubview:_themeTableView];
        
        [self setBackgroundColor:[UIColor colorWithWhite:0.98 alpha:1]];
        [self.layer setMasksToBounds:NO];
        [self.layer setShadowColor:[UIColor colorWithWhite:0.1 alpha:1].CGColor];
        [self.layer setShadowOffset:CGSizeMake(0, 1)];
        [self.layer setShadowOpacity:0.5];
        [self.layer setShadowRadius:2];
        
        [self addSubview:_titleLabel];
        [self addSubview:_descriptionLabel];
        [self addSubview:_themeTableView];
        [_themeTableView setDataSource:self];
        [_themeTableView setDelegate:self];
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
    if(buttonIndex == 1) {
        if(self.didSelectFinish) {
            self.didSelectFinish();
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.titleLabel setCenter:CGPointMake(self.bounds.size.width/2, 50)];
    [self.descriptionLabel setCenter:CGPointMake(self.bounds.size.width/2, 150)];
    [self.themeTableView setFrame:CGRectMake(0, 225, self.bounds.size.width, self.themeTableView.contentSize.height)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ALSPThemeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ALSPThemeCell" forIndexPath:indexPath];
    
    [cell setRespringLabelHidden:indexPath.row>0];
    [cell setTopDividerHidden:indexPath.row>0];
    if(indexPath.row == 0) {
        self.respringCell = cell;
        [cell setUserInteractionEnabled:self.respringCellEnabled];
        [cell setCheckmarkHidden:YES];
        [cell setSnowflakeHidden:YES];
    }
    else {
        [[self.themeList objectAtIndex:indexPath.row-1] setObject:cell forKey:@"Cell"];
        HOIThemeStatus status = [[[self.themeList objectAtIndex:indexPath.row-1] objectForKey:@"Status"] integerValue];
        [cell setCheckmarkHidden:status!=HOIThemeStatusActivePreviouslyNone && status!=HOIThemeStatusActivePreviouslyWinterboardActive];
        [cell setSnowflakeHidden:status!=HOIThemeStatusWinterboardActive];
        [cell setText:[[self.themeList objectAtIndex:indexPath.row-1] objectForKey:@"Name"]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if(indexPath.row == 0 && self.respringCellEnabled) {
        system("killall -9 SpringBoard");
    }
    else {
        HOIThemeStatus newStatus = [ALSPPreferenceManager toggledStatus:[[[self.themeList objectAtIndex:indexPath.row-1] objectForKey:@"Status"] integerValue]];
        
        __weak __typeof__(self) weakSelf = self;
        self.didSelectFinish = ^{
            [weakSelf setRespringCellEnabled:YES];
            if(weakSelf.respringCell) {
                [weakSelf.respringCell setUserInteractionEnabled:YES];
            }
            ALSPThemeTableCell *cell = [[weakSelf.themeList objectAtIndex:indexPath.row-1] objectForKey:@"Cell"];
            if(cell) {
                [[weakSelf.themeList objectAtIndex:indexPath.row-1] setObject:@(newStatus) forKey:@"Status"];
                
                HOICellStatus newCellStatus;
                switch(newStatus) {
                    case HOIThemeStatusNone:
                        newCellStatus = HOICellStatusNone;
                        break;
                    case HOIThemeStatusWinterboardActive:
                        newCellStatus = HOICellStatusSnowflakeVisible;
                        break;
                    case HOIThemeStatusActivePreviouslyNone: case HOIThemeStatusActivePreviouslyWinterboardActive:
                        newCellStatus = HOICellStatusCheckmarkVisible;
                        break;
                    default:
                        newCellStatus = HOICellStatusNone;
                        break;
                }
                [cell animateCellStatusChange:newCellStatus];
            }
            
            [ALSPPreferenceManager statusChangedForTheme:[[weakSelf.themeList objectAtIndex:indexPath.row-1] objectForKey:@"Name"] inFolder:[[weakSelf.themeList objectAtIndex:indexPath.row-1] objectForKey:@"Folder"] status:newStatus];
        };
        if(newStatus == HOIThemeStatusActivePreviouslyWinterboardActive) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Active Theme" message:@"\nThe theme you've selected is currently active in Winterboard, and will have to be automatically deselected there so Home Only Icons can work properly.\n\nDo you wish to continue?" delegate:self cancelButtonTitle:@"Never Mind" otherButtonTitles:@"Yes Please", nil];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        }
        else {
            self.didSelectFinish();
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    self.themeList = [ALSPPreferenceManager themeList];
    return self.themeList.count+1;
}

- (CGFloat)totalHeight {
    return self.themeTableView.frame.origin.y+self.themeTableView.frame.size.height;
}

@end
