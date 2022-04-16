# Java内存模型

> JMM，也叫做Java Memory Model

- 原子性 - 保证指令不会受到线程上下文切换的影响
- 可见性 - 保证指令不会受到cpu缓存的影响
- 有序性 - 保证指令不会受到cpu指令并行优化的影响

## 并发问题分析

`i++`和`i--`（i是一个静态变量）不是原子操作，而是以下几个步骤：

```c++
getstatic   i // 从主存中 获取静态变量i的值 到工作内存
iconst_1      // 准备常量1
iadd || isub  // 加法 || 减法
putstatic     // 将工作内存的值 存回 主存中
```

在多线程情况下，可能会有代码的交错，最终导致结果不准确：

| 线程1          | 线程2          |
| -------------- | -------------- |
| `getstatic  i` |                |
|                | `getstatic  i` |
| `iconst_1`     |                |
| `iadd`         |                |
| `putstatic`    |                |
|                | `iconst_1`     |
|                | `isub`         |
|                | `putstatic`    |

## 原子性

> 防止指令交错。

使用synchronized可以解决原子性的问题

```java
synchronized(对象) {
  
}
```

## 可见性

> 保证指令不会受到cpu缓存的影响。

### 问题

下面代码在1s后不会立即停下来：

```java
public class TestKeJian {
    static boolean run = true;
    public static void main(String[] args) throws InterruptedException {
        Thread t = new Thread(()->{
            while (run) {
                // ...
            }
        }, "t1");
        t.start();
        Thread.sleep(1000);
        log.debug("停止t");
        run = false;
    }
}
```

### 原因分析

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204042104204.jpg)

- 初始状态， t 线程刚开始从主内存读取了 run 的值到工作内存。

- 因为 t 线程要频繁从主内存中读取 run 的值，JIT 编译器会将 run 的值缓存至自己工作内存中的高速缓存中， 减少对主存中 run 的访问，提高效率。

- 1 秒之后，main 线程修改了 run 的值，并同步至主存，而 t 是从自己工作内存中的高速缓存中读取这个变量的值，结果永远是旧值。

### 解决办法

使用`volatile`和`synchronized`都可以解决内存的可见性问题，但是`volatile`比`synchronized`更加轻量。

- 使用volitile

```java
public class TestKeJian {
    volatile static boolean run = true;
    public static void main(String[] args) throws InterruptedException {
        Thread t = new Thread(()->{
            while (run) {
                // ...
            }
        }, "t1");
        t.start();
        Thread.sleep(1000);
        log.debug("停止t");
        run = false;
    }
}
```

- 使用synchronized

```java
public class TestKeJian {
    static boolean run = true;
    // 锁对象
    final static Object lock = new Object();

    public static void main(String[] args) throws InterruptedException {
        Thread t = new Thread(()->{
            while (true) {
                // ...
                synchronized (lock) {
                    if (!run){
                        break;
                    }
                }
            }
        }, "t1");
        t.start();
        Thread.sleep(1000);
        log.debug("停止t");
        synchronized (lock) {
            run = false;
        }
    }
}
```

synchronized既可以保证代码的可见性，也可以保障代码的原子性，但是缺点是synchronized是重量级的操作，性能相对更低。

## 有序性

### 问题

```java
int num = 0;
boolean ready = false;
// 线程1 执行此方法
public void actor1(I_Result r) {
	if(ready) r.r1 = num + num;
	else r.r1 = 1;
}
// 线程2 执行此方法
public void actor2(I_Result r) {
	num = 2;
	ready = true; 
}
```

- 情况1:线程1 先执行，这时 `ready = false`，所以进入 `else` 分支结果为 `1`。

- 情况2:线程2 先执行 `num = 2`，但没来得及执行 `ready = true`，线程1 执行，还是进入 `else` 分支，结果为`1`。
- 情况3:线程2 执行到 `ready = true`，线程1 执行，这回进入 `if` 分支，结果为 `4`
- **情况4:线程2 执行 ready = true，切换到线程1，进入 if 分支，相加结果为 0。再切回线程2 执行 num = 2**

### 原因分析

出现情况4的原因是因为发生指令重排了，`ready = true`在`num=2`之前先执行。

因为JVM会在不影响（单线程）正确性的情况下，调整语句的执行顺序。

### 解决方案

- 给ready加volatile，在volatile之前的代码一定已经执行过了

```java
volatile boolean ready = false; 
```

## happens-before

> happens-before 规定了对共享变量的写操作对其它线程的读操作可见

- **synchronized锁定规则**。线程对synchronized锁住变量的写，对接下来锁住对象之后对变量的读是可见的。
- **volatile 变量规则**。线程对 volatile 描述变量的写，对接下来其它线程对该变量的读可见。
- **线程启动规则**。线程 start 前对变量的写，对该线程开始后对该变量的读可见。
- **线程终止原则**。线程结束前对变量的写，对其它线程得知它结束后的读可见。
- **线程中断规则**。线程 t1 打断 t2(interrupt)前对变量的写，对于其他线程得知 t2 被打断后对变量的读可见(通过 t2.interrupted 或 t2.isInterrupted)

- 对变量默认值(0，false，null)的写，对其它线程对该变量的读可见。
- **传递性规则** 。具有传递性，如果 `x hb-> y` 并且` y hb-> z` 那么有 `x hb-> z` ，配合 volatile 的防指令重排，有下面的例子