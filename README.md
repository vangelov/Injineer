# Injineer

Injineer is simpler than other DI frameworks for Objective-C, but just as powerful. 
The framework introduces no dependencies in your code, so using it is almost completely transparent (see below).

## Instalation

To install using [CocoaPods](https://github.com/cocoapods/cocoapods), add the following line to your Podfile:

```ruby
pod 'Injineer'
```

Alternatively, you can just drag and drop `INJContainer.h` and `INJContainer.m` into your Xcode project, agreeing to copy files if needed.

## Example application

I converted the example of another DI framework (Typhoon) to use Injineer, found in the Example folder. Just type `pod install` in the Example directory before running it. 

I didn't update the unit tests, because they rely on test utilities provided by Typhoon. You don't need such utils with Injineer. You can either create a new container for your tests, or just initialize the objects you are testing manually.

## How it works

The whole project consists of a single class: `INJContainer`, where you register your objects and their dependencies.

You can add two types of objects: an `instance` and a `provider`.

### Instances

```Objective-C

- (void) addInstance: (id) instance 
             forName: (NSString *) name;
             
```

Instances are just objects that have a name, they don't have dependencies. If an object depends on a name registered to an instance, it's the value you 
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

Providers are a bit more complex than instances. They too have names, but can also have dependencies that are just names of other
providers or instances. Every provider has a creator block whose job is to construct and return an object. 

A provider takes a dictionary as parameter that contains the resolved value for each dependency name. 

If you use constructor injection, you can pass the corresponding objects from the values dictionary to you `init` method. 

For each property of the created object that is `nil`, which has a setter and a name from the dependencies list, the framework will try to set it to the resolved value of the corresponding dependency. You can turn off this behavior by passing the `INJProviderOptionManualInit` option.

By default a provider's constructor block is called each time another provider depends on the first provider's name. You can make your provider a singleton by adding the `INJProviderOptionSingleton` in options. In that case, the provider's constructor block is called once, and the returned instance is given to all other providers that depend on it.

### Checking for common errors

After you specify all your instances and providers, you can call the `checkForErrors` method, which ensures you are not depending on names that are not added to the container. This can usually occur due to spelling mistakes. Additionally, it does a topological sort of the dependency graph in order to find any circular dependencies, and throws an exception listing them.

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
                      creator: ^id(NSDictionary *values) {
                          return [[ProductsListViewController alloc] init];
                      }];
                 
 [container addProviderForName: @"productDetailsViewController"
                  dependencies: @[ @"productsService" ]
                       options: 0
                       creator: ^id(NSDictionary *values) {
                           return [[ProductDetailsViewController alloc] init];
                       }];
```

Both view controllers depend on `productsService`, and `ProductsListViewController` also depends on `ProductDetailsViewController`, the 
latter of which is opened whenever a product is selected from the list. The problem with this arrangement is that the `ProductDetailsViewController`
is only created once. Instead what you want is to do is create a new controller each time a product is selected. To accomplish this,
you need to change the name of the dependency from `productDetailsViewController` to `productDetailViewControllerProvider`. What this will do is, instead of creating a new instance for `ProductDetailsViewController`
and injecting it in the `ProductListViewController`, will rather inject a block that returns a new `ProductDetailsViewController` instance.

For example, instead of `ProductsListViewController` having a property:

```Objective-C

@property (nonatomic, strong) ProductDetailsViewController *productDetailsViewController

```

it will have:

```Objective-C

@property (nonatomic, strong) ProductDetailsViewController *(^productDetailsViewControllerProvider)(void)

```

When you want a new `ProductDetailsViewController` instance, you just use the object returned from `productDetailsViewControllerProvider()`. This is the only place where the framework interferes with your code organization, as in this case you need to inject a block which returns the instance you want. However, you are just adhering to a convention, not importing other code or libraries in your view controllers.

#### Circular dependencies

Circular dependencies are usually a code smell and Injineer does not support them out of the box, but you can still have them if you want. Suppose you have the following dependencies:

```Objective-C

[container addProviderForName: @"rootViewController"
                 dependencies: @[ @"productsListViewController" ]
                      options: INJProviderOptionSingleton
                      creator: ^id(NSDictionary *values) creator {
                          return [[RootViewController alloc] init];
                      }];

[container addProviderForName: @"productsListViewController"
                 dependencies: @[ @"productsService", @"productDetailsViewControllerProvider" ]
                      options: 0
                      creator: ^id(NSDictionary *values) {
                          return [[ProductsListViewController alloc] init];
                      }];
                      
[container addProviderForName: @"productsService"
                 dependencies: @[ @"rootViewController" ]
                      options: INJProviderOptionSingleton
                      creator: ^id(NSDictionary *values) {
                          return [[ProductsService alloc] init];
                      }];
```

This dependency graph contains a circular dependency of the form `rootViewController` -> `productsListViewController` -> `productsService` -> `rootViewController`. In order to untagle this situation, you can change the `productService` to depend on `rootViewControllerProvider`, thus breaking the cycle. When you need an instance of `rootViewController` in the service, just use the one returned from `rootViewControllerProvider()`.
