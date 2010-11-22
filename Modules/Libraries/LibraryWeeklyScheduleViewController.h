//
//  LibraryWeeklyScheduleViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/20/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LibraryWeeklyScheduleViewController : UITableViewController {

	
	NSArray * daysOfTheWeek;
	NSDictionary * weeklySchedule;
}

-(void)setDaysOfWeek:(NSArray *) days weeklySchedule:(NSDictionary *)schedule;

@end
