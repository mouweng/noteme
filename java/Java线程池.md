# Java线程池

## 定义

> 为了减少线程频繁的创建和销毁，Java提出了一种管理线程的概念，这个概念叫做线程池。

- **降低资源消耗**。通过重复利用已创建的线程降低线程创建和销毁造成的消耗。

- **提高响应速度**。当任务到达时，任务可以不需要的等到线程创建就能立即执行。

- **提高线程的可管理性**。线程是稀缺资源，如果无限制的创建，不仅会消耗系统资源，还会降低系统的稳定性，使用线程池可以进行统一的分配，调优和监控。

## ThreadPoolExecutor 

### 构造函数

> ThreadPoolExecutor 类中提供的四个构造方法。我们来看最长的那个，其余三个都是在这个构造方法的基础上产生.

```java
/**
 * 用给定的初始参数创建一个新的ThreadPoolExecutor。
 */
public ThreadPoolExecutor(
  int corePoolSize,//线程池的核心线程数量
  int maximumPoolSize,//线程池的最大线程数
  long keepAliveTime,//当线程池中的线程数大于核心线程数时，多余的空闲线程存活的最长时间
  TimeUnit unit,//时间单位
  BlockingQueue<Runnable> workQueue,//任务队列，用来储存等待执行任务的队列
  ThreadFactory threadFactory,//线程工厂，用来创建线程，一般默认即可
  RejectedExecutionHandler handler//拒绝策略，定制策略来处理任务过多的情况
) {}
```

⚠️相比于我们自定义的线程池，多了一个maximumPoolSize线程池中最大线程数的概念。线程达到corePoolSize且没有线程空闲时，再加入任务会进入workQueue，如果workQueue满了，则会创建**救急线程**。（救急线程+core线程<mximumPoolSize。）

### 策略类型

- `AbortPolicy`:抛出异常RejectedExecutionException来拒绝新任务的处理。（默认）
- `CallerRunsPolicy`：调用执行自己的线程运行任务，也就是直接在调用execute方法的线程中运行(run)被拒绝的任务。（相当于直接在main里面运行任务）
- `DiscardPolicy`：不处理新任务，直接丢弃掉。
- `DiscardOldestPolicy`：此策略将丢弃最早的未处理。

### 常用方法

#### execute() vs submit()

- `execute()`方法用于提交不需要返回值的任务，所以无法判断任务是否被线程池执行成功与否；

- `submit()`方法用于提交需要返回值的任务。线程池会返回一个 **Future** 类型的对象，通过这个 Future 对象可以判断任务是否执行成功 ，并且可以通过 Future 的 `get()`方法来获取返回值，`get()`方法会阻塞当前线程直到任务完成，而使用 `get（long timeout，TimeUnit unit）`方法则会阻塞当前线程一段时间后立即返回，这时候有可能任务没有执行完。

#### invokeAll() vs invokeAny()

- `invokeAll()` 执行队列中所有任务
- `invokeAny() `执行最先完成的任务并返回，丢弃其他任务

#### shutdown() vs shutdownNow()

- `shutdown() `线程池状态变为SHUTDOWN，不接收新任务、已提交的任务会执行完
- `shutdownNow()`线程池状态变为STOP，将队列中的任务返回、用interrupt的方式中断正在执行的任务

#### isTerminated() VS isShutdown()

- `isTerminated()` 当调用 shutdown() 方法后，并且所有提交的任务完成后返回为 true
- `isShutDown()` 当调用 shutdown() 方法后返回为 true。

### 几种常见的线程池

> 都是通过ThreadPoolExecutor来实现的，是特殊的ThreadPoolExecutor

#### FixedThreadPool

> 创建一个可重用固定数量线程的线程池。

```java
newFixedThreadPool(int nThreads, ThreadFactory threadFactory) {
    return new ThreadPoolExecutor(
      nThreads,// corePoolSize
      nThreads,// maximumPoolSize
      0L, 
      TimeUnit.MILLISECONDS,
      new LinkedBlockingQueue<Runnable>(),
      threadFactory);
}
```

- corePoolSize = maximumPoolSize 
- 使用无界队列 **LinkedBlockingQueue**（队列的容量为 Intger.MAX_VALUE），任务队列里面的任务数可以为无限大，容易导致内存溢出OOM。

#### CachedThreadPool

> 根据需要创建新线程，无corePoolSize只有maximumPoolSize

```java
newCachedThreadPool(ThreadFactory threadFactory) {
    return new ThreadPoolExecutor(
      0, // corePoolSize
      Integer.MAX_VALUE, // maximumPoolSize
      60L, 
      TimeUnit.SECONDS,
      new SynchronousQueue<Runnable>(),
      threadFactory);
}
```

- corePoolSize设置为0
- 线程销毁时间为60s
- maximumPoolSize为无限大，可能会创建大量线程，从而导致 OOM。

#### SingleThreadExecutor

> 返回只有一个线程的线程池

```java
newSingleThreadExecutor(ThreadFactory threadFactory) {
    return new FinalizableDelegatedExecutorService(new ThreadPoolExecutor(
      1, 
      1,
      0L, 
      TimeUnit.MILLISECONDS,
      new LinkedBlockingQueue<Runnable>(),
      threadFactory)
    );
}
```

- 只有一个线程的线程池，保证多个任务串行执行
- 和FixedThreadPool一样使用无界队列，容易导致内存溢出OOM
- 如果线程运行任务失败而终止，线程池还会创建一个新的线程保证正常工作

## 原理分析

![线程池原理分析](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204121512159.jpg)

## 使用示例

### Runnable创建线程池

```java
public class TestThreadPool {
    private static final int CORE_POOL_SIZE = 3;
    private static final int MAX_POOL_SIZE = 6;
    private static final int QUEUE_CAPACITY = 3;
    private static final Long KEEP_ALIVE_TIME = 1L;
    public static void main(String[] args) {
        ThreadPoolExecutor executor = new ThreadPoolExecutor(
                CORE_POOL_SIZE,
                MAX_POOL_SIZE,
                KEEP_ALIVE_TIME,
                TimeUnit.SECONDS,
                new ArrayBlockingQueue<>(QUEUE_CAPACITY),
                new ThreadPoolExecutor.CallerRunsPolicy()
        );
        for (int i = 0; i < 7; i ++) {
            Runnable r = new Runnable() {
                @Override
                public void run() {
                    System.out.println(
                            Thread.currentThread().getName() 
                            + " StartTime = " 
                            + new Date());
                    try {
                        Thread.sleep(2000);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    System.out.println(
                            Thread.currentThread().getName() 
                            + " EndTime = " 
                            + new Date());
                }
            };
            executor.execute(r);
        }
        // 终止线程
        executor.shutdown();
        while (!executor.isTerminated()) {}
        System.out.println("Finished all threads");
    }
}
```

```java
pool-1-thread-1 StartTime = Tue Apr 12 15:22:10 CST 2022
pool-1-thread-4 StartTime = Tue Apr 12 15:22:10 CST 2022
pool-1-thread-2 StartTime = Tue Apr 12 15:22:10 CST 2022
pool-1-thread-3 StartTime = Tue Apr 12 15:22:10 CST 2022
pool-1-thread-4 EndTime = Tue Apr 12 15:22:12 CST 2022
pool-1-thread-1 EndTime = Tue Apr 12 15:22:12 CST 2022
pool-1-thread-4 StartTime = Tue Apr 12 15:22:12 CST 2022
pool-1-thread-1 StartTime = Tue Apr 12 15:22:12 CST 2022
pool-1-thread-3 EndTime = Tue Apr 12 15:22:12 CST 2022
pool-1-thread-2 EndTime = Tue Apr 12 15:22:12 CST 2022
pool-1-thread-3 StartTime = Tue Apr 12 15:22:12 CST 2022
pool-1-thread-4 EndTime = Tue Apr 12 15:22:14 CST 2022
pool-1-thread-1 EndTime = Tue Apr 12 15:22:14 CST 2022
pool-1-thread-3 EndTime = Tue Apr 12 15:22:14 CST 2022
Finished all threads
```

### Callable创建线程池

```java
public class TestThreadPool2 {
    private static final int CORE_POOL_SIZE = 3;
    private static final int MAX_POOL_SIZE = 6;
    private static final int QUEUE_CAPACITY = 3;
    private static final Long KEEP_ALIVE_TIME = 1L;

    public static void main(String[] args) {
        ThreadPoolExecutor executor = new ThreadPoolExecutor(
                CORE_POOL_SIZE,
                MAX_POOL_SIZE,
                KEEP_ALIVE_TIME,
                TimeUnit.SECONDS,
                new ArrayBlockingQueue<>(QUEUE_CAPACITY),
                new ThreadPoolExecutor.CallerRunsPolicy());
        List<Future<String>> futureList = new ArrayList<>();
        Callable<String> callable = new Callable<String>() {
            @Override
            public String call() throws Exception {
                Thread.sleep(2000);
                return Thread.currentThread().getName();
            }
        };
        for (int i = 0; i < 7; i++) {
            Future<String> future = executor.submit(callable);
            futureList.add(future);
        }
        for (Future<String> fut : futureList) {
            try {
                System.out.println(fut.get());
            } catch (InterruptedException | ExecutionException e) {
                e.printStackTrace();
            }
        }
        //关闭线程池
        executor.shutdown();
    }
}
```

```java
pool-1-thread-1
pool-1-thread-2
pool-1-thread-3
// -这里停顿两秒-
pool-1-thread-2
pool-1-thread-1
pool-1-thread-4
pool-1-thread-4

// 分析：为什么会发生这种情况呢?遍历submit前六个任务，其中前三个开始获得线程执行任务后三个在任务队列里面等待。当第7个任务来的时候，这时候任务队列已经容不下了，所以会在线程池中开辟一个新线程给这个任务，但是根据add到队列里面的顺序，队列中的3个任务先执行get，所以会阻塞住当前队列，即使第7个任务已经执行完毕，但是被阻塞住不能get到值，等到后三个队列都执行完之后，才能get到值（但其实他的任务都已经执行完了）。
```

