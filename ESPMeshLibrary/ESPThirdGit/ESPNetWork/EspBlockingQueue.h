//
//  EspBlockingQueue.h
//  Esp32Mesh
//
//  Created by AE on 2018/4/18.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EspBlockingQueue : NSObject

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSCondition *lock;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

/**
 * Enqueues an object to the queue.
 * @param object Object to enqueue
 */
- (void)enqueue:(id)object;

/**
 * Dequeues an object from the queue.  This method will block.
 */
- (id)dequeue;

- (NSUInteger)count;

@end
