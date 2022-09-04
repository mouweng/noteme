# JUC下面常用工具类

- **JUC的atomic包**：运用了CAS的AtomicBoolean、AtomicInteger、AtomicReference等原子变量类

- **JUC的locks包**：
  - AbstractQueuedSynchronizer（AQS）
  - ReentantLock
  - ReentrantReadWriteLock
  - 运用了AQS的类还有：[Semaphore](https://so.csdn.net/so/search?q=Semaphore&spm=1001.2101.3001.7020)、CountDownLatch
- **JUC下的一些同步工具类**：
  - CountDownLatch（闭锁）
  - Semaphore（信号量）
  - CyclicBarrier（栅栏）
  - FutureTask
- **JUC下的一些并发容器类**：
  - ConcurrentHashMap
  - CopyOnWriteArrayList
- **JUC下的一些Executor框架的相关类**： 
  - 线程池的工厂类->Executors 
  - 线程池的实现类->ThreadPoolExecutor
- **JUC下的一些阻塞队列实现类**：
  - ArrayBlockingQueue
  - LinkedBlockingQueue
  - PriorityBlockingQueue