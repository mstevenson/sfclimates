//
//  Observation.h
//  sfmcs
//
//  Created by Gary Grossman on 1/17/15.
//
//

#import <Foundation/Foundation.h>

@interface Observation : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *condition;
@property (nonatomic) double temperature;

- (id)initWithJSON:(NSDictionary*)jsonRecord;

@end