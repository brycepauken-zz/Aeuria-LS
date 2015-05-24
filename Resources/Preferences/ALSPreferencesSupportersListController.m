#import "ALSPreferencesSupportersListController.h"

#import "PSSpecifier.h"

@interface ALSPreferencesSupportersListController()

@property (nonatomic, strong) NSArray *supporters;

@end

@implementation ALSPreferencesSupportersListController

- (void)buttonTapped:(id)button {
    NSString *link = [button propertyForKey:@"supporterLink"];
    if(link) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
    }
}

- (id)specifiers {
    NSMutableArray *specifiers = [[NSMutableArray alloc] init];
    
    PSSpecifier* donateButton = [PSSpecifier preferenceSpecifierNamed:@"Donate if you'd like. Thanks!" target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
    [donateButton setProperty:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=XPP27CAYVPPTC" forKey:@"supporterLink"];
    donateButton->action = @selector(buttonTapped:);
    [donateButton setProperty:@(50) forKey:@"height"];
    [specifiers addObject:donateButton];
    
    if(!self.supporters.count) {
        PSSpecifier *title = [PSSpecifier preferenceSpecifierNamed:@"Loading supporters list..." target:self set:NULL get:NULL detail:Nil cell:PSGroupCell edit:Nil];
        [specifiers addObject:title];
    }
    else {
        PSSpecifier *title = [PSSpecifier preferenceSpecifierNamed:@"Thank you all so much!" target:self set:NULL get:NULL detail:Nil cell:PSGroupCell edit:Nil];
        [specifiers addObject:title];
        for(NSArray *supporter in self.supporters) {
            PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:[supporter objectAtIndex:0] target:self set:NULL get:NULL detail:Nil cell:(supporter.count>1?PSButtonCell:PSTitleValueCell) edit:Nil];
            if(supporter.count > 1) {
                [specifier setProperty:[supporter objectAtIndex:1] forKey:@"supporterLink"];
                specifier->action = @selector(buttonTapped:);
            }
            [specifier setProperty:@(50) forKey:@"height"];
            [specifiers addObject:specifier];
        }
    }
    _specifiers = specifiers;
    return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://brycepauken.com/aeurials/supporters.php"]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(!connectionError) {
            _supporters = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        }
        if(!_supporters.count) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to load supporters list." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        }
        else {
            [self reloadSpecifiers];
        }
    }];
}

@end