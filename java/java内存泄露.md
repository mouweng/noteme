# Java内存泄露

- [java中内存泄露8种情况的总结](https://blog.csdn.net/whx_0612/article/details/109519725)

> 🔖静态集合类，如static HashMap、static LinkedList等等。

如果这类集合容器为静态的，那么它们的生命周期与程序一致。 长声明周期的对象持有短生命周期的对象的引用，尽管短生命周期的对象不再使用，但是因为长生命周期对象持有它的引用而导致不能被回收。

> 🔖各种连接，如数据库连接、网络连接和IO连接等。

只有连接被关闭后，垃圾回收器才会回收对应的对象。对各种连接不进行调用close方法的话，将会造成大量的对象无法被回收，从而引起内存泄漏。

> 🔖改变哈希值

当一个对象被存储进HashSet集合中以后，就不能修改这个对象中的那些参与计算哈希值的字段了，否则，对象修改后的哈希值与最初存储进HashSet集合中时的哈希值就不同了，在这种情况下，即使在contains方法使用该对象的当前引用作为的参数去HashSet集合中检索对象，也将返回找不到对象的结果，这也会导致无法从HashSet集合中单独删除当前对象，造成内存泄露。

> 🔖自己写的栈导致的内存泄露。

```java
import java.util.Arrays;

public class Stack {
    private Object[] elements;
    private int size = 0;
    private static final int DEFAULT_INITIAL_CAPACITY = 16;

    public Stack() {
        elements = new Object[DEFAULT_INITIAL_CAPACITY];
    }

    public void push(Object e) {
        ensureCapacity();
        elements[size++] = e;
    }

    public Object pop() {
        if (size == 0)
            throw new EmptyStackException();
        return elements[--size];
    }

    private void ensureCapacity() {
        if (elements.length == size)
            elements = Arrays.copyOf(elements, 2 * size + 1);
    }
}
```

代码的主要问题在pop函数，当进行大量的pop操作时，由于引用未进行置空，gc是不会释放的。如果栈先增长，在收缩，那么从栈中弹出的对象将不会被当作垃圾回收，即使程序不再使用栈中的这些队象，他们也不会回收，因为栈中仍然保存这对象的引用，俗称过期引用，这个内存泄露很隐蔽。

#### 解决办法

```java
public Object pop() {
    if (size == 0)
    throw new EmptyStackException();
    Object result = elements[--size];
		// 出栈的时候设置为null
    elements[size] = null;
    return result;
}
```

> 变量不合理的作用域。

一般而言，一个变量的定义的作用范围大于其使用范围，很有可能会造成内存泄漏。可以把对象设置为null，来达到回收的目的。

> 内部类持有外部类

如果一个外部类的实例对象的方法返回了一个内部类的实例对象，这个内部类对象被长期引用了，即使那个外部类实例对象不再被使用，但由于内部类持有外部类的实例对象，这个外部类对象将不会被垃圾回收，这也会造成内存泄露。

> 缓存泄漏

内存泄漏的另一个常见来源是缓存，一旦你把对象引用放入到缓存中，他就很容易遗忘，对于这个问题，可以使用WeakHashMap代表缓存，此种Map的特点是，当除了自身有对key的引用外，此key没有其他引用那么此map会自动丢弃此值。

> 监听器和回调

内存泄漏第三个常见来源是监听器和其他回调，如果客户端在你实现的API中注册回调，却没有显示的取消，那么就会积聚。需要确保回调立即被当作垃圾回收的最佳方法是只保存他的若引用，例如将他们保存成为WeakHashMap中的键。