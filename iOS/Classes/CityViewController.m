//
//  CityViewController.m
//  sfmcs
//
//  Created by Michelle Sintov on 9/16/11.
//  Copyright 2015 Baker Beach Software, LLC. All rights reserved.
//

#import "CityViewController.h"
#import "Neighborhood.h"
#import "NeighborhoodViewController.h"
#import "NSDate+Formatters.h"
#import "NSString+Temperature.h"
#import "Constants.h"

#define ZOOM_STEP 1.5

@interface CityViewController()
- (CGContextRef) newARGBBitmapContextFromImage:(CGImageRef)inImage;
- (NSString*) getPixelColorAtPointAsHexString:(CGPoint)point;
- (void)handleSingleTap:(UITapGestureRecognizer*)sender;

@property (nonatomic, readonly) NSDictionary *colorToNeighborhoodHitTestDict;
@end

@implementation CityViewController
{
    NSDictionary *_tempFontAttributes;
    NSDictionary *_labelFontAttributes;
    id<NSObject> _modelObserver;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Add info button
    UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];

    // Add single tap gesture
	UITapGestureRecognizer *tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	[self.view addGestureRecognizer:tapgr];

    // Maintain background image aspect ratio
    float width = _cityMapImageView.frame.size.width;
    float offset = UIApplication.sharedApplication.statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
    [_cityMapImageView setFrame:CGRectMake(0, offset, width, width * 1.3125)];
    
    _labelFontAttributes = @{
        NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:10.0],
        NSForegroundColorAttributeName: [UIColor colorWithWhite: 0.70 alpha:1]
    };
    _tempFontAttributes = @{
        NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0],
        NSForegroundColorAttributeName: [UIColor colorWithWhite: 1.0 alpha:1]
    };

    _modelObserver = [[NSNotificationCenter defaultCenter] addObserverForName:ModelChangedNotificationName
                                                                       object:nil queue:nil
                                                                   usingBlock:^(NSNotification *note) {
                                                                       _weatherDataModel = [[note userInfo] objectForKey:@"model"];
                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                           [self drawNewData];
                                                                       });
                                                                   }];
    
    [_refreshButton addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventTouchUpInside];
}

- (void)refreshData
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RequestRefreshNotificationName
                                                        object:self
                                                      userInfo:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self drawNewData];

    [super viewWillAppear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.lastUpdated = nil;
    self.cityMapImageView = nil;
    self.refreshButton = nil;

    nameToTempViewDict = nil;
    nameToCondViewDict = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:_modelObserver];
}

- (void)showSettings
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ShowSettingsNotificationName object:nil];
}

- (void)drawNewData
{
    if (_weatherDataModel.neighborhoods.count == 0)
    {
        return;
    }
    
    NSArray *neighborhoodsArray = [_weatherDataModel neighborhoods];

    if (!nameToCondViewDict)
    {
        nameToCondViewDict = [[NSMutableDictionary alloc] init];
        nameToTempViewDict = [[NSMutableDictionary alloc] init];

        CGSize tempTextSize = [@"88º" sizeWithAttributes:_tempFontAttributes];

        for (Neighborhood *neighborhood in neighborhoodsArray)
        {
            NSString *name = [neighborhood name];
            CGRect condRect = [neighborhood rect];
            // fudge the vertical offset to match the repositioned background image
            condRect.origin.y -= self.navigationController.navigationBar.frame.size.height;

            UIImageView *imageView = [[UIImageView alloc] initWithFrame:condRect];
            [_cityMapImageView addSubview:imageView];
            [nameToCondViewDict setObject:imageView forKey:name];

            CGSize labelSize = [name sizeWithAttributes:_labelFontAttributes];
            CGFloat centerX = condRect.origin.x+condRect.size.width/2;
            CGRect labelRect = CGRectMake(centerX-labelSize.width/2, condRect.origin.y+condRect.size.height*7/8,
                                          labelSize.width, labelSize.height);
            UILabel *label = [[UILabel alloc] initWithFrame:(CGRect)labelRect];

            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:name
                                                                                 attributes:_labelFontAttributes];
            [label setAttributedText:attributedText];
            [_cityMapImageView addSubview:label];

            CGRect tempRect = CGRectMake(condRect.origin.x-tempTextSize.width * 15/16,
                                         condRect.origin.y+(condRect.size.height-tempTextSize.height)/2,
                                         tempTextSize.width, tempTextSize.height);
            UILabel *tempLabel = [[UILabel alloc] initWithFrame:(CGRect)tempRect];

            NSAttributedString *tempAttributedText = [[NSAttributedString alloc] initWithString:@""
                                                                                     attributes:_tempFontAttributes];
            [tempLabel setAttributedText:tempAttributedText];
            [_cityMapImageView addSubview:tempLabel];
            [nameToTempViewDict setObject:tempLabel forKey:name];
        }
    }

    BOOL isNight = [_weatherDataModel isNight];

    // Set city map background.
    if (isNight)
    {
        [_cityMapImageView setImage:[UIImage imageNamed:@"cityMapNight"]];
        [self.view setBackgroundColor:[UIColor colorWithRed:(70.0/255.0) green:(70.0/255.0) blue:(70.0/255.0) alpha:1]];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
        [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor lightGrayColor]];
    }
    else
    {
        [_cityMapImageView setImage:[UIImage imageNamed:@"cityMapDay"]];
        [self.view setBackgroundColor:[UIColor colorWithRed:0 green:(75.0/255.0) blue:(133.0/255.0) alpha:1]];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:(43.0/255.0) green:(151.0/255.0) blue:(215.0/255.0) alpha:0.5]];
    }

    for (Neighborhood *neighborhood in neighborhoodsArray)
	{
        Observation *observation = [neighborhood observation];
        if (!observation)
        {
            continue;
        }

        NSString *neighborhoodName = [neighborhood name];

        UILabel *tempLabel = [nameToTempViewDict objectForKey:neighborhoodName];
        if (tempLabel != nil)
        {
            // Get temperature string
            int tempInt = (int)[observation temperature];
            NSString *temperatureString = [NSString formatTemperature:tempInt showDegree:YES];
            
            tempLabel.attributedText = [[NSAttributedString alloc] initWithString:temperatureString attributes:_tempFontAttributes];
            [tempLabel sizeToFit];
        }

		UIImageView* imageView = [nameToCondViewDict objectForKey:neighborhoodName];
        if (imageView != nil)
        {
            // Get condition image
            NSString *conditionString = [observation condition];
            UIImage *conditionImage = [[ConditionImages sharedInstance] getConditionImage:conditionString withIsNight:isNight withIconSize:smallConditionIcon];

            [imageView setImage:conditionImage];
        }
    }

	_lastUpdated.text = [[_weatherDataModel timeOfLastUpdate] formatDateWithPrefix:@"Updated "];
}

- (void)handleSingleTap:(UITapGestureRecognizer*)sender
{
	if (sender.state == UIGestureRecognizerStateEnded)
	{
		// Get the patchwork map color at the tap location and use it to figure
		// out which neighborhood was selected based on color.
		CGPoint tapPoint = [sender locationInView:_cityMapImageView];

		NSString *colorAsString = [self getPixelColorAtPointAsHexString:tapPoint];
		if (colorAsString == nil) return;
		
		NSString *neighborhoodName = [self.colorToNeighborhoodHitTestDict objectForKey:colorAsString];
		if (!neighborhoodName)
        {
            return;
        }

        NeighborhoodViewController *vc = [[NeighborhoodViewController alloc] init];

        vc.neighborhoodName = neighborhoodName;
        vc.weatherDataModel = _weatherDataModel;

        [self.navigationController pushViewController:vc animated:YES];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc. that aren't in use.
}
*/

- (NSDictionary *)colorToNeighborhoodHitTestDict
{
	if (!colorToNeighborhoodHitTestDict)
	{
		NSBundle* nsBundle = [NSBundle mainBundle];
		if (nsBundle == nil) return nil;
		
		NSString * plistPath = [nsBundle pathForResource:@"ColorToNeighborhoodHitTest" ofType:@"plist"];
		if (plistPath == nil) return nil;
		
		colorToNeighborhoodHitTestDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
		if (colorToNeighborhoodHitTestDict == nil) return nil;
    }
	return colorToNeighborhoodHitTestDict;
}

- (CGContextRef) newARGBBitmapContextFromImage:(CGImageRef)inImage
{
	// Get image width, height. We'll use the entire image.
	size_t pixelsWide = CGImageGetWidth(inImage);
	size_t pixelsHigh = CGImageGetHeight(inImage);
	
	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	size_t bitmapBytesPerRow = (pixelsWide * 4);
	
	// Use the generic RGB color space.
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL) return NULL;
	
	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
	// per component. Regardless of what the source image format is
	// (CMYK, Grayscale, and so on) it will be converted over to the format
	// specified here by CGBitmapContextCreate.
	CGContextRef context = CGBitmapContextCreate (NULL,
                                                  pixelsWide,
                                                  pixelsHigh,
                                                  8,      // bits per component
                                                  bitmapBytesPerRow,
                                                  colorSpace,
                                                  kCGImageAlphaPremultipliedFirst);

	if (context == NULL) DLog(@"Context not created!");
	
	// Make sure and release colorspace before returning
	CGColorSpaceRelease(colorSpace);
	
	return context;
}

- (NSString*) getPixelColorAtPointAsHexString:(CGPoint)point
{
	NSString *colorAsString = nil;
	
	// Get Quartz image data.
	UIImage *patchWorkMap = [UIImage imageNamed:@"patchwork.png"];
	if (!patchWorkMap)
    {
        return nil;
    }

    // Scale the tap point to the image size
    CGSize viewSize = [_cityMapImageView bounds].size;
    CGSize imageBounds = [patchWorkMap size];
    point.x *= imageBounds.width/viewSize.width;
    point.y *= imageBounds.height/viewSize.height;

	//If the image data has been purged because of memory constraints,
	//invoking this method forces that data to be loaded back into memory.
	//Reloading the image data may incur a performance penalty.
	CGImageRef inImage = patchWorkMap.CGImage;
	
	// Create offscreen bitmap context to draw the image into. Format ARGB is 4 bytes for each pixel
	CGContextRef cgctx = [self newARGBBitmapContextFromImage:inImage];
	if (cgctx == NULL) { return nil;}
	
    size_t w = CGImageGetWidth(inImage);
	size_t h = CGImageGetHeight(inImage);
	CGRect rect = {{0,0},{w,h}};
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextDrawImage(cgctx, rect, inImage);
	
	// Now we can get a pointer to the image data associated with the bitmap context.
    unsigned char *data = (unsigned char*)CGBitmapContextGetData(cgctx);
    if (data != NULL)
    {
		//offset locates the pixel in the data from x,y.
		//4 for 4 bytes of data per pixel, w is width of one row of data.
		//int offset = 4*((w*round(point.y))+round(point.x));
		int offset = ((w*round(point.y))+round(point.x));
        if (offset > 0 && offset <= w * h)
        {
            unsigned char *pixelPtr = data+offset*4;
            colorAsString = [NSString stringWithFormat:@"%02X%02X%02X", pixelPtr[1], pixelPtr[2], pixelPtr[3]];
        }
		//DLog(@"%@", colorAsString);
	}
	
	CGContextRelease(cgctx);
	
	return colorAsString;
}

@end
