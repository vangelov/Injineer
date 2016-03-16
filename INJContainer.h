
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, INJProviderOptions) {
    INJProviderOptionSingleton = 1 << 0,
    INJProviderOptionManualInit = 1 << 1
};

@interface INJContainer : NSObject

- (void) addInstance: (id) instance
             forName: (NSString *) name;

- (void) addProviderForName: (NSString *) name
                depedencies: (NSArray *) dependencies
                    creator: (id (^)(NSDictionary *values)) creator;

- (void) addProviderForName: (NSString *) name
                depedencies: (NSArray *) dependencies
                    options: (INJProviderOptions) options
                    creator: (id (^)(NSDictionary *values)) creator;

- (id) valueForName: (NSString *) name;

- (void) checkForErrors;

@end