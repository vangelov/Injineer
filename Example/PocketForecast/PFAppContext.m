//
//  PFAppContext.m
//  PocketForecast
//
//  Created by Vladi on 1/20/16.
//  Copyright © 2016 typhoon. All rights reserved.
//

#import "PFAppContext.h"
#import "PFWeatherClientBasicImpl.h"
#import "PFWeatherReportDaoFileSystemImpl.h"
#import "PFCityDaoUserDefaultsImpl.h"
#import "PFThemeFactory.h"
#import "PFTheme.h"
#import "PFWeatherReportView.h"
#import "PFWeatherReportViewController.h"
#import "PFRootViewController.h"
#import "PFCitiesListViewController.h"
#import "PFAddCityViewController.h"

#import "INJContainer.h"

#import "NanoFrame.h"

@implementation PFAppContext

- (void) initContainer: (INJContainer *) container {
    NSString *confFile = [[NSBundle mainBundle] pathForResource: @"Configuration"
                                                     ofType: @"plist"];
    
    [container addInstance: [NSUserDefaults standardUserDefaults]
                   forName: @"userDefaults"];
    
    [container addInstance: [[NSMutableDictionary alloc] initWithContentsOfFile: confFile]
                   forName: @"conf"];
    
    [container addInstance: self.themes forName: @"themes"];
    
    [container addProviderForName: @"weatherClient"
                      dependencies: @[ @"weatherReportDao", @"conf" ]
                          options: INJProviderOptionSingleton
                          creator: ^id(NSDictionary *values) {
                              PFWeatherClientBasicImpl *weatherClient = [[PFWeatherClientBasicImpl alloc] init];
                            
                              weatherClient.serviceUrl = [NSURL URLWithString: values[@"conf"][@"service.url"]];
                              weatherClient.apiKey = values[@"conf"][@"api.key"];
                              weatherClient.daysToRetrieve = [values[@"conf"][@"days.to.retrive"] intValue];
                            
                              return weatherClient;
                          }];
    
    [container addInstance: [[PFWeatherReportDaoFileSystemImpl alloc] init]
                  forName: @"weatherReportDao"];
    
    [container addProviderForName: @"cityDao"
                      dependencies: @[ @"userDefaults" ]
                          options: INJProviderOptionSingleton
                          creator: ^id(NSDictionary *dependencies) {
                              return [[PFCityDaoUserDefaultsImpl alloc] initWithDefaults: dependencies[@"userDefaults"]];
                          }];
    
    [container addProviderForName: @"theme"
                      dependencies: @[ @"themes" ]
                          options: INJProviderOptionSingleton | INJProviderOptionManualInit
                          creator: ^id(NSDictionary *dependencies) {
                              PFThemeFactory *themeFactory = [[PFThemeFactory alloc] initWithThemes: dependencies[@"themes"]];
                              return [themeFactory sequentialTheme];
                          }];
    
    [container addProviderForName: @"weatherReportView"
                      dependencies: @[ @"theme" ]
                          creator: ^id(NSDictionary *dependencies) {
                              return [[PFWeatherReportView alloc] init];;
                          }];
    
    [container addProviderForName: @"weatherReportViewController"
                      dependencies: @[ @"weatherReportView", @"weatherClient", @"weatherReportDao", @"cityDao", @"rootViewControllerProvider" ]
                          creator: ^id (NSDictionary *dependencies) {
                              return [[PFWeatherReportViewController alloc] initWithView: dependencies[@"weatherReportView"]
                                                                           weatherClient: dependencies[@"weatherClient"]
                                                                        weatherReportDao: dependencies[@"weatherReportDao"]
                                                                                 cityDao: dependencies[@"cityDao"]];;
                          }];
    
    [container addProviderForName: @"rootViewController"
                      dependencies: @[ @"weatherReportViewController", @"citiesListViewControllerProvider", @"addCityViewControllerProvider" ]
                          options: INJProviderOptionSingleton
                          creator:^id (NSDictionary *dependencies) {
                              return [[PFRootViewController alloc] initWithMainContentViewController: dependencies[@"weatherReportViewController"]];;
                          }];
    
    [container addProviderForName: @"window"
                      dependencies: @[ @"rootViewController" ]
                          options: INJProviderOptionSingleton
                          creator: ^id(NSDictionary *dependencies) {
                              return [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
                          }];
    
    [container addProviderForName: @"citiesListViewController"
                      dependencies: @[ @"cityDao", @"theme", @"rootViewControllerProvider" ]
                          creator: ^id(NSDictionary *dependencies) {
                              return [[PFCitiesListViewController alloc] initWithCityDao: dependencies[@"cityDao"]
                                                                                   theme: dependencies[@"theme"]];
                          }];
    
    [container addProviderForName: @"addCityViewController"
                      dependencies: @[ @"cityDao", @"theme", @"weatherClient", @"rootViewControllerProvider" ]
                          creator: ^id(NSDictionary *dependencies) {
                              return [[PFAddCityViewController alloc] initWithNibName: @"AddCity"
                                                                               bundle: [NSBundle mainBundle]];;
                          }];
    
    [container checkForErrors];
}


- (NSArray *) themes {
    PFTheme *cloudsOverTheCityTheme = [[PFTheme alloc] init];
    cloudsOverTheCityTheme.backgroundResourceName = @"bg3.png";
    cloudsOverTheCityTheme.navigationBarColor = [UIColor colorWithHexRGB:0x641d23];
    cloudsOverTheCityTheme.forecastTintColor = [UIColor colorWithHexRGB:0x641d23];
    cloudsOverTheCityTheme.controlTintColor = [UIColor colorWithHexRGB:0x7f9588];
    
    PFTheme *lightsInTheRainTheme = [[PFTheme alloc] init];
    lightsInTheRainTheme.backgroundResourceName = @"bg4.png";
    lightsInTheRainTheme.navigationBarColor = [UIColor colorWithHexRGB:0xeaa53d];
    lightsInTheRainTheme.forecastTintColor = [UIColor colorWithHexRGB:0x722d49];
    lightsInTheRainTheme.controlTintColor = [UIColor colorWithHexRGB:0x722d49];
    
    PFTheme *beachTheme = [[PFTheme alloc] init];
    beachTheme.backgroundResourceName = @"bg5.png";
    beachTheme.navigationBarColor = [UIColor colorWithHexRGB:0x37b1da];
    beachTheme.forecastTintColor = [UIColor colorWithHexRGB:0x37b1da];
    beachTheme.controlTintColor = [UIColor colorWithHexRGB:0x0043a6];
    
    PFTheme *sunsetTheme = [[PFTheme alloc] init];
    sunsetTheme.backgroundResourceName = @"bg5.png";
    sunsetTheme.navigationBarColor = [UIColor colorWithHexRGB:0x0a1d3b];
    sunsetTheme.forecastTintColor = [UIColor colorWithHexRGB:0x0a1d3b];
    sunsetTheme.controlTintColor = [UIColor colorWithHexRGB:0x606970];
    
    return @[ cloudsOverTheCityTheme, lightsInTheRainTheme, beachTheme, sunsetTheme ];
}

@end
