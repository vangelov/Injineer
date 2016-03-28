
#import "INJContainer.h"

typedef NS_ENUM(NSUInteger, INJNameState) {
    INJNameStateUsed,
    INJNameStateBeingUsed
};

NSString * const INJNameAlreadyUsedException = @"INJNameAlreadyUsedException";
NSString * const INJMissingDependencyException = @"INJMissingDependencyException";
NSString * const INJCircularReferencesException = @"INJCircularReferencesException";

@interface INJContainer ()

@property (strong, nonatomic) NSMutableDictionary *providers;
@property (strong, nonatomic) NSMutableDictionary *singletonsCache;
@property (strong, nonatomic) NSMutableDictionary *instances;
@property (strong, nonatomic) NSMutableDictionary *nameState;
@property (strong, nonatomic) NSMutableDictionary *nameDependencies;

@end

@implementation INJContainer

- (id) init {
    self = [super init];
    
    if(self) {
        self.providers = [NSMutableDictionary dictionary];
        self.instances = [NSMutableDictionary dictionary];
        self.singletonsCache = [NSMutableDictionary dictionary];
        self.nameDependencies = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void) throwIfNameIsUsed: (NSString *) name {
    NSString *providerName = [self providerNameForName: name];

    if(self.instances[name] || self.providers[providerName]) {
        NSString *reason = [NSString stringWithFormat: @"Name '%@' has already been used.", name];
    
        @throw [NSException exceptionWithName: INJNameAlreadyUsedException
                                       reason: reason
                                     userInfo: nil];
    }
}

- (void) addInstance: (id) instance
             forName: (NSString *) name {
    
    [self throwIfNameIsUsed: name];
    
    self.instances[name] = instance;
}

- (void) addProviderForName: (NSString *) name
               dependencies: (NSArray *) dependencies
                    creator: (id (^)(NSDictionary *)) creator {
    
    [self addProviderForName: name
                dependencies: dependencies
                     options: 0
                     creator: creator];
}

- (void) addProviderForName: (NSString *) name
               dependencies: (NSArray *) dependencies
                    options: (INJProviderOptions) options
                    creator: (id (^)(NSDictionary *values)) creator {
    
    [self throwIfNameIsUsed: name];
    
    self.nameDependencies[name] = dependencies;
    
    __weak __typeof(self) weakSelf = self;
    NSString *providerName = [self providerNameForName: name];
    
    self.providers[providerName] = ^{
        BOOL isSingleton = options & INJProviderOptionSingleton;
        
        if(isSingleton && self.singletonsCache[name]) {
            return weakSelf.singletonsCache[name];
        }
        
        NSDictionary *values = [weakSelf valuesForDependencies: dependencies parentName: name];
        id result = creator(values);
        
        if(!(options & INJProviderOptionManualInit)) {
            [weakSelf initObject: result withValues: values];
        }
        
        if(isSingleton) {
            weakSelf.singletonsCache[name] = result;
        }
        
        return result;
    };
}

- (NSDictionary *) valuesForDependencies: (NSArray *) dependencies
                              parentName: (NSString *) parentName {
    
    NSMutableDictionary *dependenciesValues = [NSMutableDictionary dictionary];
    
    for(NSString *dependency in dependencies) {
        dependenciesValues[dependency] = [self valueForName: dependency];
    }
    
    return dependenciesValues;
}

- (void) initObject: (id) result withValues: (NSDictionary *) values {
    for(NSString *dependency in values.allKeys) {
        BOOL hasDependencyProperty = [result respondsToSelector: NSSelectorFromString(dependency)];
        
        if(hasDependencyProperty) {
            BOOL propertyNotSet = [result valueForKey: dependency] == nil;
            
            if(propertyNotSet) {
                SEL setterSelector = [self settterSelectorForDependency: dependency];
                
                if([result respondsToSelector: setterSelector]) {
                    [result setValue: values[dependency] forKey: dependency];
                }
            }
        }
    }
}

- (id) valueForName: (NSString *) name {
    if(self.instances[name]) {
        return self.instances[name];
    }
    
    if(self.providers[name]) {
        return self.providers[name];
    }
    
    NSString *providerName = [self providerNameForName: name];
    
    if(self.providers[providerName]) {
        id (^provider)(void) = self.providers[providerName];
        return provider();
    }
    
    return nil;
}

- (NSString *) providerNameForName: (NSString *) name {
    return [name stringByAppendingString: @"Provider"];
}

- (SEL) settterSelectorForDependency: (NSString *) dependency {
    NSString *firstLetterCapitalized = [[dependency substringToIndex: 1] uppercaseString];
    NSString *selectorString = [NSString stringWithFormat: @"set%@:",
                                [dependency stringByReplacingCharactersInRange: NSMakeRange(0,1)
                                                                    withString: firstLetterCapitalized]];
    
    return NSSelectorFromString(selectorString);
}

- (void) checkForErrors {
    [self checkForMissingValues];
    [self checkForCircularReferences];
}

- (void) checkForMissingValues {
    NSArray *names = self.nameDependencies.allKeys;
    
    for(NSString *name in names) {
        NSArray *dependencies = self.nameDependencies[name];
        
        for(NSString *dependency in dependencies) {
            if(![self hasValueForName: dependency]) {
                NSString *reason = [NSString stringWithFormat: @"Missing value for dependency '%@' for '%@'.", dependency, name];
                
                @throw [NSException exceptionWithName: INJMissingDependencyException
                                               reason: reason
                                             userInfo: nil];
            }
        }
    }
}

- (BOOL) hasValueForName: (NSString *) name {
    NSString *providerName = [self providerNameForName: name];
    
    return self.instances[name] != nil ||
           self.providers[name] != nil ||
           self.providers[providerName] != nil;
}


- (void) checkForCircularReferences {
    NSArray *names = [self.nameDependencies.allKeys sortedArrayUsingSelector: @selector(compare:)];
    NSMutableArray *cycles = [NSMutableArray array];

    self.nameState = [NSMutableDictionary dictionary];
    
    for(NSString *name in names) {
        if(!self.nameState[name]) {
            BOOL hasCycle = NO;
            NSMutableArray *path = [NSMutableArray array];
            
            [self checkForCycleStartingAtName: name
                                  currentPath: path
                                     hasCycle: &hasCycle];
            
            if(hasCycle) {
                [cycles addObject: path];
            }
        }
    }
    
    if(cycles.count > 0) {
        NSString *reason = [NSString stringWithFormat: @"Circular references found: %@", cycles];
        
        @throw [NSException exceptionWithName: INJCircularReferencesException
                                       reason: reason
                                     userInfo: @{
                                                 @"cycles": cycles
                                                 }];
    }
}

- (NSString *) checkForCycleStartingAtName: (NSString *) name
                               currentPath: (NSMutableArray *) path
                                  hasCycle: (BOOL *) hasCycle {
    
    if([self.nameState[name] isEqual: @(INJNameStateBeingUsed)]) {
        [path insertObject: name atIndex: 0];
        return name;
    }
    
    if([self.nameState[name] isEqual: @(INJNameStateUsed)]) {
        return nil;
    }
    
    self.nameState[name] = @(INJNameStateBeingUsed);
    
    for(NSString *dependency in self.nameDependencies[name]) {
        NSString *name2 = [self checkForCycleStartingAtName: dependency
                                                currentPath: path
                                                   hasCycle: hasCycle];

        if (name2) {
            [path insertObject: name atIndex: 0];
            
            if ([name2 isEqualToString: name]) {
                *hasCycle = YES;
            }
            
            return name2;
        }
    }
    
    self.nameState[name] = @(INJNameStateUsed);
    
    return nil;
}

@end