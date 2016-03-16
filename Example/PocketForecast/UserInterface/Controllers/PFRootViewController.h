////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2015, Typhoon Framework Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>
#import "PaperFoldView.h"


@class JBReplaceableRootNavigationController;
@class PFCitiesListViewController;
@class PFAddCityViewController;

typedef enum
{
    PFSideViewStateHidden,
    PFSideViewStateShowing
} PFSideViewState;

@interface PFRootViewController : UIViewController <PaperFoldViewDelegate>
{
    UINavigationController *_navigator;
    UIView *_mainContentViewContainer;
    PFSideViewState _sideViewState;

    UIViewController *_citiesListController;
    UIViewController *_addCitiesController;
}

@property(nonatomic, strong) PaperFoldView *view;
@property(nonatomic, strong) PFCitiesListViewController *(^citiesListViewControllerProvider)(void);
@property(nonatomic, strong) PFAddCityViewController *(^addCityViewControllerProvider)(void);

/**
* Creates a root view controller instance, with the initial main content view controller, and side view controller.
*/
- (instancetype)initWithMainContentViewController:(UIViewController *)mainContentViewController;

/**
* Sets main content view, with an animated transition.
*/
- (void)pushViewController:(UIViewController *)viewController;

- (void)pushViewController:(UIViewController *)viewController replaceRoot:(BOOL)replaceRoot;

- (void)popViewControllerAnimated:(BOOL)animated;

- (void)showCitiesListController;

- (void)dismissCitiesListController;

- (void)showAddCitiesController;

- (void)dismissAddCitiesController;

- (void)toggleSideViewController;


@end
