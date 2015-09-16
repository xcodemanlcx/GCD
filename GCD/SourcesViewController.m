//
//  SourcesViewController.m
//  GCD
//
//  Created by hx_leichunxiang on 14-12-10.
//  Copyright (c) 2014年 lcx. All rights reserved.
//  内容：GCD 之 dispatch source 处理用户事件源。

/*
 
 dispatch source
 定义：一个 监视某些类型 事件的对象。
 
 * dispatch source 与 dispatch async 的比较：
     以更新 下载进度条UI 显示为例
     1、信号响应：dispatch source是不会响应每一个信号，而是以一个单元的工作完成（事件联结机制），才去主线程刷新UI;dispatch async会响应每一个信号。
     2、使用场景：dispatch source而不用dispatch async 唯一使用原因，就是利用事件联结机制。
     
 * 实际问题举例：列如UI界面进度条不是下载字符就去更新，下载图片而不是下载一个像素就取更新。
 
 * 代码层实现步骤：
     1、建立事件源处理机制，即把block任务提交到事件源；
        1.1 实现：调用dispatch_source_create获取用户事件源，调用dispatch_source_set_event_handler把任务提交给事件源。此时，并没有提交到队列。
     2、联结事件源，提交到队列。
        2.1 实现：调用dispatch_source_merge_data联结事件源，并提交至队列。
 
 * 执行原理：
     1、主线程有空时候，先联结事件源，获取工作单元完成的信息，再提交任务到队列。
 
 
 
 以下为扩展内容，不必太多关注：
 
 句柄：
 1、定义：对象实例的唯一标识，是整型数值。
 2、作用：应用程序 可通过 句柄 获取对象的信息。
 3、补充：
 3.1 句柄不是指针: 程序 不能利用句柄来直接阅读文件中的信息。
 3.2 句柄不在I/O文件中，则毫无用处。
 
 dispatch source
 定义：一个 监视某些类型 事件的对象。
 监听事件类型：端口发送与接收、外部进程、文件描述符、文件系统节点、POSIX信号、用户自定义的事件或定时器 的状态改变。
 下面是GCD 10.6.0版本支持的事件：
 Mach port send right state changes.
 Mach port receive right state changes.
 External process state change.
 File descriptor ready for read.
 File descriptor ready for write.
 Filesystem node event.
 POSIX signal.
 Custom timer.
 Custom event.
 用户事件：向自己发送信号。
 使用原理：把block任务提交给事件源，事件源的单元任务完成一个，如果主线程有空，在执行把block任务提交到主线程队列前，联结事件源的相关的事件，合并已完成工作单元的数据信息，则更新UI进度条；如果主线程
 */

/*
 http://img.app.d1cm.com/news/img/201312021616153719.jpg",
 http://img1.xcarimg.com/b63/s2515/m_20110718163332702074.jpg
 http://img.app.d1cm.com/news/img/201312021610065708.jpg
 
 http://dl_dir.qq.com/qqfile/qq/QQforMac/QQ_V2.4.1.dmg
 */

#import "SourcesViewController.h"

@interface SourcesViewController ()
{
    dispatch_queue_t _globalQueue;
    
    dispatch_source_t _source;
  
    uintptr_t _handlerValue;
}
@end

@implementation SourcesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //1-- 确定提交队列后，队列执行时要做的任务
    
    //获取 主线程的用户事件源
    _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
    //把block任务 提交到用户事件
    dispatch_source_set_event_handler(_source, ^{
        
        //更新UI的操作
        NSLog(@"%lu",dispatch_source_get_data(_source));
        
    });
    // 恢复用户事件（用户事件默认休眠状态），执行用户事件
    dispatch_resume(_source);
    
    
    //2-- 提交队列前，先联结事件源。
    
    //注意：以下代码，只关注dispatch_source_merge_data，不要去研究dispatch_apply。只要知道，我们把事件源提交到队列了。
    //记住：提交到队列的任务，自动执行。
    NSArray *array = @[@"A",@"B",@"C"];
     _globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply([array count], _globalQueue, ^(size_t index) {
        // do some work on data at index
        dispatch_source_merge_data(_source, 1);//merge:联结
    });

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
