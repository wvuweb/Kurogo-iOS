#import "ShuttleRouteCache.h"
#import "ShuttleStop.h"
#import "ShuttleStopLocation.h"
#import "CoreDataManager.h"

@implementation ShuttleRouteCache 

@dynamic routeID;
@dynamic title;
@dynamic interval;
@dynamic isSafeRide;
@dynamic summary;
@dynamic stops;
@dynamic sortOrder;
@dynamic agency;
@dynamic color;
@dynamic routeDescription;

- (NSSet *)stops {
	return [self valueForKey:@"stops"];
}

@end
