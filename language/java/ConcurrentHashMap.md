# ConcurrentHashMap

- [HashMap? ConcurrentHashMap? 相信看完这篇没人能难住你！](https://crossoverjie.top/2018/07/23/java-senior/ConcurrentHashMap/)

## 背景

> HashMap不是线程安全。

- 并发插入元素时，有可能出现带环链表，让下一次读操作出现死循环。
- 多线程的put可能导致元素的丢失。

- put和get并发时，可能导致get为null。

![HashTable](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204121838127.jpg)

避免HashMap的线程安全问题可以使用`Hashtable`或者`Collections.synchronizedMap`, 但是这两者有一个共同的问题是：性能。无论是读操作还是写操作都会给整个EntryTable加锁，导致同一时间的其他操作阻塞。

## ConcurrentMap1.7原理

> 1.7是一个二级哈希表，由若干个子哈希表(Segment)。 
>
> Segment 实现了 ReentrantLock，每次锁住的是一个Segment。
>
>  并发度为Segment的个数，数组扩容只在Segment内部扩容。

ConcurrentHashMap当中每个Segment各自持有一把锁。在保证线程安全的同时降低了锁的粒度，让并发操作效率更高。

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204121850655.jpg)

### Get方法

> 无需加锁，volatile保证可见性

1. 为输入的Key做Hash运算，得到hash值。
2. 通过hash值，定位到对应的Segment对象
3. 再次通过hash值，定位到Segment当中数组的具体位置。

### Put方法

1. 为输入的Key做Hash运算，得到hash值。

2. 通过hash值，定位到对应的Segment对象

3. 获取可重入锁

4. 再次通过hash值，定位到Segment当中数组的具体位置。

5. 插入或覆盖HashEntry对象。

6. 释放锁。

### size方法

把Segment的元素数量累加起来，把Segment的修改次数累加起来。判断所有Segment的总修改次数是否大于上一次的总修改次数。如果大于，说明统计过程中有修改，重新统计，尝试次数+1；如果不是。说明没有修改，统计结束。

为了尽量不锁住所有Segment，首先乐观地假设Size过程中不会有修改。当尝试一定次数，才无奈转为悲观锁，锁住所有Segment保证强一致性。（先乐观后悲观）

## ConcurrentMap1.8原理

>  1.8的版本与HashMap1.8的数据结构一致，采用数组+链表+红黑树实现，锁使用synchronized+CAS。

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204121844829.jpg)

⚠️由于在新版的 JDK 中对 synchronized 优化是很到位的。

synchronized 只锁定当前Entry节点（链表或红黑二叉树的首节点）

- put方法：采用synchronized锁住Entry，如果已经被占用，则CAS自旋（Synchronized优化）
- get方法：无锁，数据结构用volatile修饰，保证可见性

- 扩容时，阻塞所有的读写操作、并发扩容。