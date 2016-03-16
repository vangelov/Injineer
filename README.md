# Injineer

Injineer is simpler than other DI frameworks for Objective-C but just as powerful. 
The framework introduces no dependencies in your code, so using it is almost completely transparent (see below).

## Example application

I converted the example of another DI framework (Typhoon) to use Injineer. You can find it the Example folder.
I didn't udpdate the unit tests though, because they rely on custom functionality of Typhoon.

## How it works

The whole project consists of a single class: INJContainer. This the place where to register your objects and their dependencies.

You can add two types of objects: instaces and providers.

### Instances

```Objective-C

- (void) addInstance: (id) instance 
             forName: (NSString *) name;
             
```

Instances are just objects which have a name. They don't have dependencies. If an object depends on a name registered to an instance, it's the value you 
set here that will be injected. 

### Providers

```Objective-C

- (void) addProviderForName: (NSString *) name
                depedencies: (NSArray *) dependencies
                    creator: (id (^)(NSDictionary *values)) creator;

- (void) addProviderForName: (NSString *) name
                depedencies: (NSArray *) dependencies
                    options: (INJProviderOptions) options
                    creator: (id (^)(NSDictionary *values)) creator;
                    
```

Providers are a bit more complex than instances. They too have names, but can also have dependencies which are just names of other
providers or instances. Every provider has a creator block whose job is to construct and return an object. 
It takes a dictionary as parameter which contains the resolved value for each dependency name. 

If you use constructor injection you can pass the corresponding objects from the values dictionary to you init method. 

For each property of the created object that is nil, has a setter and a name from the dependencies list, the framework will try to set it to the resolved value of the corresponding dependency. You can turn off this behavior by passing the INJProviderOptionManualInit option.

By default a provider's constructor block is called each time when another provider depends on the first provider's name. You can make your provider a singleton by adding the INJProviderOptionSingleton in options. In that case the provider's constructor block is called once and the returned instance is given to all other providers that depend on it.

### Checking for common errors

After you specify all your instances and providers you can call the -checkForErrors method. It makes sure you are not depending on names which are not added to the container. This can usually occur due to spelling mistakes. It also does a topological sorting of the dependency graph in order to find any circular dependencies and throws an exception listing them.

### Common use cases

#### Being able to create new objects at will

Sometimes you want to have more control when an object you depend on is created. A good example of this are view controllers. 
Say you we have the following situation:

```Objective-C

[container addInstance: [[ProductsService alloc] init] 
               forName: "productsService"];

[container addProviderForName: @"productsListViewController"
                  dependencies: @[ @"productsService", @"productDetailsViewController" ]
                      options: 0
                      creator: (id (^)(NSDictionary *values)) creator {
                          return [[ProductsListViewController alloc] init];
                      }];
                 
 [container addProviderForName: @productDetailsViewController"
                   dependencies: @[ @"productsService" ]
                       options: 0
                       creator: (id (^)(NSDictionary *values)) creator {
                           return [[ProductDetailsViewController alloc] init];
                       }];
```

Both view controllers depend on productsService and ProductsListViewController also depends on ProductDetailsViewController as the 
latter is opened whenever a product is selected from the list. The problem with this arrangement is that the details controller
is only created once. Instead what you want is to do is create a new controller each time a product is selected. To accomplish this
you need to change the name of the dependency from 'productDetailsViewController' to 'productDetailViewControllerProvider'. What this will do is instead of creating a new instance for details view controller and injecting it in the list view controller it will inject a block that returns a new ProductDetailsViewController instance. I.e.:

instead of ProductsListViewController having a property:

```Objective-C

@property (nonatomic, string) ProductDetailsViewController *productDetailsViewController

```

it will have:

```Objective-C

@property (nonatomic, string) ProductDetailsViewController *(^productDetailsViewControllerProvider)(void)

```

When you want a new details view controller instance you just use the object returned from  productDetailsViewControllerProvider(). This is the only place where the framework interferes with your code organization as you need to inject a block which returns the instance you want in this case. However, you are just adhering to a convention, not importing other code or libraries in your view controllers.

#### Circular dependencies

They are usually a code smell and Injineer does not support them out of the box but you can still have them if you want. Suppose you have the following dependencies:

```Objective-C

[container addProviderForName: @"rootViewController"
                  dependencies: @[ @"productsListViewController" ]
                      options: INJProviderOptionSingleton
                      creator: (id (^)(NSDictionary *values)) creator {
                          return [[RootViewController alloc] init];
                      }];

[container addProviderForName: @"productsListViewController"
                  dependencies: @[ @"productsService", @"productDetailsViewControllerProvider" ]
                      options: 0
                      creator: (id (^)(NSDictionary *values)) creator {
                          return [[ProductsListViewController alloc] init];
                      }];
                      
[container addProviderForName: @"productsService"
                 dependencies: @[ @"rootViewController" ]
                      options: INJProviderOptionSingleton
                      creator: (id (^)(NSDictionary *values)) creator {
                          return [[ProductsService alloc] init];
                      }];
```

This dependency graph contains a circular dependency of the form rootViewController -> productsListViewController -> productsService -> rootViewController. It order to untagle this situation you can change the productService to depend on rootViewControllerProvider thus breaking the cycle. When you need an instance of rootViewController in the service just use the one returned from rootViewControllerProvider().






