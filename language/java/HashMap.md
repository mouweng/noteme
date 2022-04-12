# HashMap

- [HashMap夺命14问，你能坚持到第几问？](https://mp.weixin.qq.com/s/sv94zXCl7MU54VBQx8WQJw)
- [这篇文章对HashMap和ConcurrentHashMap进行了源码分析，通俗易懂！](https://crossoverjie.top/2018/07/23/java-senior/ConcurrentHashMap/)

## HashMap的特点

- HashMap的数组长度是2的幂次方
- 默认大小为16
- 碰撞因子为0.75
- 每次进行hash扩容的时候，容量都会乘2。
- HashMap允许null作为key，null键只有一个null值可以多个

## HashMap的底层数据结构是什么？

### JDK1.7

> 数组+链表，数组是HashMap的主体，链表则是主要为了解决哈希冲突而存在的。

### JDK1.8改进

> 数组+链表+红黑树，当链表过长，则会严重影响HashMap的性能，红黑树搜索时间复杂度是O(logn)，而链表是O(n)。

- **当链表长度>8 且 数组长度>64 才会转为红黑树**

在数组比较小时如果出现红黑树结构，反而会降低效率，而红黑树需要进行左旋右旋，变色，这些操作来保持平衡。

![JDK1.8](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204021434216.png)

- **首先在元素插入的时候选择尾插法。**

  避免了在扩容rehash时，因为导致的成环问题。

- **1.7采用了扰动函数来计算Hash值，1.8使用的HashCode计算更加简单。**相比于 JDK1.8 的 hash 方法 ，JDK 1.7 的 hash 方法的性能会稍差一点点，因为毕竟扰动了 4 次。

```java
// JDK1.8
static final int hash(Object key) {
    int h;
    // key.hashCode()：返回散列值也就是hashcode
    // ^ ：按位异或
    // >>>:无符号右移，忽略符号位，空位都以0补齐
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}

// JDK1.7
static int hash(int h) {
  // This function ensures that hashCodes that differ only by
  // constant multiples at each bit position have a bounded
  // number of collisions (approximately 8 at default load factor).

  h ^= (h >>> 20) ^ (h >>> 12);
  return h ^ (h >>> 7) ^ (h >>> 4);
}
```

## Hash冲突解决办法

> 解决Hash冲突方法有：开放定址法、多重散列、拉链法、公共溢出区。HashMap中采用的是拉链法。

- 开放定址法也称为再散列法，基本思想就是，如果p=H(key)出现冲突时，则以p为基础，再次hash(开放定址法只能使用同一种hash函数进行再次hash)，p1=H(p)，如果p1再次出现冲突，则以p1为基础，以此类推，直到找到一个不冲突的哈希地址pi。因此开放定址法所需要的hash表的长度要大于等于所需要存放的元素，而且因为存在再次hash，所以只能在删除的节点上做标记，而不能真正删除节点
- 再哈希法（双重散列，多重散列），提供多个不同的hash函数，R1=H1(key1)发生冲突时，再计算R2=H2（key1），直到没有冲突为止。这样做虽然不易产生堆集，但增加了计算的时间。
- 链地址法（拉链法），将哈希值相同的元素构成一个同义词的单链表，并将单链表的头指针存放在哈希表的第i个单元中，查找、插入和删除主要在同义词链表中进行，链表法适用于经常进行插入和删除的情况。
- 建立公共溢出区，将哈希表分为公共表和溢出表，当溢出发生时，将所有溢出数据统一放到溢出区

## HashMap 的长度为什么是 2 的幂次方?

虽然长度为基数能更好的让元素均匀分布，但是长度为2的幂次方的计算速度会大大提高。数组下标的计算方法是hash & (length -1) 。

## HashMap为什么线程不安全？

- 多线程下扩容死循环。JDK1.7中的HashMap使用头插法插入元素，在多线程的环境下，扩容的时候有可能导致环形链表的出现，形成死循环。因此JDK1.8使用尾插法插入元素，在扩容时会保持链表元素原本的顺序，不会出现环形链表的问题。参考[JAVA HASHMAP的死循环](https://coolshell.cn/articles/9606.html)。
- 多线程的put可能导致元素的丢失。多线程同时执行put操作，如果计算出来的索引位置是相同的，那会造成前一个key被后一个key覆盖，从而导致元素的丢失。此问题在JDK1.7和JDK1.8中都存在。
- put和get并发时，可能导致get为null。线程1执行put时，因为元素个数超出threshold而导致rehash，线程2此时执行get，有可能导致这个问题，此问题在JDK1.7和JDK1.8中都存在。

## HashMap的put方法流程

![HashMap put流程](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041240878.jpg)

1. 首先根据key的值计算hash值，找到该元素在数组中存储的下标
2. 如果没有哈希冲突直接放在对应的数组下标里
3. 如果冲突了，且key已经存在，就覆盖掉value
4. 如果冲突后是链表结构，就判断该链表是否大于8，如果大于8并且数组容量小于64，就进行扩容；如果链表节点数量大于8并且数组的容量大于64，则将这个结构转换成红黑树；否则，链表插入键值对，若key存在，就覆盖掉value
5. 如果冲突后，发现该节点是红黑树，就将这个节点挂在树上