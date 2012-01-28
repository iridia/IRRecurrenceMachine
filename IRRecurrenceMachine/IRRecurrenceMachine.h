//
//  IRRecurrenceMachine.h
//  IRRecurrenceMachine
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IRRecurrenceMachine : NSObject

- (id) initWithQueue:(NSOperationQueue *)aQueue;
@property (nonatomic, readonly, retain) NSOperationQueue *queue;

//	Designated initializer.  If a queue is not provided, or if the method was invoked
//	implicitly, the recurrence machine will create a queue on its own.
	
//	It is generally recommended to let the recurrence machine use its own queue.
//	Although the machine is conscious not to interfere with the queue, exotic queues
//	with unknown or unexpected attributes might be troublesome.


@property (nonatomic, readwrite, assign) NSTimeInterval recurrenceInterval;

//	The default interval is 30 seconds.  Changing the interval invalidates the timer.


- (void) addRecurringOperation:(NSOperation<NSCopying> *)anOperation;
@property (nonatomic, readonly, retain) NSArray *recurringOperations;

//	All the operations sent to the recurrence machine should be considered as prototypes.
//	That means whenever the recurrence machine needs to do stuff, it copies all the operations
//	and enqueues the copied instances.  This prevents stale state,
//	and avoids resetting them too.
	
//	The recurring operations array is available for KVO.  If you need to remove stuff,
//	or if you have to reorder stuff, you can invoke -mutableArrayValueForKey:
//	before a more proper API is introduced.


- (void) beginPostponingOperations;
- (void) endPostponingOperations;
- (BOOL) isPostponingOperations;
@property (nonatomic, readonly, assign) NSInteger postponingRequestCount;

//	Instead of locking and unlocking the operation queue, which might not always be an option,
//	this set of methods simply work on the internal timer held by the recurrence machine.
//	Whenever operations are postponed, the timer is invalidated and destroyed;
//	the timer is re-created whenever operations cease to be postponed.

//	That means if the recurrence machine has an interval of 30 seconds,
//	the recreated timer will not fire right after the operations are not postponed;
//	the timer will fire 30 seconds after that. 

//	If you need to immediately resume all the operations, call -scheduleOperationsNow.

//	The postponing request count is only exposed for debugging purposes;
//	do not rely on its value for anything; it is not considered to conform to KVO
//	and its accuracy is not vetted at all.


- (BOOL) scheduleOperationsNow;

//	If the operations were still running, this method returns NO; it’ll do nothing.
//	Otherwise, if the queue is empty, it starts a new interval
//	where things will happen again after `recurrenceInterval` seconds.
	
//	If operations are rescheduled properly, the internal timer will also be reset.


- (NSOperation *) newPostponingWrapperPrefix NS_RETURNS_RETAINED;
- (NSOperation *) newPostponingWrapperSuffix NS_RETURNS_RETAINED;

//	They call -beginPostponingOperations and -endPostponingOperations on self
//	and are sent to the operation queue in this order:
//	
//		{ Prefix } - { Real Operation } - { Suffix }
//	
//	where the real operation is dependent on the prefix, and
//	the suffix is dependent on the real operation.

@end
