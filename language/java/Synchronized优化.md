# Synchronized优化

## Java对象头

每一个普通的对象都有一个对象头，对象头包括Klass Word（指向class类对象的指针）和Marked Word。

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041833641.jpg)

Marked Word平时存储这个对象的哈希码、分代年龄等。**当加锁时，这些信息就根据情况被替换为标记位、线程锁记录指针、重量级锁记录指针、线程id等内容。**

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041845272.jpg)

## 重量级锁Monitor

>  如果使用synchronized给对象上锁（重量级），该对象头的Mark Word中就被设置为指向Monitor对象的指针，每个java对象都可以关联一个Monitor。

```java
static final Object obj = new Object();
public static int count = 0;
public static void method() {
     synchronized( obj ) {
         count ++;
     }
}
```

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041924436.jpg)

- 新建一个Monitor，刚开始时Monitor中的Owner为null。
- 当`Thread2`执行`synchronized(obj){}`代码时就会将Monitor的所有者Owner 设置为`Thread-2`，上锁成功，Monitor中同一时刻只能有一个Owner。
- 当`Thread2` 占据锁时，如果线程`Thread3`，`Thread4`也来执行`synchronized(obj){}`代码，就会进入EntryList中变成`Blocked`阻塞状态。
- `Thread2` 执行完同步代码块的内容，然后唤醒 EntryList 中等待的线程来竞争锁，竞争时是非公平的。

- 图中 WaitSet 中的 `Thread0`，`Thread1` 是之前获得过锁，但条件不满足进入就会WAITING 状态的线程。

## 优化-轻量级锁

> 多个线程对一个对象进行加锁，但加锁的时间是错开的（竞争少），那么会使用轻量级锁进行优化。轻量级锁对使用者是透明的，即语法仍然是synchronized。

```java
// 这种情况下就没竞争
static final Object obj = new Object();
public static void method1() {
     synchronized( obj ) {
         // 同步块 A
         method2();
     }
}
public static void method2() {
     synchronized( obj ) {
         // 同步块 B
     }
}
```

每个线程都包括一个**锁记录对象**（Lock Record），锁记录储存对象的Mark Word和对象引用Object Reference。

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041959882.jpg)

### 加锁

> CAS自旋替换Mark Word，CAS失败就锁膨胀或者锁升级。

当线程锁住对象时，会让Object reference指向对象，并且尝试用CAS替换Object对象的Mark Word ，将Mark Word 的值存入锁记录中

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041947013.jpg)

- 如果cas替换成功，那么对象的对象头储存的就是锁记录的地址和状态01（被锁住）

  ![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041947033.jpg)

- 如果cas替换失败：

  1. 如果是其它线程已经持有了该Object的轻量级锁，那么表示有竞争，将进入锁膨胀阶段。

  2. 如果是自己的线程已经执行了synchronized进行加锁，那么那么再添加一条 Lock Record 作为重入的计数

     ![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204042008433.jpg)

### 解锁

> 取值为null，则解除重入锁，否则CAS自旋替换解锁，失败则进入重量级锁的解锁流程

当线程退出synchronized代码块的时候

- 当线程退出synchronized代码块的时候，如果获取的是取值为 null 的锁记录，表示有重入，这时重置锁记录，表示重入计数减一。

- 当线程退出synchronized代码块的时候，如果获取的锁记录取值不为 null，那么使用CAS将Mark Word的值恢复给对象
  - 成功则解锁成功
  - 失败（对象的Marked word为10，也就是重量级锁），则说明轻量级锁进行了锁膨胀或已经升级为重量级锁，进入重量级锁解锁流程

## 锁膨胀

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204042011609.jpg)

当 Thread-1 进行轻量级加锁时，Thread-0 已经对该对象加了轻量级锁，这时 Thread-1 加轻量级锁失败，进入锁膨胀流程。

- 对象申请Monitor锁，让Object指向重量级锁地址，Monitor的Owner指向Thread-0，然后自己进入Monitor 的EntryList 变成BLOCKED状态。

  ![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204042019650.jpg)

- 当Thread-0 退出synchronized同步块时，使用cas将Mark Word的值恢复给对象头，失败。那么会进入重量级锁的解锁过程，即按照Monitor的地址找到Monitor对象，将Owner设置为null，唤醒EntryList 中的Thread-1线程

## 自旋优化

> JDK6之后，重量级锁竞争的时候，使用自旋来进行优化。

如果当前线程自旋成功（即在自旋的时候持锁的线程释放了锁），那么当前线程就可以不用阻塞就获得了锁。

⚠️自旋会占用 CPU 时间，单核 CPU 自旋就是浪费，多核 CPU 自旋才能发挥优势。

## 偏向锁

> 解决轻量级锁在做锁重入的时候还是要执行CAS的操作的问题

只有第一次使用CAS时将对象的Mark Word头设置为入锁线程ID，之后这个**入锁线程再进行重入锁时，发现线程ID是自己的，那么就不用再进行CAS了**。

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204042028332.jpg)

-  撤销偏向锁需要将锁升级为轻量级锁。这个过程需要STW。
- 访问对象的HashCode需要撤销偏向锁
- 如果对象虽然被多个线程访问，但是没有竞争，这时偏向锁可以被重置。
- 撤销偏向锁和重偏向都是批量进行的，以类为单位。
- 如果撤销偏向达到某个阈值，整个类所有对象都会变为不可偏向

## 总结

重量级锁（Monitor）适合于线程竞争激烈的情况，但是在竞争不激烈的情况下，我们使用重量级锁性能不是很好，所以有了轻量级锁和偏向锁的优化。因此有了锁膨胀。另外由于线程的阻塞比较消耗性能，所以用锁竞争时线程采用CAS自旋优化。