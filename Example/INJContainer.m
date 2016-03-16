
#import "INJContainer.h"

@interface INJContainer ()

@property (strong, nonatomic) NSMutableDictionary *providers;
@property (strong, nonatomic) NSMutableDictionary *singletonsCache;
@property (strong, nonatomic) NSMutableDictionary *instances;
@property (strong, nonatomic) NSMutableDictionary *usedNames;
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

- (void) addInstance: (id) instance
             forName: (NSString *) name {
    
    self.instances[name] = instance;
}

- (void) addProviderForName: (NSString *) name
                depedencies: (NSArray *) dependencies
                    creator: (id (^)(NSDictionary *)) creator {
    
    [self addProviderForName: name
                 depedencies: dependencies
                     options: 0
                     creator: creator];
}

- (void) addProviderForName: (NSString *) name
                depedencies: (NSArray *) dependencies
                    options: (INJProviderOptions) options
                    creator: (id (^)(NSDictionary *values)) creator {
    
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
    [self checkForCycleReferences];
}

- (void) checkForMissingValues {
    NSArray *names = self.nameDependencies.allKeys;
    
    for(NSString *name in names) {
        NSArray *dependencies = self.nameDependencies[name];
        
        for(NSString *dependency in dependencies) {
            if(![self hasValueForName: dependency]) {
                NSString *reason = [NSString stringWithFormat: @"Missing value for dependency '%@' for '%@'.", dependency, name];
                
                @throw [NSException exceptionWithName: @"MissingDependencyException"
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


- (void) checkForCycleReferences {
    NSArray *names = self.nameDependencies.allKeys;
    NSMutableArray *cycleReferences = [NSMutableArray array];
    
    self.usedNames = [NSMutableDictionary dictionary];
    
    for(NSString *name in names) {
        if(!self.usedNames[name]) {
            NSMutableArray *path = [NSMutableArray array];
            [self outputTopologicallySortedPathForName: name inArray: path];
            
            NSArray *cycleReferencesInPath = [self cycleReferencesForPath: path];
            
            if(cycleReferences.count > 0) {
                [cycleReferences addObjectsFromArray: cycleReferencesInPath];
            }
        }
    }
    
    if(cycleReferences.count > 0) {
        NSString *reason = [NSString stringWithFormat: @"Cycle references found:\n%@", cycleReferences];
        
        @throw [NSException exceptionWithName: @"CycleReferenceException"
                                       reason: reason
                                     userInfo: nil];
    }
}

- (void) outputTopologicallySortedPathForName: (NSString *) name
                                      inArray: (NSMutableArray *) path {
    
    self.usedNames[name] = @(YES);
    
    for(NSString *dependency in self.nameDependencies[name]) {
        if(!self.usedNames[dependency]) {
            [self outputTopologicallySortedPathForName: dependency inArray: path];
        }
    }
    
    [path insertObject: name atIndex: 0];
}

- (NSArray *) cycleReferencesForPath: (NSArray *) path {
    NSMutableArray *cycleReferences = [NSMutableArray array];
    
    for(NSInteger i = 0; i < path.count; i++) {
        NSArray *currentName = path[i];
        NSArray *previousNames = [path subarrayWithRange: NSMakeRange(0, i)];
        
        for(NSString *dependency in self.nameDependencies[currentName]) {
            if([previousNames containsObject: dependency]) {
                [cycleReferences addObject: @{
                                              @"from": currentName,
                                              @"to": dependency
                                              }];
            }
        }
    }
    
    return cycleReferences;
}

@end