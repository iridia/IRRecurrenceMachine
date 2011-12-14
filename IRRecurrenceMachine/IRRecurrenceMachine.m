//
//  IRRecurrenceMachine.m
//  IRRecurrenceMachine
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IRRecurrenceMachine.h"

@interface IRRecurrenceMachine ()

@property (nonatomic, readwrite, retain) NSOperationQueue *queue;
@property (nonatomic, readwrite, retain) NSArray *recurringOperations;
@property (nonatomic, readwrite, retain) NSTimer *timer;
@property (nonatomic, readwrite, assign) NSInteger postponingRequestCount;

@end


@implementation IRRecurrenceMachine

@synthesize queue, recurrenceInterval, recurringOperations, postponingRequestCount;
@synthesize timer;

- (void) dealloc {

	[queue release];
	[recurringOperations release];
	[timer invalidate];
	[timer release];
	[super dealloc];

}

- (id) init {
	
	return [self initWithQueue:nil];
	
}

- (id) initWithQueue:(NSOperationQueue *)aQueue {
	
	self = [super init];
	if (!self)
		return nil;
	
	if (!aQueue)
		aQueue = [[[NSOperationQueue alloc] init] autorelease];
	
	self.queue = aQueue;
	self.recurrenceInterval = 30;
	self.recurringOperations = [NSArray array];
	
	[self timer];
	
	return self;
	
}

- (void) addRecurringOperation:(NSOperation<NSCopying> *)anOperation {
	
	NSParameterAssert(![self.recurringOperations containsObject:anOperation]);
	
	[[self mutableArrayValueForKey:@"recurringOperations"] addObject:anOperation];
	
}

- (void) setRecurrenceInterval:(NSTimeInterval)newInterval {
	
	if (recurrenceInterval == newInterval)
		return;
	
	[self willChangeValueForKey:@"recurrenceInterval"];
	
	recurrenceInterval = newInterval;
	
	[self didChangeValueForKey:@"recurrenceInterval"];
	
	[timer invalidate];
	[timer release];
	timer = nil;
	
	if (![self isPostponingOperations])
		[self timer];
	
}

- (NSTimer *) timer {
	
	if (timer)
		return timer;
	
	timer = [[NSTimer scheduledTimerWithTimeInterval:self.recurrenceInterval target:self selector:@selector(handleTimerFire:) userInfo:nil repeats:YES] retain];
	
	return timer;
	
}

- (void) handleTimerFire:(NSTimer *)aTimer {
	
	//	BOOL didSchedule = 
	[self scheduleOperationsNow];
	
	
	//	NSParameterAssert(didSchedule);
	
}

- (BOOL) scheduleOperationsNow {
	
	if (self.queue.operationCount)
		return NO;
	
	[self beginPostponingOperations];
	
	[self.recurringOperations enumerateObjectsUsingBlock: ^ (NSOperation *operationPrototype, NSUInteger idx, BOOL *stop) {
		
		NSOperation *prefix = [[self newPostponingWrapperPrefix] autorelease];
		NSOperation *operation = [[operationPrototype copy] autorelease];
		NSOperation *suffix = [[self newPostponingWrapperSuffix] autorelease];
		
		[operation addDependency:prefix];
		[suffix addDependency:operation];
	
		[queue addOperation:prefix];
		[queue addOperation:operation];
		[queue addOperation:suffix];
	
	}];

	[self endPostponingOperations];
	
	return YES;
	
}

- (NSOperation *) newPostponingWrapperPrefix {
	
	__block typeof(self) nrSelf = self;
	
	return [[NSBlockOperation blockOperationWithBlock: ^ {
		[nrSelf beginPostponingOperations];
	}] retain];
	
}

- (NSOperation *) newPostponingWrapperSuffix {
	
	__block typeof(self) nrSelf = self;
	
	return [[NSBlockOperation blockOperationWithBlock: ^ {
		[nrSelf endPostponingOperations];
	}] retain];
	
}

- (void) beginPostponingOperations {

	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}
	
	NSParameterAssert([NSThread isMainThread]);
	
	self.postponingRequestCount += 1;
	
	if (postponingRequestCount == 1) {
		
		[self.timer invalidate];
		self.timer = nil;
		
	}
	
}

- (void) endPostponingOperations {

	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}
	
	NSParameterAssert([NSThread isMainThread]);
	
	NSParameterAssert(postponingRequestCount > 0);
	self.postponingRequestCount -= 1;
	
	if (!postponingRequestCount) {
		
		[self timer];
		
	}
	
}

- (BOOL) isPostponingOperations {
	
	return !!(self.postponingRequestCount);
	
}

@end
