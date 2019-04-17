//
//  EspBlockingQueue.m
//  Esp32Mesh
//
//  Created by AE on 2018/4/18.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspBlockingQueue.h"

@implementation EspBlockingQueue

- (id)init {
    self = [super init];
    if (self) {
        self.queue = [[NSMutableArray alloc] init];
        self.lock = [[NSCondition alloc] init];
        self.dispatchQueue = dispatch_queue_create("com.min.kwon.mkblockingqueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)enqueue:(id)object {
    [_lock lock];
    [_queue addObject:object];
    [_lock signal];
    [_lock unlock];
}

- (id)dequeue {
    __block id object;
    dispatch_sync(_dispatchQueue, ^{
        [self.lock lock];
        while (self.queue.count == 0) {
            [self.lock wait];
        }
        object = [self.queue objectAtIndex:0];
        [self.queue removeObjectAtIndex:0];
        [self.lock unlock];
    });
    NSLog(@"device details object %@",object);
    return object;
}

- (NSUInteger)count {
    return [_queue count];
}

- (void)dealloc {
    self.dispatchQueue = nil;
    self.queue = nil;
    self.lock = nil;
}

@end
