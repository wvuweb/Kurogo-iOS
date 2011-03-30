#import "EventDetailTableView.h"
#import "CalendarModel.h"
#import "KGOContactInfo.h"
#import "ThemeConstants.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGORequestManager.h"
#import "KGODetailPageHeaderView.h"

@interface EventDetailTableView (Private)

- (void)setupTableHeader;

@end

@implementation EventDetailTableHeader : KGODetailPageHeaderView

- (UILabel *)descriptionLabel
{
    if (!_descriptionLabel) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.font = [[KGOTheme sharedTheme] fontForTableFooter];
        _descriptionLabel.textColor = [[KGOTheme sharedTheme] textColorForTableFooter];
        _descriptionLabel.backgroundColor = [UIColor clearColor];
        _descriptionLabel.numberOfLines = 0;
    }
    return _descriptionLabel;
}

- (void)inflateSubviews
{
    [super inflateSubviews];
    
    if (_descriptionLabel) {
        CGSize constraintSize = CGSizeMake(self.frame.size.width - 20, 2000);
        CGRect frame = _descriptionLabel.frame;
        frame.size = [_descriptionLabel.text sizeWithFont:_descriptionLabel.font constrainedToSize:constraintSize];
        frame.origin.x = 10;
        frame.origin.y = self.frame.size.height;
        _descriptionLabel.frame = frame;
        
        [self addSubview:_descriptionLabel];
        
        frame = self.frame;
        frame.size.height += _descriptionLabel.frame.size.height + 10;
        self.frame = frame;
    }
}

- (void)setDetailItem:(id<KGOSearchResult>)item
{
    [super setDetailItem:item];

    if (_descriptionLabel) {
        [_descriptionLabel removeFromSuperview];
        [_descriptionLabel release];
        _descriptionLabel = nil;
    }
}

- (void)dealloc
{
    [_descriptionLabel release];
    [super dealloc];
}

@end


@implementation EventDetailTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        
        _shareController = [(KGOShareButtonController *)[KGOShareButtonController alloc] initWithDelegate:self];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        
        _shareController = [(KGOShareButtonController *)[KGOShareButtonController alloc] initWithDelegate:self];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
    }
    return self;
}

- (void)dealloc
{
	[_shareController release];
    self.event = nil;
    self.delegate = nil;
    self.dataSource = nil;
    [super dealloc];
}

#pragma mark - Event

- (KGOEventWrapper *)event
{
    return _event;
}

- (void)setEvent:(KGOEventWrapper *)event
{
    [_event release];
    _event = [event retain];
    
    NSLog(@"%@ %@ %@", [_event description], _event.title, _event.location);
    
    [_sections release];
    NSMutableArray *mutableSections = [NSMutableArray array];

    NSMutableArray *basicInfo = [NSMutableArray array];
    if (_event.location) {
        if (_event.briefLocation) {
            [basicInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  _event.briefLocation, @"title",
                                  _event.location, @"subtitle",
                                  TableViewCellAccessoryMap, @"accessory",
                                  nil]];
        } else {
            [basicInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  _event.location, @"title",
                                  TableViewCellAccessoryMap, @"accessory",
                                  nil]];
        }
    }
    
    if (_event.attendees) {
        [basicInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              [NSString stringWithFormat:@"%d others attending", _event.attendees.count], @"title",
                              KGOAccessoryTypeChevron, @"accessory",
                              nil]];
    }
    
    if (basicInfo.count) {
        [mutableSections addObject:basicInfo];
    }
    
    if (_event.organizers) {
        NSMutableArray *contactInfo = [NSMutableArray array];
        for (KGOAttendeeWrapper *organizer in _event.organizers) {
            for (KGOEventContactInfo *aContact in organizer.contactInfo) {
                NSString *type;
                NSString *accessory;
                if ([aContact.type isEqualToString:@"phone"]) {
                    type = NSLocalizedString(@"Organizer phone", nil);
                    accessory = TableViewCellAccessoryPhone;
                } else if ([aContact.type isEqualToString:@"email"]) {
                    type = NSLocalizedString(@"Organizer email", nil);
                    accessory = TableViewCellAccessoryEmail;
                } else if ([aContact.type isEqualToString:@"url"]) {
                    type = NSLocalizedString(@"Event website", nil);
                    accessory = TableViewCellAccessoryExternal;
                } else {
                    type = NSLocalizedString(@"Contact", nil);
                    accessory = KGOAccessoryTypeNone;
                }
                
                [contactInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                        type, @"title",
                                        aContact.value, @"subtitle",
                                        accessory, @"accessory",
                                        nil]];
            }
        }
        
        [mutableSections addObject:contactInfo];
    }
    
    _sections = [mutableSections copy];
    
    [self reloadData];
    [self setupTableHeader];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_sections objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellStyle style = UITableViewCellStyleDefault;
    NSDictionary *cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData objectForKey:@"subtitle"]) {
        style = UITableViewCellStyleSubtitle;
    }
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d", style];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier] autorelease];
    }
    
    cell.textLabel.text = [cellData objectForKey:@"title"];
    cell.detailTextLabel.text = [cellData objectForKey:@"subtitle"];
    cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:[cellData objectForKey:@"accessory"]];
    
    return cell;
}

#pragma mark - UITableViewDelegate


#pragma mark - Table header

- (void)setupTableHeader
{
    if (!_headerView) {
        _headerView = [[EventDetailTableHeader alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 1)];
        _headerView.showsBookmarkButton = YES;
    }
    _headerView.detailItem = self.event;
    _headerView.showsShareButton = [self twitterUrl] != nil;
    
    // time
    // TODO: consolidate date formatter objects
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterNoStyle];
    NSString *dateString = [formatter stringFromDate:_event.startDate];
    
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *timeString = nil;
    if (_event.endDate) {
        timeString = [NSString stringWithFormat:@"%@\n%@-%@",
                      dateString,
                      [formatter stringFromDate:_event.startDate],
                      [formatter stringFromDate:_event.endDate]];
    } else {
        timeString = [NSString stringWithFormat:@"%@\n%@",
                      dateString,
                      [formatter stringFromDate:_event.startDate]];
    }
    _headerView.subtitleLabel.text = timeString;
    _headerView.descriptionLabel.text = _event.summary;
    
    [_headerView inflateSubviews];
    
    self.tableHeaderView = _headerView;
}

- (void)headerView:(KGODetailPageHeaderView *)headerView shareButtonPressed:(id)sender
{
    [_shareController shareInView:self];
}

#pragma mark KGOShareButtonDelegate

- (NSString *)actionSheetTitle {
	return [NSString stringWithString:@"Share this event"];
}

- (NSString *)emailSubject {
    return _event.title;
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this event...\n%@\n%@\n%@",
            _event.title,
            [self twitterUrl],
            _event.summary];
}

- (NSString *)fbDialogPrompt {
	return nil;
}

- (NSString *)fbDialogAttachment {
    NSString *attachment = [NSString stringWithFormat:
                            @"{\"name\":\"%@\","
                            "\"href\":\"%@\","
                            "\"description\":\"%@\"}",
                            _event.title, [self twitterUrl], _event.summary];
    return attachment;
}

- (NSString *)twitterUrl {
    NSString *urlString = nil;
    for (KGOAttendeeWrapper *organizer in _event.organizers) {
        for (KGOContactInfo *contact in organizer.contactInfo) {
            if ([contact.type isEqualToString:@"url"]) {
                urlString = contact.value;
                break;
            }
        }
        if (urlString)
            break;
    }
    
    if (!urlString) {
        KGOCalendar *calendar = [_event.calendars anyObject];
        NSString *startString = [NSString stringWithFormat:@"%.0f", [_event.startDate timeIntervalSince1970]];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                _event.identifier, @"id",
                                calendar.identifier, @"calendar",
                                calendar.type, @"type",
                                startString, @"time",
                                nil];
        
        urlString = [[NSURL URLWithQueryParameters:params baseURL:[[KGORequestManager sharedManager] serverURL]] absoluteString];
    }
    
    return urlString;
}

- (NSString *)twitterTitle {
	return _event.title;
}

@end
