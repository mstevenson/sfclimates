//
//  UtilityMethods.h
//  sfmcs
//
//  Created by Michelle Sintov on 10/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString *bayviewNSString;
extern NSString *castroNSString;
extern NSString *coleValleyNSString;
extern NSString *financialDistrictNSString;
extern NSString *glenParkNSString;
extern NSString *hayesValleyNSString;
extern NSString *innerRichmondNSString;
extern NSString *lakeMercedNSString;
extern NSString *missionNSString;
extern NSString *noeValleyNSString;
extern NSString *northBeachNSString;
extern NSString *outerRichmondNSString;
extern NSString *outerSunsetNSString;
extern NSString *potreroHillNSString;
extern NSString *presidioNSString;
extern NSString *somaNSString;
extern NSString *twinPeaksNSString;
extern NSString *westPortalNSString;

enum {
    smallConditionIcon,
    mediumConditionIcon,
    largeConditionIcon
} typedef ConditionIconSize;

// This protocol is implemented by the CityViewController and the NeighborhoodViewController
// to call setNeedsDisplay on their respective views. When new data arrives, sfmcsAppDelegate
// is contacted by the model, and sfmcsAppDelegate tells the visible view controller to update
// by calling drawNewData.
//
// This protocol could live somewhere else but this location was handy.
@protocol RequestRedrawDelegate
-(void) drawNewData;
@end

@protocol ShowSettings
-(void) showSettings;
@end

@interface UtilityMethods : NSObject {
	NSDictionary *conditionImageMappingDict;
    NSDateFormatter *dateFormatterForDate;
    NSDateFormatter *dateFormatterForDay;
    BOOL celsiusMode;
}

+ (UtilityMethods*)sharedInstance;
- (UIImage*)getConditionImage:(NSString*)conditionString withIsNight:(BOOL)isNight withIconSize:(ConditionIconSize)conditionIconSize;
- (BOOL)isNight:(NSDictionary*)weatherDict;
- (NSString*)getFormattedDate:(NSDate*)myDate prependString:(NSString*)prependStringValue;
- (NSString*)getDay:(NSDate*)myDate;
- (NSString*)makeTemperatureString:(int)temperatureInt showDegree:(BOOL)showDegree;
- (BOOL)isCelsiusMode;
- (void)setCelsiusMode:(BOOL)newCelsiusMode;

@end