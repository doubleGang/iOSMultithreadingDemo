//
//  GCDController.m
//  iOSMultithreadingDemo
//
//  Created by 杨永杰 on 2019/3/25.
//  Copyright © 2019年 杨永杰. All rights reserved.
//

#import "GCDController.h"

@interface GCDController ()

@property (nonatomic, assign) int ticketSurplusCount; // 剩余票数
@end

static dispatch_semaphore_t _saleTicketLock; // 售票锁

@implementation GCDController

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"2");
    });

    // GCD 信号量：dispatch_semaphore
//    [self semaphoreSync]; // 线程同步
//    [self initTicketSystem]; // 线程安全(模拟售票)
    
    // GCD 队列组：dispatch_group
//    [self groupNotify]; // 队列组 dispatch_group_notify
//    [self groupWait]; // 队列组 dispatch_group_wait
//    [self groupEnterAndLeave]; // dispatch_group_enter、dispatch_group_leave
    
    // GCD 栅栏方法：dispatch_barrier_async
//    [self barrier];
    
    // GCD 任务和队列
//    [self syncConcurrent]; // 同步执行 + 并发队列
//    [self asyncConcurrent]; // 异步执行 + 并发队列
//    [self syncSerial]; // 同步执行 + 串行队列
//    [self asyncSerial]; // 异步执行 + 串行队列


    /**
     在主线程中调用 同步执行 + 主队列 --> 奔溃
     这是因为我们在主线程中执行syncMain方法，相当于把syncMain任务放到了主线程的队列中。而同步执行会等待当前队列中的任务执行完毕，才会接着执行。那么当我们在syncMain中把task1追加到主队列中，task1就在等待主线程处理完syncMain任务。而syncMain任务需要等待task1执行完毕，才能接着执行。
     */
//    [self syncMain];
    
    // 在其它线程中调用： 同步执行 + 主队列
//    [NSThread detachNewThreadSelector:@selector(syncMain) toTarget:self withObject:nil];
    
//    [self asyncMain]; // 异步执行 + 主队列
}


#pragma mark - 1、信号量：dispatch_semaphore
/**
 Dispatch Semaphore 提供了三个函数：
 dispatch_semaphore_create：创建一个Semaphore并给一个初始值
 dispatch_semaphore_signal：发送一个信号，让信号总量加1
 dispatch_semaphore_wait：可以使总信号量减1，当信号总量小于0时就会一直等待（阻塞所在线程），否则就可以正常执行。
 
 Dispatch Semaphore 在实际开发中主要用于：
 1、保持线程同步，将异步执行任务转换为同步执行任务
 2、保证线程安全，为线程加锁
 */
#pragma mark - 1.1 semaphore 线程同步：将异步执行任务转换为同步执行任务。
- (void)semaphoreSync
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"semaphore---begin");
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // 创建一个信号量，并给一个初始值
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block int number = 0;
    dispatch_async(queue, ^{
        
        // 追加任务1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
        
        number = 100;
        // 发送一个信号，让信号总量加1
        dispatch_semaphore_signal(semaphore);
    });
    
    // 信号量减1，当信号量小于0时就会一直等待（阻塞所在线程），否则就可以正常
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"semaphore---end,number = %d",number);
}

#pragma mark - 1.2 semaphore 线程安全：为线程加锁
// 模拟火车票售票窗口
- (void)initTicketSystem
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"semaphore---begin");
    
    // 初始化锁，实现线程安全
    _saleTicketLock = dispatch_semaphore_create(1);
    
    // 票总数
    self.ticketSurplusCount = 10;
    // 模拟两个售票窗口
    dispatch_queue_t windowOne = dispatch_queue_create("window one", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t windowTwo = dispatch_queue_create("window two", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(windowOne, ^{
//        [self saleTicketNotSafe]; // 非线程安全的
        [self saleTicketSafe]; // 线程安全的
    });
    dispatch_async(windowTwo, ^{
//        [self saleTicketNotSafe]; // 非线程安全的
        [self saleTicketSafe]; // 线程安全的
    });
}

// 非线程安全的
- (void)saleTicketNotSafe
{
    while (1) {
        if (self.ticketSurplusCount > 0) {  //如果还有票，继续售卖
            self.ticketSurplusCount--;
            NSLog(@"%@", [NSString stringWithFormat:@"剩余票数：%d 窗口：%@", self.ticketSurplusCount, [NSThread currentThread]]);
            [NSThread sleepForTimeInterval:0.2];
        } else { //如果已卖完，关闭售票窗口
            NSLog(@"所有火车票均已售完");
            break;
        }
    }
    /*
     输出：
     2019-03-25 12:17:58.867310+0800 iOSMultithreadingDemo[5001:112202] semaphore---begin
     2019-03-25 12:17:58.867525+0800 iOSMultithreadingDemo[5001:112258] 剩余票数：2 窗口：<NSThread: 0x6000028c5a80>{number = 4, name = (null)}
     2019-03-25 12:17:58.867531+0800 iOSMultithreadingDemo[5001:112257] 剩余票数：3 窗口：<NSThread: 0x6000028d1b40>{number = 3, name = (null)}
     2019-03-25 12:17:59.071133+0800 iOSMultithreadingDemo[5001:112257] 剩余票数：1 窗口：<NSThread: 0x6000028d1b40>{number = 3, name = (null)}
     2019-03-25 12:17:59.071128+0800 iOSMultithreadingDemo[5001:112258] 剩余票数：0 窗口：<NSThread: 0x6000028c5a80>{number = 4, name = (null)}
     2019-03-25 12:17:59.274680+0800 iOSMultithreadingDemo[5001:112257] 所有火车票均已售完
     2019-03-25 12:17:59.274682+0800 iOSMultithreadingDemo[5001:112258] 所有火车票均已售完
     */
}

// 线程安全的
- (void)saleTicketSafe
{
    while (1) {
        // 信号量-1（上锁）
        dispatch_semaphore_wait(_saleTicketLock, DISPATCH_TIME_FOREVER);

        if (self.ticketSurplusCount > 0) {  //如果还有票，继续售卖

            self.ticketSurplusCount--;
            NSLog(@"%@", [NSString stringWithFormat:@"剩余票数：%d 窗口：%@", self.ticketSurplusCount, [NSThread currentThread]]);
            [NSThread sleepForTimeInterval:0.2];
            
            
        } else { //如果已卖完，关闭售票窗口
            NSLog(@"所有火车票均已售完");
            // 信号量+1 (解锁)
            dispatch_semaphore_signal(_saleTicketLock);
            break;
        }
        
        // 信号量+1 (解锁)
        dispatch_semaphore_signal(_saleTicketLock);
    }
}


#pragma mark - 2、 GCD 队列组：dispatch_group
/**
 有时候我们会有这样的需求：分别异步执行多个耗时任务，然后当多个耗时任务都执行完毕后再回到主线程执行任务。这时候我们可以用到 GCD 的队列组。
 
 调用队列组的 dispatch_group_async 先把任务放到队列中，然后将队列放入队列组中。或者使用队列组的 dispatch_group_enter、dispatch_group_leave 组合来实现 dispatch_group_async。
 调用队列组的 dispatch_group_notify 回到指定线程执行任务。或者使用 dispatch_group_wait 回到当前线程继续向下执行（会阻塞当前线程）。
 */
#pragma mark - 2.1 dispatch_group_notify
- (void)groupNotify
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"group---begin");
    
    dispatch_group_t group = dispatch_group_create();
    
    // 模拟任务一
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
          NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
//        [self simulationNetworkRequest:^{
//            NSLog(@"task_1 finished ---%@",[NSThread currentThread]);      // 打印当前线程
//        }];
    });
    
    // 模拟任务二
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
        
//        [self simulationNetworkRequest:^{
//            NSLog(@"task_2 finished ---%@",[NSThread currentThread]);      // 打印当前线程
//        }];
    });
    
    // 任务一、二完成
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
       
        // 等前面的异步任务1、任务2都执行完毕后，回到主线程执行下边任务
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
}

//- (void)simulationNetworkRequest:(dispatch_block_t)callback
//{
//    dispatch_queue_t queue = dispatch_queue_create("callback", DISPATCH_QUEUE_SERIAL);
//    dispatch_async(queue, ^{
//        [NSThread sleepForTimeInterval:2];
//        callback();
//    });
//}


#pragma mark - 2.2 队列组 dispatch_group_wait
- (void)groupWait
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"group---begin");
    
    dispatch_group_t group =  dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 追加任务1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 追加任务2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    
    // dispatch_group_wait 相比 dispatch_group_notify 会阻塞当前线程，等待指定的 group 中的任务执行完成后，才会往下继续执行。
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    NSLog(@"group---end");
}

#pragma mark - 2.3 dispatch_group_enter/dispatch_group_leave
/**
 dispatch_group_enter 标志着一个任务追加到 group，执行一次，相当于 group 中未执行完毕任务数+1
 dispatch_group_leave 标志着一个任务离开了 group，执行一次，相当于 group 中未执行完毕任务数-1。
 当 group 中未执行完毕任务数为0的时候，才会使dispatch_group_wait解除阻塞，以及执行追加到dispatch_group_notify中的任务。
 */
- (void)groupEnterAndLeave
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"group---begin");
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        // 追加任务1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        // 追加任务2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 等前面的异步操作都执行完毕后，回到主线程.
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
        NSLog(@"group---end");
    });
    
    //    // 等待上面的任务全部完成后，会往下继续执行（会阻塞当前线程）
    //    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    //    NSLog(@"group---end");
}


#pragma mark - 3、GCD 栅栏方法：dispatch_barrier_async
/**
 我们有时需要异步执行两组操作，而且第一组操作执行完之后，才能开始执行第二组操作。这样我们就需要一个相当于栅栏一样的一个方法将两组异步执行的操作组给分割起来，当然这里的操作组里可以包含一个或多个任务。这就需要用到dispatch_barrier_async方法在两个操作组间形成栅栏。
 dispatch_barrier_async函数会等待前边追加到并发队列中的任务全部执行完毕之后，再将指定的任务追加到该异步队列中。然后在dispatch_barrier_async函数追加的任务执行完毕之后，异步队列才恢复为一般动作，接着追加任务到该异步队列并开
 */
//* 栅栏方法 dispatch_barrier_async
- (void)barrier
{
    dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        // 追加任务1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_barrier_async(queue, ^{
        // 追加任务 barrier
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"barrier---%@",[NSThread currentThread]);// 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务4
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"4---%@",[NSThread currentThread]);      // 打印当前线程
    });
}


#pragma mark - 4、GCD 任务和队列
/**
 任务：执行操作即执行的代码块，在GCD中就是block里面的代码；执行任务有两种方式：同步执行（sync）和异步执行（async）。两者的主要区别是：是否等待队列的任务执行结束，以及是否具备开启新线程的能力。
 
 同步执行（sync）：同步添加任务到指定队列中，在已添加的任务执行结束之前，会一直等待，直到队列里的已添加的任务执行结束，才开始添加新的执行；只在当前线程中执行任务，不具备开启新线程的能力
 异步执行（async）：异步添加任务到指定的队列中，它不会做任何等待，可以继续执行任务。 可以在新的线程中执行任务，具备开启新线程的能力。

 
 队列（Dispatch Queue）：这里的队列指执行任务的等待队列，即用来存放任务的队列。队列是一种特殊的线性表，采用 FIFO（先进先出）的原则，即新任务总是被插入到队列的末尾，而读取任务的时候总是从队列的头部开始读取。每读取一个任务，则从队列中释放一个任务。
 
 在 GCD 中有两种队列：串行队列和并发队列。两者都符合 FIFO（先进先出）的原则。两者的主要区别是：执行顺序不同，以及开启线程数不同。
 
 
 串行队列（Serial Dispatch Queue）：每次只有一个任务被执行。让任务一个接着一个地执行。（只开启一个线程，一个任务执行完毕后，再执行下一个任务）
 并发队列（Concurrent Dispatch Queue）：可以让多个任务并发（同时）执行。（可以开启多个线程，并且同时执行任务）
 
 
 */

#pragma mark - 4.1 同步执行 + 并发队列
// 特点：在当前线程中执行任务，不会开启新线程，执行完一个任务，再执行下一个任务
- (void)syncConcurrent
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"%s---begin", __func__);
    
    // 创建并发队列
    dispatch_queue_t queue = dispatch_queue_create("testQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_1---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_2---%@",[NSThread currentThread]); // 打印当前线程
    });

    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_3---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    NSLog(@"%s---end", __func__);
}

#pragma mark - 4.2 异步执行 + 并发队列
// 可以开启多个线程，任务交替（同时）执行。
- (void)asyncConcurrent
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"%s---begin", __func__);
    
    // 创建并发队列
    dispatch_queue_t queue = dispatch_queue_create("testQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_1---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_2---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_3---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    NSLog(@"%s---end", __func__);
}


#pragma mark - 4.3 同步执行 + 串行队列
// 不会开启新线程，在当前线程执行任务。任务是串行的，执行完一个任务，再执行下一个任务。
- (void)syncSerial
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"%s---begin", __func__);
    
    // 创建并发队列
    dispatch_queue_t queue = dispatch_queue_create("testQueue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_1---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_2---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_3---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    NSLog(@"%s---end", __func__);
}

#pragma mark - 4.4 异步执行 + 串行队列
// 特点：会开启新线程(只开启一个新线程)，但是因为任务是串行的，执行完一个任务，再执行下一个任务。
- (void)asyncSerial
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"%s---begin", __func__);
    
    // 创建并发队列
    dispatch_queue_t queue = dispatch_queue_create("testQueue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_1---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_2---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_3---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    NSLog(@"%s---end", __func__);
}

#pragma mark - 4.5 同步执行 + 主队列
// 特点(主线程调用)：互等卡主不执行-崩溃。
// 特点(其他线程调用)：不会开启新线程，执行完一个任务，再执行下一个任务。
- (void)syncMain
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"%s---begin", __func__);
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_1---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_2---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_3---%@",[NSThread currentThread]); // 打印当前线程
    });

    NSLog(@"%s---end", __func__);
}

#pragma mark - 4.6 异步执行 + 主队列
// 只在主线程中执行任务，执行完一个任务，再执行下一个任务。
- (void)asyncMain
{
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"%s---begin", __func__);
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_1---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_2---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"task_3---%@",[NSThread currentThread]); // 打印当前线程
    });
    
    NSLog(@"%s---end", __func__);
}

@end
