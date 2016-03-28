
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, INJProviderOptions) {
    INJProviderOptionSingleton = 1 << 0,
    INJProviderOptionManualInit = 1 << 1
};

extern NSString * const INJNameAlreadyUsedException;
extern NSString * const INJMissingDependencyException;
extern NSString * const INJCircularReferencesException;

@interface INJContainer : NSObject

- (void) addInstance: (id) instance
             forName: (NSString *) name;

- (void) addProviderForName: (NSString *) name
               dependencies: (NSArray *) dependencies
                    creator: (id (^)(NSDictionary *values)) creator;

- (void) addProviderForName: (NSString *) name
               dependencies: (NSArray *) dependencies
                    options: (INJProviderOptions) options
                    creator: (id (^)(NSDictionary *values)) creator;

- (id) valueForName: (NSString *) name;

- (void) checkForErrors;

@end