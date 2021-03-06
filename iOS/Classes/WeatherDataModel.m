//
//  WeatherDataModel.m
//  sfmcs
//
//  Created by Michelle Sintov on 9/6/11.
//  Copyright 2015 Baker Beach Software, LLC. All rights reserved.
//

#import "WeatherDataModel.h"
#import "JSON.h"
#import "NSDictionary+JSONHelpers.h"

@implementation WeatherDataModel
{
    NSDictionary *_neighborhoods;
    int _sunriseInSecondsSinceMidnight;
    int _sunsetInSecondsSinceMidnight;
}

- (id)init
{
    if (self = [super init])
    {
        _neighborhoods = @{};
    }

    return self;
}

- (id)initWithJSON:(NSDictionary*)weatherDict
{
    if (self = [super init])
    {
        _timeOfLastUpdate = [weatherDict dateForKey:@"timeOfLastUpdate"];
        _timeOfNextPull   = [weatherDict dateForKey:@"timeOfNextPull"];

        _sunriseInSecondsSinceMidnight = [weatherDict integerForKey:@"sunrise"];
        _sunsetInSecondsSinceMidnight = [weatherDict integerForKey:@"sunset"];

        NSMutableDictionary *observations = [[NSMutableDictionary alloc] init];
        for (NSDictionary *jsonRecord in [weatherDict arrayForKey:@"observations"])
        {
            Observation *observation = [[Observation alloc] initWithJSON:jsonRecord];
            [observations setObject:observation forKey:[observation name]];
        }
        
        NSMutableDictionary *forecasts = [[NSMutableDictionary alloc] init];
        for (NSArray *jsonSubArray in [weatherDict arrayForKey:@"forecasts"])
        {
            for (NSDictionary *jsonRecord in jsonSubArray)
            {
                Forecast *forecast = [[Forecast alloc] initWithJSON:jsonRecord];
                NSMutableArray *forecastsArray = [forecasts objectForKey:[forecast name]];
                if (!forecastsArray)
                {
                    forecastsArray = [[NSMutableArray alloc] init];
                    [forecasts setObject:forecastsArray forKey:[forecast name]];
                }
                [forecastsArray addObject:forecast];
            }
        }
        
        NSMutableDictionary *neighborhoods = [[NSMutableDictionary alloc] init];
        for (NSDictionary *jsonRecord in [weatherDict arrayForKey:@"neighborhoods"])
        {
            NSString *name = [jsonRecord stringForKey:@"name"];
            
            CGRect rect = CGRectMake([jsonRecord doubleForKey:@"x"],
                                     [jsonRecord doubleForKey:@"y"],
                                     [jsonRecord doubleForKey:@"width"],
                                     [jsonRecord doubleForKey:@"height"]);
            
            Neighborhood *neighborhood = [[Neighborhood alloc] initWithName:name
                                                                       rect:rect
                                                                observation:[observations objectForKey:name]
                                                                  forecasts:[forecasts objectForKey:name]];
            [neighborhoods setObject:neighborhood forKey:name];
        }
        _neighborhoods = neighborhoods;
        _isNight = [self calcIsNight];
    }
    return self;
}

- (NSArray*)neighborhoods
{
    return [_neighborhoods allValues];
}

- (Neighborhood*)neighborhoodByName:(NSString*)name
{
    return [_neighborhoods objectForKey:name];
}

-(BOOL)calcIsNight
{
    // Determine the number of seconds since midnight of the current day according to the time on the phone.
    BOOL isNight = NO;
    
    NSTimeZone* pacificTimeZone = [NSTimeZone timeZoneWithName:@"America/Los_Angeles"];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:pacificTimeZone];
    
    NSDateComponents *components = [calendar components:kCFCalendarUnitSecond|kCFCalendarUnitHour|kCFCalendarUnitMinute fromDate:[NSDate date]];
    if (components)
    {
        NSInteger seconds = [components second];
        NSInteger hours = [components hour];
        NSInteger minutes = [components minute];
        
        NSInteger currentSecondsSinceMidnight = ((hours*60)+minutes)*60 + seconds;
        isNight = (currentSecondsSinceMidnight < _sunriseInSecondsSinceMidnight ||
                   currentSecondsSinceMidnight > _sunsetInSecondsSinceMidnight);
    }
    return isNight;
}

@end

