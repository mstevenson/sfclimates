//
//  CityTableViewController.m
//  sfmcs
//
//  Created by Michelle Sintov on 2/16/12.
//  Copyright (c) 2012 Baker Beach Software. All rights reserved.
//

#import "CityTableViewController.h"
#import "NeighborhoodViewController.h"
#import "Constants.h"
#import "NSString+Temperature.h"

@implementation CityTableViewController
{
    id<NSObject> _modelObserver;
}

/*- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Add info button
    UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];

    _modelObserver = [[NSNotificationCenter defaultCenter] addObserverForName:ModelChangedNotificationName
                                                                       object:nil queue:nil
                                                                   usingBlock:^(NSNotification *note) {
                                                                       _weatherDataModel = [[note userInfo] objectForKey:@"model"];
                                                                       [self drawNewData];
                                                                   }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RequestRefreshNotificationName
                                                        object:self
                                                      userInfo:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_modelObserver];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self drawNewData];

    [super viewWillAppear:animated];
}

- (void)showSettings
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ShowSettingsNotificationName object:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)createTableSections
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    for (Neighborhood *neighborhood in [_weatherDataModel neighborhoods])
    {
        NSString *neighborhoodName = [neighborhood name];
        NSString *firstLetter = [neighborhoodName substringToIndex:1];

        NSMutableArray *letterArray = [dictionary objectForKey:firstLetter];
        if (!letterArray)
        {
            letterArray = [[NSMutableArray alloc] init];
            [dictionary setObject:letterArray forKey:firstLetter];
        }
        [letterArray addObject:[neighborhood observation]];
    }
    
    self.sections = dictionary;
}

- (void)drawNewData
{
    [self createTableSections];

    [self.view performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.sections allKeys] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CityCurrentConditionCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"CityTableViewCell" owner:self options:nil];
        cell = _cityTableViewCell;
        self.cityTableViewCell = nil;
    }

    Observation *observation = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];

    UILabel *label = (UILabel *)[cell viewWithTag:1];
    label.text = [observation name];
    
    label = (UILabel *)[cell viewWithTag:2];
    label.text = [observation condition];

    UIImageView *imageView = (UIImageView *)[cell viewWithTag:3];
    [imageView setImage:[[ConditionImages sharedInstance] getConditionImage:[observation condition]
                                                               withIsNight:[_weatherDataModel isNight]
                                                              withIconSize:mediumConditionIcon]];

    label = (UILabel *)[cell viewWithTag:4];
    label.text = [NSString formatTemperature:(int)[observation temperature]
                                  showDegree:YES];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Observation *observation = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];

    NeighborhoodViewController *vc = [[NeighborhoodViewController alloc] init];
     
    vc.neighborhoodName = [observation name];
    vc.weatherDataModel = self.weatherDataModel;
 
    [self.navigationController pushViewController:vc animated:YES];
}

@end
