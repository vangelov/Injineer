//
//  InjineerTests.m
//  InjineerTests
//
//  Created by Vladimir Angelov on 3/24/16.
//  Copyright © 2016 Vladimir Angelov. All rights reserved.
//


#import "INJContainer.h"

#import <Specta/Specta.h>
#import <Expecta/Expecta.h>

@interface INJTestClass : NSObject

@property (strong, nonatomic) NSString *A;
@property (strong, nonatomic) NSString *B;

@end

@implementation INJTestClass @end

SpecBegin(INJContainer)

describe(@"INJContainer", ^{
    __block INJContainer *container;
    
    beforeEach(^{
        container = [[INJContainer alloc] init];
    });
    
    describe(@"instances", ^{
        it(@"throws an exception if the same instance name is used a second time", ^{
            [container addInstance: [[NSObject alloc] init] forName: @"instance"];
            expect(^{ [container addInstance: [[NSObject alloc] init] forName: @"instance"]; }).to.raise(INJNameAlreadyUsedException);
        });
        
        it(@"always retrieves the same instance", ^{
            NSObject *instance = [[NSObject alloc] init];
            [container addInstance: instance forName: @"instance"];
            
            NSNumber *retrievedValue1 = [container valueForName: @"instance"];
            expect(retrievedValue1).to.beIdenticalTo(instance);
            
            NSNumber *retrievedValue2 = [container valueForName: @"instance"];
            expect(retrievedValue2).to.beIdenticalTo(instance);
        });
    });
    
    describe(@"providers", ^{
        it(@"throws an exception if the same provider name is used a second time", ^{
            NSLog(@"C1 %@", container);
            [container addProviderForName: @"test"
                             dependencies: @[]
                                  creator: ^id(NSDictionary *values) {
                                      return [[NSObject alloc] init];
                                  }];
            
            expect(^{
                [container addProviderForName: @"test"
                                 dependencies: @[]
                                      creator: ^id(NSDictionary *values) {
                                          return [[NSObject alloc] init];
                                      }];
            }).to.raise(INJNameAlreadyUsedException);
        });
        
        it(@"retrieves a new object for non-singleton providers", ^{
            NSLog(@"C2 %@", container);

            [container addProviderForName: @"test"
                             dependencies: @[]
                                  creator: ^id(NSDictionary *values) {
                                      return [[NSObject alloc] init];
                                  }];
            
            NSObject *value1 = [container valueForName: @"test"];
            NSObject *value2 = [container valueForName: @"test"];
            
            expect(value1).notTo.beIdenticalTo(value2);
        });
        
        it(@"retrieves the same object for singleton providers", ^{
            [container addProviderForName: @"test"
                             dependencies: @[]
                                  options: INJProviderOptionSingleton
                                  creator: ^id(NSDictionary *values) {
                                      return [[NSObject alloc] init];
                                  }];
            
            NSObject *value1 = [container valueForName: @"test"];
            NSObject *value2 = [container valueForName: @"test"];
            
            expect(value1).to.beIdenticalTo(value2);
        });
        
        it(@"returns a block for provider names ending in 'Provider'", ^{
            [container addProviderForName: @"test"
                             dependencies: @[]
                                  creator: ^id(NSDictionary *values) {
                                      INJTestClass *result = [[INJTestClass alloc] init];
                                      return result;
                                  }];
            
            INJTestClass *(^testProvider)(void) = [container valueForName: @"testProvider"];
            expect(testProvider).to.beTruthy;
            
            INJTestClass *instance1 = testProvider();
            INJTestClass *instance2 = testProvider();
            
            expect(instance1).to.beTruthy;
            expect(instance1).to.beTruthy;
            expect(instance1).toNot.beIdenticalTo(instance2);
        });
        
        describe(@"dependencies", ^{
            it(@"retrieves dependencies for providers", ^{
                [container addProviderForName: @"A"
                                 dependencies: @[]
                                      creator:^id(NSDictionary *values) {
                                          expect(values).to.beEmpty();
                                          return @"instanceA";
                                      }];
                
                [container addProviderForName: @"B"
                                 dependencies: @[ @"A" ]
                                      creator:^id(NSDictionary *values) {
                                          expect(values).to.haveCountOf(1);
                                          expect(values[@"A"]).to.equal(@"instanceA");
                                          
                                          return @"instanceB";
                                      }];
                
                [container addInstance: @"instanceC" forName: @"C"];
                
                [container addProviderForName: @"D"
                                 dependencies: @[ @"A", @"B", @"C" ]
                                      creator:^id(NSDictionary *values) {
                                          expect(values).to.haveCountOf(3);
                                          expect(values[@"A"]).to.equal(@"instanceA");
                                          expect(values[@"B"]).to.equal(@"instanceB");
                                          expect(values[@"C"]).to.equal(@"instanceC");
                                          
                                          return @"instanceC";
                                      }];
                
                [container valueForName: @"D"];
            });
            
            it(@"by default initializes nil properties with names of the dependencies", ^{
                [container addInstance: @"instanceA" forName: @"A"];
                [container addInstance: @"instanceB" forName: @"B"];
                
                [container addProviderForName: @"C"
                                 dependencies: @[ @"A", @"B" ]
                                      creator:^id(NSDictionary *values) {
                                          INJTestClass *result = [[INJTestClass alloc] init];
                                          result.B = @"otherInstance";
                                          
                                          return result;
                                      }];
                
                INJTestClass *testObject = [container valueForName: @"C"];
                
                expect(testObject.A).to.equal(@"instanceA");
                expect(testObject.B).to.beNull;
            });
            
            it(@"doesn't initializes nil properties with names of the dependencies providers marked for manual init", ^{
                [container addInstance: @"instanceA" forName: @"A"];
                [container addInstance: @"instanceB" forName: @"B"];
                
                [container addProviderForName: @"C"
                                 dependencies: @[ @"A", @"B" ]
                                      options: INJProviderOptionManualInit
                                      creator: ^id(NSDictionary *values) {
                                          INJTestClass *result = [[INJTestClass alloc] init];
                                          return result;
                                      }];
                
                INJTestClass *testObject = [container valueForName: @"C"];
                
                expect(testObject.A).to.beNull;
                expect(testObject.B).to.beNull;
            });
        });
    });
    
   
    describe(@"errors", ^{
        it(@"throws an exception if a provider depends on a missing name", ^{
            [container addProviderForName: @"A"
                             dependencies: @[ @"B" ]
                                  creator: ^id(NSDictionary *values) {
                                      return @"instanceA";
                                  }];
            
            expect(^{ [container checkForErrors]; }).to.raise(INJMissingDependencyException);
        });
        
        it(@"throws an exception containing all circular references if any", ^{
            [container addProviderForName: @"C"
                             dependencies: @[ @"A" ]
                                  creator: ^id(NSDictionary *values) {
                                      return @"instanceC";
                                  }];
            
            [container addProviderForName: @"B"
                             dependencies: @[ @"C" ]
                                  creator: ^id(NSDictionary *values) {
                                      return @"instanceB";
                                  }];
            
            [container addProviderForName: @"A"
                             dependencies: @[ @"B" ]
                                  creator: ^id(NSDictionary *values) {
                                      return @"instanceA";
                                  }];
            
            [container addProviderForName: @"D"
                             dependencies: @[ @"E" ]
                                  creator: ^id(NSDictionary *values) {
                                      return @"instanceD";
                                  }];
            
            [container addProviderForName: @"E"
                             dependencies: @[ @"D" ]
                                  creator: ^id(NSDictionary *values) {
                                      return @"instanceE";
                                  }];
            
            BOOL didThrow = NO;
            
            @try {
                [container checkForErrors];
            }
            @catch(NSException *exception) {
                NSArray *cycles = exception.userInfo[@"cycles"];

                expect(cycles).to.haveLengthOf(2);
                expect(cycles[0]).to.equal(@[ @"A", @"B", @"C", @"A" ]);
                expect(cycles[1]).to.equal(@[ @"D", @"E", @"D" ]);
            }
            @finally {
                expect(didThrow).to.beTruthy;
            }
           
        });
    });
});

SpecEnd
