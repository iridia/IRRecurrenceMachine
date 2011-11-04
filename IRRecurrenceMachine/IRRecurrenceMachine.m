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
@property (nonatomic, readwrite, assign) NSUInteger postponingRequestCount;

@end


@implementation IRRecurrenceMachine

@synthesize queue, recurrenceInterval, recurringOperations, postponingRequestCount;
@synthesize timer;

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
	
	[self.timer invalidate];
	
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
	
	BOOL didSchedule = [self scheduleOperationsNow];
	NSParameterAssert(didSchedule);
	
}

- (BOOL) scheduleOperationsNow {
	
	if (self.queue.operationCount)
		return NO;
	
	[self beginPostponingOperations];
	
	[recurringOperations enumerateObjectsUsingBlock: ^ (NSOperation *operationPrototype, NSUInteger idx, BOOL *stop) {
		
		NSOperation *prefix = [[self newPostponingWrapperPrefix] autorelease];
		NSOperation *operation = [[operationPrototype copy] autorelease];
		NSOperation *suffix = [[self newPostponingWrapperPrefix] autorelease];
	
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
	
	return [NSBlockOperation blockOperationWithBlock: ^ {
		[nrSelf beginPostponingOperations];
	}];
	
}

- (NSOperation *) newPostponingWrapperSuffix {
	
	__block typeof(self) nrSelf = self;
	
	return [NSBlockOperation blockOperationWithBlock: ^ {
		[nrSelf endPostponingOperations];
	}];
	
}

- (void) beginPostponingOperations {
	
	self.postponingRequestCount += 1;
	
	if (postponingRequestCount == 1) {
		
		[self.timer invalidate];
		self.timer = nil;
		
	}
	
}

- (void) endPostponingOperations {
	
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
