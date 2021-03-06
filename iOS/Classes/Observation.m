//
//  Observation.m
//  sfmcs
//
//  Copyright 2015 Baker Beach Software, LLC. All rights reserved.
//

#import "Observation.h"
#import "NSDictionary+JSONHelpers.h"

@implementation Observation

- (id)initWithJSON:(NSDictionary *)jsonRecord
{
    if (self = [super init])
    {
        _name = [jsonRecord stringForKey:@"name"];
        _temperature = [jsonRecord doubleForKey:@"current_temperature"];
        _wind = [jsonRecord doubleForKey:@"current_wind"];
        _windDirection = [jsonRecord doubleForKey:@"current_wind_direction"];
        _condition = [jsonRecord stringForKey:@"current_condition"];
    }
    return self;
}


@end
