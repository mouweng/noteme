# 自定义线程池

- [全面深入学习Java并发编程](https://www.bilibili.com/video/BV16J411h7Rd?p=208)
- [源码](https://github.com/mouweng/java-thread-pool)

## 线程池的组成

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204111936825.jpg)

### task

> 本质上是一个Runnable，用于定义线程执行的具体内容。

### BlockQueue

> 阻塞队列，当任务创建时，会进入阻塞队列等待被执行

#### 属性

- **queue**：双端队列存储task
- **ReentrantLock**：用于保证线程安全
- **fullWaitSet**：满队列条件变量
- **emptyWaitSet**：空队列条件变量
- **capacity**：容量

#### 方法

- `offer(task)`：添加对象方法
- `offer(task,time)`：带有效时间的添加对象方法
- `poll()`：获取对象方法
- `poll(time)`：带有效时间的获取对象方法

#### 实现

```java
class BlockingQueue<T> {
    // 任务队列
    private Deque<T> queue = new ArrayDeque<T>();
    // 锁
    private ReentrantLock lock = new ReentrantLock();
    // 生产者条件变量
    private Condition fullWaitSet = lock.newCondition();
    // 消费者条件变量
    private Condition emptyWaitSet = lock.newCondition();
    // 容量
    private int capacity;

    public BlockingQueue(int capacity) {
        this.capacity = capacity;
    }
    // 阻塞获取
    public T poll() {
        lock.lock();
        try {
            while (queue.isEmpty()) {
                try {
                    emptyWaitSet.await();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            T element = queue.removeFirst();
            fullWaitSet.signal();
            return element;
        } finally {
            lock.unlock();
        }
    }

    // 带超时的阻塞获取
    public T poll(long timeout, TimeUnit unit) {
        lock.lock();
        try {
            // 将 timeout 统一转换为 纳秒
            long nanos = unit.toNanos(timeout);
            while (queue.isEmpty()) {
                try {
                    if (nanos <= 0) {
                        return null;
                    }
                    // 返回的是剩余的时间, 无需永久的等待
                    nanos = emptyWaitSet.awaitNanos(nanos);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            T element = queue.removeFirst();
            fullWaitSet.signal();
            return element;
        } finally {
            lock.unlock();
        }
    }

    // 阻塞添加
    public void offer(T element) {
        lock.lock();
        try {
            while (queue.size() == capacity) {
                try {
                    log.debug("等待加入任务队列{}...", element);
                    fullWaitSet.await();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            log.debug("加入任务队列{}", element);
            queue.addLast(element);
            emptyWaitSet.signal();
        } finally {
            lock.unlock();
        }
    }
    // 带超时的阻塞添加
    public boolean offer(T task, long timeout, TimeUnit unit) {
        lock.lock();
        try {
            long nanos = unit.toNanos(timeout);
            while (queue.size() == capacity) {
                try {
                    log.debug("等待加入任务队列{}...", task);
                    if (nanos <= 0) {
                        return false;
                    }
                    nanos = fullWaitSet.awaitNanos(nanos);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            log.debug("加入任务队列{}", task);
            queue.addLast(task);
            emptyWaitSet.signal();
            return true;
        } finally {
            lock.unlock();
        }
    }

    // 获取大小
    public int size() {
        lock.lock();
        try {
            return queue.size();
        } finally {
            lock.unlock();
        }
    }
}
```

### workersSet

> 本质上是一个HashSet，存储worker

### worker

> 本质上是一个Thread

#### 属性

- **task**：当前worker绑定的task

#### 方法

- `run()`：重写了Thread的run方法，用于不断从BlockingQueue中获取task执行
  - 当task不为空, 执行任务。执行完毕继续接着从任务队列获取任务执行。
  - 释放worker对象

#### 实现

```java
class Worker extends Thread {
  private Runnable task;

  public Worker(Runnable task) {
    this.task = task;
  }

  public void run() {
    // 执行任务
    // 1) 当task不为空, 执行任务
    // 2) 当task执行完毕，接着从任务队列获取任务
    while (task != null || (task = taskQueue.poll(1000, TimeUnit.MILLISECONDS)) != null) {
      try {
        log.info("正在执行... {}", task);
        task.run();
      } catch (Exception e) {
        e.printStackTrace();
      } finally {
        task = null;
      }
    }
    synchronized (workers) {
      log.info("worker被移除... {}", this);
      workers.remove(this);
    }
  }
}
```

### ThreadPool

> 线程池对象，包含BlockingQueue和Workers Set。

#### 属性

- **BlockingQueue**：task阻塞队列
- **Workers Set**：线程集合
- **coreSize**：核心线程数
- **timeout**：超时时间

#### 方法

- `execute(Task)`：用于线程池层面执行task
  - 如果任务数没有超过coreSize时，创建worker，然后把task交给worker执行
  - 如果任务数超过coreSize时，加入阻塞队列

#### 实现

```java
class ThreadPool {
    // 自己定义的任务阻塞队列
    private  BlockingQueue<Runnable> taskQueue;
    // 线程集合
    private HashSet<Worker> workers = new HashSet<Worker>();
    // 核心线程数
    private int coreSize;
    // 获取任务的超时时间
    private long timeout;
    private TimeUnit timeUnit;

    public ThreadPool(int coreSize, int queueCapacity, long timeout, TimeUnit timeUnit) {
        this.taskQueue = new BlockingQueue<>(queueCapacity);
        this.coreSize = coreSize;
        this.timeout = timeout;
        this.timeUnit = timeUnit;
    }

    public void execute(Runnable task) {
        // workers线程不安全，所以用一个synchronized保证安全
        synchronized (workers) {
            // 当任务数没有超过coreSize时，直接交给Worker对象执行
            if (workers.size() < coreSize) {
                Worker worker = new Worker(task);
                log.info("新增 worder {}, 新增 task {}", worker, task);
                workers.add(worker);
                worker.start();
            } else {
                // 如果任务数超过coreSize,加入任务队列暂存
                taskQueue.offer(task);
                // log.info("加入任务队列 task {}", task);
            }
        }
    }

    class Worker extends Thread {
      ...
    }
}
```

## 拒绝策略

> 当任务队列满时，阻塞添加，主线程在添加任务的时候会阻塞住
> 可以添加拒绝策略，处理在阻塞队列满的情况

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204112049159.jpg)

### 拒绝策略类型

- 死等
- 超时等待
- 放弃任务执行
- 调用者抛出异常
- 调用者（main线程）自己执行

### 添加拒绝策略接口

```java
interface RejectPolicy<T> {
  void reject(BlockingQueue<T> queue, T task);
}
```

### 更改ThreadPool中的内容

```java
...
// RejectPolicy
private RejectPolicy<Runnable> rejectPolicy;
...

public ThreadPool(int coreSize, int queueCapacity, long timeout, TimeUnit timeUnit, RejectPolicy<Runnable> rejectPolicy) {
	...
  this.rejectPolicy = rejectPolicy;
}

public void execute(Runnable task) {
  synchronized (workers) {
    if (workers.size() < coreSize) {
      Worker worker = new Worker(task);
      log.info("新增 worder {}, 新增 task {}", worker, task);
      workers.add(worker);
      worker.start();
    } else {
      // 封装到taskQueue里面（因为里面有锁），传入拒绝策略传入
      taskQueue.tryOffer(rejectPolicy, task);
    }
  }
}
```

### BlockingQueue里面方法

```java
public void tryOffer(RejectPolicy<T> rejectPolicy, T task) {
  lock.lock();
  try {
    if (queue.size() == capacity) {// 判断队列已满
      rejectPolicy.reject(this, task);
    } else {// 队列空闲
      log.debug("加入任务队列{}", task);
      queue.addLast(task);
      emptyWaitSet.signal();
    }
  } finally {
    lock.unlock();
  }
}
```

### 定义策略-测试

```java

// 定义拒绝策略-死等
RejectPolicy<Runnable> rejectPolicy1 = new RejectPolicy<Runnable>() {
  @Override
  public void reject(BlockingQueue<Runnable> queue, Runnable task) {
    queue.offer(task);
  }
};
// 定义拒绝策略-有时间等待
RejectPolicy<Runnable> rejectPolicy2 = new RejectPolicy<Runnable>() {
  @Override
  public void reject(BlockingQueue<Runnable> queue, Runnable task) {
    queue.offer(task, 1500, TimeUnit.MILLISECONDS);
  }
};

// 定义拒绝策略-放弃等待
RejectPolicy<Runnable> rejectPolicy3 = new RejectPolicy<Runnable>() {
  @Override
  public void reject(BlockingQueue<Runnable> queue, Runnable task) {
    // 啥也不干
    log.debug("啥也不干");
  }
};

// 定义拒绝策略-抛出异常
RejectPolicy<Runnable> rejectPolicy4 = new RejectPolicy<Runnable>() {
  @Override
  public void reject(BlockingQueue<Runnable> queue, Runnable task) {
    // 可以让剩余的任务不执行
    throw new RuntimeException("任务执行失败");
  }
};

// 定义拒绝策略-让主线程自己执行
RejectPolicy<Runnable> rejectPolicy5 = new RejectPolicy<Runnable>() {
  @Override
  public void reject(BlockingQueue<Runnable> queue, Runnable task) {
    // 让主线程自己执行
    log.debug("任务自己执行");
    task.run();
  }
};


ThreadPool threadPool = new ThreadPool(1, 1, 1000, TimeUnit.MILLISECONDS, rejectPolicy5);
for (int i = 0; i < 4; i ++) {
  int j = i;
  threadPool.execute(()->{
    try {
      Thread.sleep(100000L);
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
    log.debug("{}", j);
  });
}
```

