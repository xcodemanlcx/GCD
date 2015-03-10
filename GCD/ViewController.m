//
//  ViewController.m
//  GCD
//
//  Created by hx_leichunxiang on 14-12-9.
//  Copyright (c) 2014年 lcx. All rights reserved.
//  内容：GCD 之 dispatch_async(异步) 与 dispatch_sync（同步）

#pragma mark - 0 GCD 的定义、原理、总结、辅助博客等网址、代码层实现指导。

/*
 阅读指南：
 gcd详细说明博客：http://justsee.iteye.com/blog/1883409；
 百度搜索博客 关键词：gcd 的定义。

 学习方法思想指导：
 1､解决问题式学习：先充分理解需求，复杂问题简单化，确定思路，再写demo解决。
 
 2、学习某个大知识点：先知道这个是什么东西？有什么特点？有什么用？怎么用？
 
 
 学习目标：
 1、什么是GCD？GCD有哪些特点？由特点可知对象传统多线程（NSThread、队列）有哪些优势？
 2、GCD有什么用？在什么时候用？怎么用？（对于进行IO操作并且可能会使用大量内存的任务，我们必须仔细斟酌）
 2、GCD的优化性能的思想？
 3、GCD的最终步骤？GCD（一般为block）最终 都是提交任务 到主队列或者全局队列。
 4、什么事件源？
 5、事件源与提交队列的关系？

 
 
 一、 GCD介绍（一）: 基本概念和Dispatch Queu
 
 GCD: grand central dispatch
 定义：是一套低层API，提供了一种新的方法来进行 并发程序 编写。
 详细概括补充定义: 一套用面想对象思想、纯c语言封装的（比oc更底层）底层api，并且很大程度基于block，基于work unit。
 GCD理解深入：其实是为了优化在某些应用场景下的性能，用面向对象的思想封装了c语言的api，使多线程的使用更简单、性能更高。
 功能：有点想GCD有点像NSOperationQueue，他们都允许程序将 任务切分为多个单一任务 然后提交至工作队列来 并发地或者串行 地执行。
 终端获取文档：在Mac上敲命令“man dispatch”来获取GCD的文档。
 
 api实现原理特点：
 1、GCD的API 很大程度上 基于block，并且api是更底层纯c的api：
     *使用方式：
     1 脱离block使用：使用传统c机制提供的指针，比如函数指针和 上下文指针。
     2 配合block使用：GCD非常 简单易用 且能发挥其最大能力。
     *优势：
     1 简单易用：基于block的血统导致它能极为简单得,在不 同代码作用域 之间传递上下文。（联系block的使用时，传值的方便性理解）

 2、GCD基于work unit（工作单元），非像thread那样基于运算：
     *优势：
     1  易用：对任务执行到某种状态 进行监听，做相应处理：所以GCD可以控制诸如 等待任务结束、监视文件描述符、周期执行代码以及工作挂起等任务。（dispatch source 用户事件源）
 
 3、一套低层的API：用面向对象思想写的 c语言的封装。
     *底层封装思想机制原理：GCD自动根据系统负载来 增减线程数量，这就减少了上下文切换以及增加了计算效率。
     *优势
     1 效率性能：因为gcd 实现 更轻量（因为是更底层的api，可以在更底层去优化效率、内存，所以可以更轻量、性能更好），大多数情况，比传统新线程的创建，消耗资源更少。
 
 比较优势总结：（相对传统多线程thread、NSOperationQueue编程的优势）
 1、gcd 因为是一套多基于block、基于work unit、更底层的 api，由实现原理与特性可知其优势：很多情况，简单易用，性能更优。
 2、GCD比之NSOpertionQueue优势：更底层更高效，并且它不是Cocoa框架（oc语言）的一部分。
 3、GCD基于work unit（工作单元），非像NSThread那样基于运算。
 
 扩展：除了代码的平行执行能力，GCD还提供高度集成的事件控制系统。可以设置句柄来响应文件描述符、mach ports（Mach port 用于 OS X上的进程间通讯）、进程、计时器、信号、用户生成事件。这些句柄通过GCD来并发执行。
 
 代码实现层：
 *GCD对象：dispatch object。
    如何理解：虽然gcd是用纯c语言写的，但是用面向对象的思想封装的api。所以，GCD对象被成为dispatch object，
 *GCD内存管理：需要手动管理内存，不支持垃圾回收机制。
    如何管理：dispatch_release和dispatch_retain函数 来操作dispatch object（线程对象）的引用计数来进行内存管理。
 *GCD三种队列类型：
    1、The main queue:主队列。
           功能特点：串行队列，与主线程功能相同。
           获取： 调用dispatch_get_main_queue()来获得。
           作用：让加入主队列的任务，在主线程中执行。
           应用场景：刷新UI的操作。
    2、Global queues: 全局队列。
           功能特点：并发队列，并由整个进程共享。
           获取：调用dispatch_get_global_queue函数传入优先级来访问队列。优先级有四种。
           作用：让加入主队列的任务，在子线程中执行。
           应用场景：网络请求，跟刷新UI无关数据下载等耗时工作，避免阻塞主线程。

    3、用户队列: 用户队列 (GCD并不这样称呼这种队列, 但是没有一个特定的名字来形容这种队列，所以我们称其为用户队列)
           功能特点：串行队列，可以用同步机制来完成，有点像传统线程中的mutex。
           获取：用函数 dispatch_queue_create 创建的队列。参数说明，第一个参数：纯粹为了debug调试，命名建议用Apple建议我们使用倒置域名来命名队列，比如“com.dreamingwish.subsystem.task”。这些名字会在崩溃日志中被显示出来，也可以被调试器调用，这在调试中会很有用。
                第二个参数，目前还不支持，传入NULL就行了。
           作用：任务划分为多个单一任务后，自定义这些单一任务如何并发、串行执行的顺序信息。
 *提交job：把job提交给队列。
    1、任务提交：调用dispatch_async函数，传入一个队列和一个block。
    2、执行：队列会在轮到这个block执行时，执行这个block的代码。
 
 
 二、 GCD介绍（二）:  多核心的性能

 多核心：为了在单一进程中充分发挥多核的优势，我们有必要使用多线程技术（多进程与GCD无关）。
 工作线程池：
 1、在低层，GCD全局dispatch queue仅仅是工作线程池的抽象。
 2、用户队列的Block，最终也会进入全局队列，或主队列所在的线程池。
 
 GCD 提高 多核心系统的性能：
 
 提交队列原则，即优化两方法：1、尽量不要把队列提交的 主队列；2、任务相关-》全局队列，不相关——》用户队列。
 方法思路原则：最大化并发、最小化串行————尽量提交到并发队列，并且多个队列的尽量并发提交。即最大化并发。

 */



#import "ViewController.h"

@interface ViewController ()
{
    dispatch_queue_t _mainQueue;//主队列
    dispatch_queue_t _globalQueue;//全局队列
    dispatch_queue_t _customQueue;//用户队列
    
    NSLock *_lock;//锁：同步代码
    
    NSArray *_urls;//图片URLS
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _urls = @[@"http://img.app.d1cm.com/news/img/201312021616153719.jpg",
                      @"http://img1.xcarimg.com/b63/s2515/m_20110718163332702074.jpg",
                      @"http://img.app.d1cm.com/news/img/201312021610065708.jpg"];
    
    _mainQueue = dispatch_get_main_queue();
    _globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //异步提交队列
//    [self summitTaskToQueue];
//    [self summitTaskToQueueByGroup];
    
    
    //用户队列
//        [self methodOne];
    //全局队列
//        [self methodTwo];
    //用户队列
        [self methodThree];
//        [self methodThree2];
//        [self methodFour];
    
    //异步提交 与 同步提交 区别
//    [self methodSync];
//    [self methodAsync];
    
//    [self methodApply];

}

#pragma mark - 1 提交任务到 多个队列 ： 实现请求数据完成后，刷新UI不卡界面的方法。

#pragma mark - 1.1、方法一：单独提交。

//单独提交
- (void)summitTaskToQueue{
    for (int i = 0; i < _urls.count; i++) {
        UIImageView * imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20+100*i, 320, 100)];
        [self.view addSubview:imgView];
        
        //1 网络请求，不会阻塞主线程：提交任务（block代码）到全局队列（_globalQueue）。
        dispatch_async(_globalQueue, ^{
            NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:_urls[i]]];
            UIImage * img = [UIImage imageWithData:data];
            
            // 2 网络请求完成，刷新ui的操作的任务：1、提交给主队列，则UI界面不会卡；2、提交给全局队列，UI界面会卡。
            //  _mainQueue的位置改为_globalQueue，则会卡。
            dispatch_async(_mainQueue, ^{
                imgView.image = img;
            });
        });
    }
}

#pragma mark - 1.2、方法二：提交到group（组）。相对于单独提交，group提交可以控制所有group里队列的 执行顺序。

//提交到group（组）
- (void)summitTaskToQueueByGroup{
    dispatch_group_t group = dispatch_group_create();
    
    NSMutableArray * mutaleArr = [NSMutableArray array];
    for (int i = 0; i < _urls.count; i++) {
        dispatch_group_async(group, _globalQueue, ^{
            NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:_urls[i]]];
            UIImage * img = [UIImage imageWithData:data];
            [mutaleArr addObject:img];
        });
    }
    
     // dispatch_group_notify
    //1、执行时间：以上dispatch_group_async的队列执行完成后，才执行；
    //2、在一个group中只能使用一次。
    dispatch_group_notify(group, _mainQueue, ^{
        for (int i = 0; i < _urls.count; i++) {
            UIImageView * imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20+100*i, 320, 100)];
            [self.view addSubview:imgView];
            imgView.image = mutaleArr[i];
        }
    });
}

#pragma mark - 2 主队列（串行）、全局队列（并发）、用户队列（group）

#pragma mark - 2.1 串行队列：开辟多个线程时，执行时间长。

// 串行队列 顺序执行 总时间3秒
- (void)methodOne
{
    dispatch_async(_mainQueue, ^{
        [self doSometing:@"A"];
    });
    dispatch_async(_mainQueue, ^{
        [self doSometing:@"B"];
    });
    dispatch_async(_mainQueue, ^{
        [self doSometing:@"C"];
    });
}

#pragma mark - 2.2 并发队列：开辟多个线程时，执行时间短。

// 并行队列 无序 并发执行 总时间1秒
- (void)methodTwo
{
    dispatch_async(_globalQueue, ^{
        [self doSometing:@"A"];
        dispatch_async(_globalQueue, ^{
            [self doSometing:@"D"];
            dispatch_async(_globalQueue, ^{
                [self doSometing:@"E"];
            });
        });
    });
    dispatch_async(_globalQueue, ^{
        [self doSometing:@"B"];
    });
    dispatch_async(_globalQueue, ^{
        [self doSometing:@"C"];
    });
}

#pragma mark - 2.3 用户队列：group





// A B C E并发执行  D最后执行: dispatch_group_notify 通知
- (void)methodThree
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, _globalQueue, ^{
        [self doSometing:@"A"];
    });
    dispatch_group_async(group, _globalQueue, ^{
        [self doSometing:@"B"];
    });
    dispatch_group_async(group, _globalQueue, ^{
        [self doSometing:@"C"];
    });
    
    //1、 D必须在A B C E 都执行完毕才执行（async提交的任务执行完，才执行notify）；2、 在一个group中只能使用一次；
    dispatch_group_notify(group, _globalQueue, ^{
        [self doSometing:@"D dispatch_group_notify"];
    });
    
    dispatch_group_async(group, _globalQueue, ^{
        [self doSometing:@"E"];
    });
}

// A B C 并发执行  D最后执行: dispatch_group_wait 等待
- (void)methodThree2
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, _globalQueue, ^{
        [self doSometing:@"A"];
    });
    dispatch_group_async(group, _globalQueue, ^{
        [self doSometing:@"B"];
    });
    dispatch_group_async(group, _globalQueue, ^{
        [self doSometing:@"C"];
    });
    
    // 等待group队列的任务全部结束，才执行wait后的代码。
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    [self doSometing:@"D"];
}

// AB并发 再C  后D
- (void)methodFour
{
    /*
     DISPATCH_QUEUE_CONCURRENT 并行队列
     DISPATCH_QUEUE_SERIAL 串行队列
     */
    dispatch_queue_t myQueue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(myQueue, ^{
        [self doSometing:@"A"];
    });
    dispatch_async(myQueue, ^{
        [self doSometing:@"B"];
    });
    
    //barrier作用效果：1、AB执行完后，再执行C；C执行完后，在执行D  —— AB 并发，AB 、C、D是串行的。
    dispatch_barrier_async(myQueue, ^{
        [self doSometing:@"C"];
    });
    [self doSometing:@"C1"];

    dispatch_async(myQueue, ^{
        [self doSometing:@"D"];
    });
    
    dispatch_async(myQueue, ^{
        [self doSometing:@"E"];
    });
    
}

#pragma mark - 3 如何线程同步：dispatch_once（应用场景：单例）与 dispatch_sync（应用场景：对象初始化、登录界面）。

//防止多个线程抢同一变量：保证代码的同步，列如：单例的创建，BufferedNavigationController库中。
- (void)methodOnce
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 只会被执行一次，创建单例对象（初始化方法的创建）。
        NSLog(@"dispatch_once 只执行一次！！！！！！");
    });
}

- (void)methodForSync
{
    __block id view;//被__block修饰的、在block外的变量（对象也是变量），表示变量在block里可读可写；无__block修饰，则表示只读（在block内部，只能访问即获取变量的值）。
    dispatch_sync(_globalQueue, ^{
      view = [[UIView alloc] init];
    });
}

#pragma mark - 4 dispatch_async(异步) 与 dispatch_sync（同步）

//异步 提交队列：函数先返回，后执行block。
//dispatch_async 函数会立即返回, block会在 后台 异步执行。

- (void)methodAsync
{
    dispatch_async(_globalQueue, ^{
        [self doSometing:@"2 sync_block"];
    });
    
    NSLog(@"1 dispatch_async");
}

//同步：先执行block，函数再返回。
- (void)methodSync
{
    dispatch_sync(_globalQueue, ^{
        [self doSometing:@"2 sync_block"];
    });
    
    NSLog(@"1 dispatch_sync");
}

#pragma mark - 5 线程同步实现：NSLock（成对锁使用）、dispatch_sync（同步）、@synthesize

/*
 dispatch queue（队列）与NSLock的比较
 结果：dispatch queue 完爆 lock。
 
 安全：
    1、书写配对问题：队列形式不可能写出不成对的lock，而lock写代码容易忘记配对；
    2、内部代码返回问题：在常规Lock代码中，我们很可能在解锁之前让代码返回了。使用GCD，队列通常持续运行，你必将归还控制权。
 控制：
    1、挂起和恢复dispatch queue：队列可以，lock不可以。
    2、队列的优先级调整：队列可以，lock不可以。
        如何实现：通过将用户队列指向一个不同的全局队列，若有必要的话，这个队列甚至可以被用来在主线程上执行代码。
        实现原理：我们还可以将一个用户队列指向另一个dspatch queue，使得这个用户队列继承那个dispatch queue的属性（优先级属性），这样队列的优先级就可以被调整了。
 集成： GCD的事件系统与dispatch queue相集成。
        功能：句柄（关联事件与队列的代码） 与 队列的对象自动同步。
        实现：对象需要使用的任何事件或者计时器 都可以从该对象的队列中指向，使得这些句柄 可以自动在该队列上执行，可以使得句柄可以与队列的对象自动同步。
 平行计算：队列block内同步的代码，函数直接在c语言层面就返回了；而lock是oc的概念，内部运行没c快。
*/

- (void)methodLockAndUnlock:(UIView *)view
{
    id obj;
    
    //锁：1、锁内代码 会同步执行；2、加锁，解锁构成锁内部。
    [_lock lock];
    
    obj = @"value is locked!!!";
    NSString *str = @"hello world";
    
    [_lock unlock];
}

//methodReplaceLockBySync方法 取代 锁方法，实现block内或者锁内代码同步。要求：
//参数queue:1、要用于同步机制，queue必须是一个用户队列，而非全局队列，所以使用usingdispatch_queue_create初始化一个。2、可以用dispatch_async 或者 dispatch_sync提交队列。
- (void)methodReplaceLockBySync:(dispatch_queue_t)queue
{
    __block id obj;
    dispatch_sync(queue, ^{
        obj = @"value is protected int 多线程!!!";
        NSString *str = @"hello world";

    });
}

#pragma mark - 6 注意：dispatch queue是非常轻量级的，所以你可以大用特用，就像你以前使用lock一样。

#pragma mark - 7 dispatch_apply: 1、同步与异步的使用。2、应用场景：多个循环（相似）block并发运算。

//dispatch_apply 的同步操作.
- (void)methodApply
{
    NSArray *arr = @[@"A",@"B",@"C"];
    
    //同步提交：
    //dispatch_apply里的block：这个函数调用单一block多次，所有block并平行运算（并行运算）。
    dispatch_apply([arr count], _globalQueue, ^(size_t index) {
        [self doSometing:arr[index]];
    });
    
    [self doSometing:@"D"];
}

//dispatch_apply 的异布操作的实现。

//因为dispatch_apply没有异步的方法，所以可以用dispatch_async。
- (void)methodApplyAsync
{
    dispatch_async(_globalQueue, ^{
        [self methodApply];
    });
}

- (void)doSometing:(NSString *)str
{
    [NSThread sleepForTimeInterval:1.0];// 线程休眠 1秒: 为了让并发、串行执行顺序体现更明显。
    NSLog(@"=====%@=====",str);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
