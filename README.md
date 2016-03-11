# Injineer

Injineer is simpler than other DI frameworks for Objective-C but just as powerful. 
The framework introduces no dependencies in your code, so using it is almost completely transparent (see below).

## Example application

I converted the example of another DI framework (Typhoon) to use Injineer: 

http://link.to.example.com


## How it works

The whole project consists of a single file: INJContainer. This the place where to register your objects and their dependencies.

Injineer let's you add two types of objects: instaces and providers.

### Instances

```Objective-C

- (void) addInstance: (id) instance 
             forName: (NSString *) name;
             
```

Instances are just objects which have a name. They don't have dependencies. If an object depends on a name registered to an instance, it's the value you 
set here that will be injected. They are essentially a singletons.

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

Providers are a bit more complex than instances. They too have a name, but can also have dependencies which are just names of other
providers or instances. Every provider has a creator block whose job is to construct and return a object. 
It takes a dictionary as parameter which contains the resolved value for each dependency name. 

If you use constructor injection you can pass the corredponding objects from the values dictionary to you init method. 

For property injection Injineer by default will scan your object readwrite properties and set each one that is nil and has a 
name of a dependency. You can turn off this behaviour by passing INJProviderOptionManualInit.

By default the constuctor block is called for each object which has the corresponding provider as a dependency. You can make your
provider a singleton by adding the INJProviderOptionSingleton in options.

### Common use cases

Sometimes you want to have more control when an object you depend is created. A good example of this are view controllers. 
Say you we have the following situation:

```Objective-C

[self addInstance: [[ProductsService alloc] init] 
          forName: "productsService"];

[self addProviderForName: @"productsListViewController"
             depedencies: @[ @"productsService", @"productDetailViewController" ]
                 options: 0
                 creator: (id (^)(NSDictionary *values)) creator {
                     return [[ProductsListViewController alloc] init];
                 }
                 
 [self addProviderForName: @productDetailsViewController"
             depedencies: @[ @"productsService" ]
                 options: 0
                 creator: (id (^)(NSDictionary *values)) creator {
                     return [[ProductDetailsViewController alloc] init];
                 }
```

Both view controllers depend on productsService and ProductsListViewController also depends on ProductDetailsViewController as the 
latter is opened whenever a product is selected from the list. The problem with this arrangement is that the details controller
is only created once. Instead what you wanto to do is create a new controller each time a product is selected. To accomplish this
you need to change the name of the dependency from 'productDetailViewController' to 'productDetailViewControllerProvider'.








