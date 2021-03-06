//
//  sfmcsAppDelegate.m
//  sfmcs
//
//  Created by Michelle Sintov on 9/6/11.
//  Copyright 2015 Baker Beach Software, LLC. All rights reserved.
//

#import "sfmcsAppDelegate.h"
#import "CityTableViewController.h"
#import "SettingsViewController.h"
#import "ConditionImages.h"
#import "Constants.h"
#import <stdlib.h>
#import <time.h>

@interface sfmcsAppDelegate()
@property (nonatomic, retain) WeatherDataModel *weatherDataModel;

- (void)requestServerData;
- (void)invalidateTimer;
- (void)firstUserExperience;
@end

@implementation sfmcsAppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (void)dealloc
{
	[self invalidateTimer];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _weatherDataLoader = [[WeatherDataLoader alloc] init];
    _weatherDataModel = [_weatherDataLoader loadCachedWeatherData];
    if (!_weatherDataModel)
    {
        _weatherDataModel = [[WeatherDataModel alloc] init];
    }
    
    // Set up segmented control.
    CityViewController *cityViewController = [[CityViewController alloc] init];
    [cityViewController setWeatherDataModel:self.weatherDataModel];
    
    CityTableViewController *cityTableViewController = [[CityTableViewController alloc] init];
    [cityTableViewController setWeatherDataModel:self.weatherDataModel];
    
    NSArray * viewControllers = [NSArray arrayWithObjects:cityViewController, cityTableViewController, nil];
    
    self.navigationController = [[UINavigationController alloc] init];
    
    self.segmentsController = [[SegmentsController alloc] initWithNavigationController:self.navigationController viewControllers:viewControllers];

    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Map", @"By Name", nil]];

    [self.segmentedControl addTarget:self.segmentsController
                              action:@selector(indexDidChangeForSegmentedControl:)
                    forControlEvents:UIControlEventValueChanged];
    
	[self requestServerData];
    
    [self firstUserExperience];
    
    _window.rootViewController = self.navigationController;

	[_window addSubview:self.navigationController.view];
	[self.window makeKeyAndVisible];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestServerData)
                                                 name:RequestRefreshNotificationName
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSettings)
                                                 name:ShowSettingsNotificationName
                                               object:nil];

    return YES;
}

- (void)requestServerData
{
	// Request latest weather data on our server. Actual request will run asynchronously.
	//
	// If the latest data isn't retrieved completely before the first time we draw the UI,
	// we will use the data we cached in the plist on the previous run of the app.
	//
	// If no property list is found, no data will be shown.
    [_weatherDataLoader downloadWeatherDataWithCompletionHandler:^(NSError *error, WeatherDataModel *newModel) {
        if (error != nil)
        {
            _numConsecutiveNetworkRequestFailures++;
            
            // Try again but with exponential backoff.
            [self scheduleNetworkRequest:((1+((_numConsecutiveNetworkRequestFailures - 1) * 2))*60)];
        }
        else
        {
            _weatherDataModel = newModel;

            [[NSNotificationCenter defaultCenter] postNotificationName:ModelChangedNotificationName
                                                                object:self
                                                              userInfo:@{@"model": newModel}];

            _numConsecutiveNetworkRequestFailures = 0;
            
            // Retrieve next time to retrieve weather data and schedule the timer.
            NSTimeInterval timeOfNextPullInSecondsFromNow = [[_weatherDataModel timeOfNextPull] timeIntervalSinceNow];
            
            [self scheduleNetworkRequest:timeOfNextPullInSecondsFromNow];
        }
    }];
}

- (void)scheduleNetworkRequest:(NSTimeInterval)timeOfNextPullInSecondsFromNow
{
	if (timeOfNextPullInSecondsFromNow < 0) 
	{
		DLog(@"Error: timeOfNextPull is earlier than now. Aborting scheduleNetworkRequest. Check the server to see if it is serving old data.");
		return;
	}
    			  
	_networkRequestTimer = [NSTimer scheduledTimerWithTimeInterval:timeOfNextPullInSecondsFromNow target:self selector:@selector(requestServerData) userInfo:nil repeats:NO];
}

- (void)showSettings
{
    SettingsViewController *vc = [[SettingsViewController alloc] init];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)invalidateTimer
{
	[_networkRequestTimer invalidate];
    _networkRequestTimer = nil;
}

- (void)firstUserExperience
{
    self.segmentedControl.selectedSegmentIndex = 0;
    [self.segmentsController indexDidChangeForSegmentedControl:self.segmentedControl];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	[self requestServerData];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	
	// Delete the timer. When the app becomes active again, we will request data immediately from the server, and then schedule the next timer.
	[self invalidateTimer];
}

/*
- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
}
*/

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	// Your implementation of this method should free up as much memory as possible
	// by purging cached data objects that can be recreated (or reloaded from disk)
	// later. You use this method in conjunction with the didReceiveMemoryWarning
	// of the UIViewController class and the UIApplicationDidReceiveMemoryWarningNotification
	// notification to release memory throughout your application.
	//
	// It is strongly recommended that you implement this method. If your application does
	// not release enough memory during low-memory conditions, the system may terminate it outright.
	
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

@end
