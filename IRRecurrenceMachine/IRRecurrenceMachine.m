//
//  IRRecurrenceMachine.m
//  IRRecurrenceMachine
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "IRRecurrenceMachine.h"

@interface IRRecurrenceMachine ()

@property (nonatomic, readwrite, retain) NSOperationQueue *queue;
@property (nonatomic, readwrite, retain) NSArray *recurringOperations;
@property (nonatomic, readwrite, retain) NSTimer *timer;
@property (nonatomic, readwrite, assign) NSInteger postponingRequestCount;

@property (nonatomic, readwrite, assign) void *debugInitThreadPtr;
- (void) debugAssertThreadSafety;

@end


@implementation IRRecurrenceMachine

@synthesize queue, recurrenceInterval, recurringOperations, postponingRequestCount;
@synthesize timer;
@synthesize debugInitThreadPtr;

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
	
	queue = aQueue ? aQueue : [[NSOperationQueue alloc] init];
	recurrenceInterval = 30;
	recurringOperations = [[NSArray array] retain];
	
	debugInitThreadPtr = [NSThread currentThread];
	
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
	
	[self scheduleOperationsNow];
	
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
		dispatch_sync(dispatch_get_main_queue(), ^{
			[nrSelf beginPostponingOperations];
		});
	}] retain];
	
}

- (NSOperation *) newPostponingWrapperSuffix {
	
	__block typeof(self) nrSelf = self;
	
	return [[NSBlockOperation blockOperationWithBlock: ^ {
		dispatch_sync(dispatch_get_main_queue(), ^{
			[nrSelf endPostponingOperations];
		});
	}] retain];
	
}

- (void) beginPostponingOperations {

	[self debugAssertThreadSafety];
	
	self.postponingRequestCount += 1;
	
	if (postponingRequestCount == 1) {
		
		[self.timer invalidate];
		self.timer = nil;
		
	}
	
}

- (void) endPostponingOperations {

	[self debugAssertThreadSafety];
	
	NSParameterAssert(postponingRequestCount > 0);
	
	self.postponingRequestCount -= 1;
	
	if (!postponingRequestCount) {
		
		[self timer];
		
	}
	
}

- (BOOL) isPostponingOperations {
	
	return !!(self.postponingRequestCount);
	
}

- (void) debugAssertThreadSafety {

	NSAssert2([NSThread currentThread] == debugInitThreadPtr, @"Current Thread %@ differents from 0x%x", [NSThread currentThread], debugInitThreadPtr);

}

@end
