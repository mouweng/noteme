# ReentrantLock

>  ReentrantLock是Lock接口的一个可重入互斥锁的实现类，具有**可重入、可打断、锁超时、公平锁、多个条件变量**等特性

## 对比Synchronized

- 两者都是可重入锁
- 具有synchronized不具备的特性，可打断、可以设置超时时间、支持公平锁、支持条件变量
- 从编程角度来讲，ReentrantLock一定要自己释放锁，但是synchronized的可以自动释放锁

## 特性

### 1.可重入

```java
package com.mouweng.F06;
import lombok.extern.slf4j.Slf4j;
import java.util.concurrent.locks.ReentrantLock;

@Slf4j(topic = "TestReentrantLock")
public class TestReentrantLock {
    private static ReentrantLock lock = new ReentrantLock();
    public static void main(String[] args) {
        lock.lock();
        try {
            log.debug("进入main");
            m1();
        } finally {
            lock.unlock();
        }
    }

    public static void m1() {
        lock.lock();
        try {
            log.debug("进入m1");
            m2();
        } finally {
            lock.unlock();
        }
    }

    public static void m2() {
        lock.lock();
        try {
            log.debug("进入m2");
        } finally {
            lock.unlock();
        }
    }
}
```

### 2.可打断

> 需要使用lockInterruptibly()

- 如果没有竞争，那么此方法会获取lock对象
- 如果有竞争，则进入到阻塞队列，可以被其他线程用interrupt方法打断

```java
package com.mouweng.F06;
import lombok.extern.slf4j.Slf4j;
import java.util.concurrent.locks.ReentrantLock;

@Slf4j(topic = "TestReentrantLock2")
public class TestReentrantLock2 {
    private static ReentrantLock lock = new ReentrantLock();

    public static void main(String[] args) {
        Thread t1 = new Thread(()->{
           try {
               // 如果没有竞争，那么此方法会获取lock对象
               // 如果有竞争，则进入到阻塞队列，可以被其他线程用interrupt方法打断
               log.debug("尝试获取锁");
               lock.lockInterruptibly();
           } catch (InterruptedException e) {
               e.printStackTrace();
               log.debug("没有获得锁，返回");
               return;
           }

           try {
               log.debug("获取到锁");
           } finally {
               lock.unlock();
           }
        }, "t1");

        lock.lock();
        t1.start();

        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        log.debug("打断t1线程");
        t1.interrupt();
    }
}
```

### 3.拥有锁超时机制

> 避免无限制等待

#### 方式一：tryLock()

```java
package com.mouweng.F06;
import lombok.extern.slf4j.Slf4j;
import java.util.concurrent.locks.ReentrantLock;

@Slf4j(topic = "TestReentrantLock3")
public class TestReentrantLock3 {
    public static ReentrantLock lock = new ReentrantLock();

    public static void main(String[] args) {
        Thread t1 = new Thread(()->{
            log.debug("尝试获取锁");
            if (! lock.tryLock()) {
                log.debug("获取不到锁");
                return;
            }
            try {
                log.debug("获得到了锁");
            } finally {
                lock.unlock();
            }
        },"t1");

        lock.lock();
        log.debug("获得到锁");
        t1.start();
    }
}
```

#### 方式二：tryLock(time)

```java
package com.mouweng.F06;
import lombok.extern.slf4j.Slf4j;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantLock;

@Slf4j(topic = "TestReentrantLock3")
public class TestReentrantLock3 {
    public static ReentrantLock lock = new ReentrantLock();

    public static void main(String[] args) throws InterruptedException {
        Thread t1 = new Thread(()->{
            log.debug("尝试获取锁");

            try {
                // 引入可以被打断
                if (! lock.tryLock(2, TimeUnit.SECONDS)) {
                    log.debug("获取不到锁");
                    return;
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
                log.debug("获取不到锁");
                return;
            }

            try {
                log.debug("获得到了锁");
            } finally {
                lock.unlock();
            }
        },"t1");

        lock.lock();
        log.debug("获得到锁");
        t1.start();
        Thread.sleep(1000);
        log.debug("释放了锁");
        lock.unlock();
    }
}
```

#### 使用tryLock方法解决哲学家就餐问题

```java
package com.mouweng.F06;

import com.sun.org.apache.xpath.internal.operations.Bool;
import lombok.extern.slf4j.Slf4j;

import java.util.concurrent.locks.ReentrantLock;

public class TestDeadLockZXJ {
    public static void main(String[] args) {
        Chopstick c1 = new Chopstick("1");
        Chopstick c2 = new Chopstick("2");
        Chopstick c3 = new Chopstick("3");
        Chopstick c4 = new Chopstick("4");
        Chopstick c5 = new Chopstick("5");

        new Philosopher("苏格拉底", c1, c2).start();
        new Philosopher("柏拉图", c2, c3).start();
        new Philosopher("亚里士多德", c3, c4).start();
        new Philosopher("赫拉克利特", c4, c5).start();
        new Philosopher("阿基米德", c5, c1).start();

    }
}

@Slf4j(topic = "Philosopher")
class Philosopher extends Thread {
    Chopstick left;
    Chopstick right;

    public Philosopher(String name, Chopstick left, Chopstick right) {
        super(name);
        this.left = left;
        this.right = right;
    }

    @Override
    public void run() {
        while (true) {
            // 尝试获得左手筷子
            if (left.tryLock()) {
                try {
                    // 尝试获得右手筷子
                    if (right.tryLock()) {
                        try {
                            eat();
                        } finally {
                            right.unlock(); // 释放手里的右手筷子
                        }
                    }
                } finally {
                    left.unlock(); // 释放手里的左手筷子
                }
            }
        }
    }
    private void eat() {
        log.debug("eating");
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}

class Chopstick extends ReentrantLock {
    String name;
    public Chopstick(String name) {
        this.name = name;
    }

    @Override
    public String toString() {
        return "筷子{" + name + '}';
    }
}
```

### 4.公平锁

> 默认是不公平锁

公平锁和非公平锁。这2种机制的意思从字面上也能了解个大概：即对于多线程来说，公平锁会依赖线程进来的顺序，后进来的线程后获得锁。而非公平锁的意思就是后进来的锁也可以和前边等待锁的线程同时竞争锁资源。对于效率来讲，当然是非公平锁效率更高，因为公平锁还要判断是不是线程队列的第一个才会让线程获得锁。

```java
// 使用公平锁，按先入先得的顺序
ReentrantLock lock = new ReentrantLock(true);
```

公平锁一般没有必要，会降低并发度，是为了解决饥饿问题的！

### 5.支持多条件变量

- synchronized 中的条件变量就是waitSet
- ReentrantLock支持多个条件变量的

```java
static Condition waitSet1 = lock.newCondition();
waitSet1.await();
waitSet1.signal();
```

- await执行后，会释放锁，进入对应的waitSet等待
- await的线程被唤醒（signal），重新竞争锁，从 await 后继续执行

#### 送烟送外卖案例-ReentrantLock解法

```java
package com.mouweng.F06;
import lombok.extern.slf4j.Slf4j;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

@Slf4j(topic = "TestReentrantLock4")
public class TestReentrantLock4 {
    static final Object room = new Object();

    static boolean hasCigarette = false;
    static boolean hasTakeout = false;
    static ReentrantLock ROOM = new ReentrantLock();
    // 等待烟的waitSet
    static Condition waitCigaretteSet = ROOM.newCondition();
    // 等待外卖的waitSet
    static Condition waitTakeoutSet = ROOM.newCondition();

    public static void main(String[] args) throws InterruptedException {
        new Thread(()->{
            ROOM.lock();
            try {
                log.debug("有烟没?{}",hasCigarette);
                while (!hasCigarette) {
                    log.debug("没有烟，先歇一会");
                    try {
                        waitCigaretteSet.await();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
                log.debug("可以开始干活了！");
            } finally {
                ROOM.unlock();
            }
        }, "小南").start();

        new Thread(()->{
            ROOM.lock();
            try {
                log.debug("外卖送到了没?{}",hasTakeout);
                while (!hasTakeout) {
                    log.debug("外卖没送到，先歇一会");
                    try {
                        waitTakeoutSet.await();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
                log.debug("可以开始干活了");
            } finally {
                ROOM.unlock();
            }
        },"小女").start();

        Thread.sleep(1000);
        new Thread(()->{
            ROOM.lock();
            try {
                hasTakeout = true;
                waitTakeoutSet.signal();
            } finally {
                ROOM.unlock();
            }
        },"送外卖的").start();

        Thread.sleep(1000);
        new Thread(()->{
            ROOM.lock();
            try {
                hasCigarette = true;
                waitCigaretteSet.signal();
            } finally {
                ROOM.unlock();
            }
        },"送烟的").start();
    }
}
```

