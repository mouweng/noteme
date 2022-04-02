# Java基础篇

##  面向对象

### 1. 封装、继承、多态

> 封装、继承、多态

- **封装**：内部细节对外部调用透明，外部调用无需关注内部细节。
- **继承**：共性的抽取到父类，重复利用。
- **多态**：外部对同一个方法的调用有不同的实现逻辑。

**多态的实现方式**

- 方法的重载：通常是指在同一个类中，相同的方法名对应着不同的方法实现，这些方法名相同的方法其区别在于他们的参数不同；
- 方法的重写：方法的重写主要用于父类和子类之间，子类重写父类的方法，只是对应的方法实现不同，方法名和方法参数都相同；
- 抽象类：在面向对象语言中，一个类中的方法只给出了标准，而没有给出具体的方法实现，这样的类就是抽象类。例如父类就可以是抽象类，抽象类是不能被实例化的类；
- 接口：在多态机制中，接口比抽象类使用起来更加方便。而抽象类组成的集合就是接口。

### 2. 接口和抽象类

> 在Java中，可以通过两种形式来体现OOP的抽象：接口和抽象类。

#### 抽象类

> 抽象类不能被实例化，只能被继承。

```java
abstract class ClassName {
    abstract void fun();
}
```

**抽象类和普通类的区别**

- 抽象方法必须为public或者protected，缺省情况下默认为public
- 抽象类不能用来创建对象；
- 子类必须实现父类的抽象方法

#### 接口

> 接口泛指供别人调用的方法或者函数，一个类继承了则必须实现接口中的所有方法。

```
[public] interface InterfaceName {
	public void fun();
}
```

#### 区别

| 抽象                                          | 接口                                    |
| --------------------------------------------- | --------------------------------------- |
| IS-A 关系，子类对象必须能够替换掉所有父类对象 | LIKE-A，只是提供一种方法实现契约        |
| 不能继承多个抽象类                            | 一个类可以实现多个接口                  |
| 抽象类的字段没有这种限制                      | 接口的字段只能是 static 和 final 类型的 |
| 抽象类的成员可以有多种访问权限                | 接口的成员只能是 public 的              |

#### 使用选择

**使用接口**

- 需要让不相关的类都实现一个方法，例如不相关的类都可以实现 Comparable 接口中的 compareTo() 方法；
- 需要使用多重继承。

**使用抽象类**

- 需要在几个相关的类中共享代码。
- 需要能控制继承来的成员的访问权限，而不是都为 public。
- 需要继承非静态和非常量字段。

#### 总结

- 抽象类是对类本质的抽象，表达的是 is a 的关系。
- 接口是对行为的抽象，表达的是 like a 的关系。

在很多情况下，接口优先于抽象类。因为接口没有抽象类严格的类层次结构要求，可以灵活地为一个类添加行为。并且从 Java 8 开始，接口也可以有默认的方法实现，使得修改接口的成本也变的很低。

### 3. 重载和重写

#### 重写（Override）

> 重写是子类对父类的允许访问的方法的实现过程进行重新编写, 返回值和形参都不能改变。即外壳不变，核心重写！

#### 重载（Overload）

> 重载是在一个类里面，方法名字相同，而参数不同。返回类型可以相同也可以不同。每个重载的方法（或者构造函数）都必须有一个独一无二的参数类型列表。

#### 区别

| 区别     | 重载     | 重写                                                         |
| -------- | -------- | ------------------------------------------------------------ |
| 参数列表 | 必须修改 | 不能修改                                                     |
| 返回类型 | 可以修改 | 不能修改                                                     |
| 异常     | 无要求   | 子类方法抛出的异常类型必须是父类抛出异常类型或为其子类型。   |
| 访问权限 | 无要求   | 不能更严格，但是可以降低限制，例如子类方法访问权限为 public，大于父类的 protected。 |

### 4. 访问控制权限

| 作用域    | 当前类 | 同一包 | 其他包子类 | 其他包的类 |
| --------- | ------ | ------ | ---------- | ---------- |
| public    | ✔️      | ✔️      | ✔️          | ✔️          |
| protected | ✔️      | ✔️      | ✔️          | ❌          |
| friendly  | ✔️      | ✔️      | ❌          | ❌          |
| private   | ✔️      | ❌      | ❌          | ❌          |

- **public**：Java 中访问限制最宽的修饰符，一般称之为“公共的”。被其修饰的类、属性以及方法不仅可以跨类访问，而且允许跨包访问。
- **protected**：介于 public 和 private 之间的一种访问修饰符，一般称之为“保护访问权限”。被其修饰的属性以及方法只能被类本身的方法及子类访问，即使子类在不同的包中也可以访问。对外包的非子类是不可以访问。
- **default**：即不加任何访问修饰符，通常称为“默认访问权限“或者“包访问权限”。该模式下，只允许在同一个包中进行访问，外包的所有类都不能访问
- private：Java中对访问权限限制的最窄的修饰符，一般称之为“私有的”。被其修饰的属性以及方法只能被该类的对象访问，其子类不能访问，更不能允许跨包访问。

## 数据类型及拆箱装箱

### Java数据类型

| 类型    | 存储需求 | 包装类    |
| ------- | -------- | --------- |
| byte    | 1字节    | Byte      |
| short   | 2字节    | Short     |
| int     | 4字节    | Integer   |
| long    | 8字节    | Long      |
| boolean | 1bit     | Boolean   |
| char    | 2字节    | Character |
| float   | 4字节    | Float     |
| double  | 8字节    | Double    |

⚠️`1.1` 字面量属于 `double` 类型，不能直接将 `1.1` 直接赋值给 `float` 变量，使用`float f = 1.1f;`

### 自动装箱拆箱

> Java中基础数据类型与它们的包装类进行运算时，编译器会自动帮我们进行转换，转换过程对程序员是透明的，这就是装箱和拆箱。

当基础类型与它们的包装类有如下几种情况时，编译器会自动帮我们进行装箱或拆箱。

- 进行 `=` 赋值操作（装箱或拆箱）
- 进行`+` , `-`， `*`，`/`混合运算 （拆箱）
- 进行`>`， `<`， `==`比较运算（拆箱）
- 调用`equals`进行比较（装箱）
- `ArrayList`， `HashMap`等集合类添加基础类型数据时（装箱）

### 缓冲池

**`new Integer(123)` 与 `Integer.valueOf(123)` 的区别**

- new Integer(123) 每次都会新建一个对象；
- Integer.valueOf(123) 会使用缓存池中的对象，多次调用会取得同一个对象的引用。

```java
Integer x1 = new Integer(123);
Integer y1 = new Integer(123);
System.out.println(x1 == y1);    // false
Integer x2 = Integer.valueOf(123);
Integer y2 = Integer.valueOf(123);
System.out.println(x2 == y2);   // true
```

编译器会在自动装箱过程调用 valueOf() 方法，在使用这些基本类型对应的包装类型时，如果该数值范围在缓冲池范围内，就可以直接使用缓冲池中的对象。

```java
Integer x1 = 123;
Integer y1 = 123;
System.out.println(x1 == y1); // true
Integer x2 = 133;
Integer y2 = 133;
System.out.println(x2 == y2); // false
```

基本类型对应的缓冲池如下：

- boolean values `true` and `false`
- all byte values
- short values between `-128` and `127`
- int values between `-128` and `127`
- char in the range `\u0000` to `\u007F`

## Java常见关键字和方法

### static和final

**final**

> 用于声明属性，方法和类，分别表示属性不可变，方法不可覆盖，类不可继承

- 最常使用final修饰的类就是工具类。

**static**

>  static用来修饰成员变量和成员方法，也可以形成静态static代码块。被static修饰的成员变量和成员方法独立于该类的任何对象。

- 在类加载的时候，就进行创建和初始化或执行代码;
- 它们对于一个类来说，都只有一份；
- 类的所有实例都可以访问到它们。

**static final**

> 可简单理解为"全局常量"。

- 对于变量，表示一旦给值就不可修改，并且通过类名可以访问，该变量被类的所有实例共享。
- 对于方法，表示不可覆盖，并且可以通过类名直接访问。

### final、finally、finalize区别

**final**

> final 表示最终的、不可改变的。用于修饰类、方法和变量。

**finally**

> finally 异常处理的一部分，它只能用在try/catch语句中，表示希望finally语句块中的代码最后一定被执行

当然并不是所有finally语句块都要执行

- 未执行到try finally块时就返回了
- 未执行到try finally块时就抛出异常了
- 在try里面System.exit(0)

finalize

> finalize()是在java.lang.Object里定义的，Object的finalize方法什么都不做，对象被回收时finalize()方法会被调用。

特殊情况下，可重写finalize()方法，当对象被回收的时候释放一些资源。但注意，要调用super.finalize()。

## Object类常用方法

### getClass

> `public final native Class<?> getClass();`

- final 方法修饰，不可重写
- 获取对象的运行时 class 对象，class 对象就是描述对象所属类的对象。
- 这个方法通常是和 Java 反射机制搭配使用的。

### equals

> `public boolean equals(Object obj);`

该方法用于比较两个对象，如果这两个对象引用指向的是同一个对象，那么返回 true，否则返回 false。

子类一般都要重写这个方法，一般 equals 和 == 是不一样的，但是在 Object 中两者是一样的。

**重写方式**

```java
public class Point {
    private int x,y;

    public Point(int x, int y) {
        this.x = x;
        this.y = y;
    }
    
    @Override
    public boolean equals(Object o) {
        if (o == this) return true;
        if (!(o instanceof Point)) return false;
        Point p = (Point) o;
        return p.x == x && p.y == y;
    }
}
```

1. 使用==检查参数是否为这个对象的引用
2. 使用instanceof检查参数是否为正确的类型
3. 强制转换参数
4. 对该类中的每个关键域，检查参数的相对应域是否与之相等

**equals和==的区别**

- ==对于基本类型（byte,short,char,int,long,float,double,boolean）：比较的就是值是否相同
- ==对于引用类型：比较的是内存中存放的地址
- 只有对象才有equals。equals 如果没有被重写，对比它们的地址是否相等；如果 equals()方法被重写，则按照重写的逻辑来进行判断。

### hashCode

> `public native int hashCode();`

该方法主要用于获取对象的散列值。Object 中该方法默认返回的是对象的堆内存地址。

**重写方式**

```java
public class Point {
    private int x,y;

    public Point(int x, int y) {
        this.x = x;
        this.y = y;
    }
    
    @Override
    public int hashCode() {
        int result = Integer.hashCode(x);
        result = 31 * result + Integer.hashCode(y);
        return result;
    }
}
```

**hashSet如何检查重复元素**

当把对象放入HashSet时，会首先计算对象的hashCode。如果没有重复的hashCode，那么则默认没有重复元素；如果有hashCode重复，则会调用equals判断HashCode相等的元素是否equals也相等，如果两者相同，HashSet 就不会让加入操作成功

设计规范

> 如果equals() 方法被覆盖过，则 hashCode() 方法也必须被覆盖

- 两个对象相等,对两个 equals() 方法返回 true
- 如果两个对象相等，则 hashcode 一定也是相同的
- 两个对象有相同的 hashcode 值，它们也不一定是相等的

重写了equals没有重写hashCode，在集合中这两个对象是不会相等的，就会出现问题。

### toString

> `public String toString();`

返回一个 String 对象，一般子类都有覆盖。

默认返回格式如下：对象的 class 名称 + @ + hashCode 的十六进制字符串。

### clone

> `protected native Object clone() throws CloneNotSupportedException;`

clone() 是 Object 的 protected 方法，只有实现了 Cloneable 接口才可以调用该方法，否则抛出 CloneNotSupportedException 异常。

**默认的 clone 方法是浅拷贝**。所谓浅拷贝，指的是对象内属性引用的对象只会拷贝引用地址，而不会将引用的对象重新分配内存。深拷贝则是会连引用的对象也重新创建。

**重写方式**（深拷贝）

```java
public class Point implements Cloneable{
    private int x,y;
    private int[] z;
    @Override
    public Point clone() {
        try {
            Point p = (Point) super.clone();
            // 这个地方实现了深拷贝，如果没有下面这行则是浅拷贝
            p.z = z.clone();
            return p;
        } catch (CloneNotSupportedException e) {
            throw new AssertionError();
        }
    }
}
```

具体细节原理参见：[java中clone方法的理解（深拷贝、浅拷贝）](https://blog.csdn.net/xinghuo0007/article/details/78896726)

### Other

- notify
- notifyAll
- wait(long timeout)
- wait(long timeout, int nanos)
- wait()
- finalize

## Java参数传递

> 归根到底java都是值传递

- 基本类型作为参数传递时，是传递值的拷贝，无论你怎么改变这个拷贝，原值是不会改变的
- 对象作为参数传递时，是把对象在内存中的地址拷贝了一份传递给参数

在方法中改变对象的字段值会改变原对象该字段值，因为引用的是同一个对象。

```java
public static void main(String[] args) {
    Dog dog = new Dog("A");
    func(dog);
    System.out.println(dog.getName()); // B
}
private static void func(Dog dog) {
    dog.setName("B");
}
```

但是在方法中将指针引用了其它对象，那么此时方法里和方法外的两个指针指向了不同的对象，在一个指针改变其所指向对象的内容对另一个指针所指向的对象没有影响。

```java
public static void main(String[] args) {
    Dog dog = new Dog("A");
    System.out.println(dog.getObjectAddress()); // Dog@4554617c
    func(dog);
    System.out.println(dog.getObjectAddress()); // Dog@4554617c
    System.out.println(dog.getName());          // A
}
private static void func(Dog dog) {
    System.out.println(dog.getObjectAddress()); // Dog@4554617c
    dog = new Dog("B");
    System.out.println(dog.getObjectAddress()); // Dog@74a14482
    System.out.println(dog.getName());          // B
}
```

## 异常

> 如果发现异常，则可以马上处理，不会影响到后续的代码执行

### Throwable

> Throwable 可以用来表示任何可以作为异常抛出的类，分为两种：Error和Exception。

- Error类对象由 Java 虚拟机生成并抛出，一般是致命性错误，JVM会选择终止线程。（StackOverFlowError、OutOfMemoryError）
    - OutOfMemoryError、StackOverFlowError
- Exception通常情况下是可以被程序处理的，并且在程序中应该尽可能去处理。
    - 又分为RuntimeException（unCheckedException）和checkedException
    - 理论上只有RuntimeException才是程序员要去处理的,checkedException一般IDE就能发现
    - RuntimeException有NullPointException、ClassNotFindException、ArrayIndexOutOfBoundsException、IllegalArgumentException、ClassCastException

### 处理异常

#### 抛出异常

- **throws**：写在方法里面，声明哪种类型的异常，方法的调用者可以捕获异常
- throw：写在方法体里面，抛出异常实例

#### 捕获异常

- try
- catch
- finally

## String、StringBuffer和StringBuilder

- String的值是不可变的，每次对String的操作都会生成新的String对象，导致效率低
- StringBuffer线程安全，效率低
- StringBuilder 线程不安全，效率高

### String为什么不可变？

- 类本身是 final 修饰的；
- 存储字符的value数组是final修饰的；
- 没有对外暴露修改value的方法。

### String不可变的好处

**（1）可以缓存 hash 值**

因为 String 的 hash 值经常被使用，例如 String 用做 HashMap 的 key。不可变的特性可以使得 hash 值也不可变，因此只需要进行一次计算。

**（2）String Pool 的需要**

如果一个 String 对象已经被创建过了，那么就会从 String Pool 中取得引用。只有 String 是不可变的，才可能使用 String Pool。

**（3）安全性**

String 经常作为参数，String 不可变性可以保证参数不可变。例如在作为网络连接参数的情况下如果 String 是可变的，那么在网络连接过程中，String 被改变，改变 String 的那一方以为现在连接的是其它主机，而实际情况却不一定是。

（4）线程安全

String 不可变性天生具备线程安全，可以在多个线程中安全地使用。

### 字符串常量池

字符串常量池（String Pool）保存着所有字符串字面量（literal strings），这些字面量在编译时期就确定。不仅如此，还可以使用 String 的 intern() 方法在运行过程将字符串添加到 String Pool 中。

> 当一个字符串调用 intern() 方法时，如果 String Pool 中已经存在一个字符串和该字符串值相等（使用 equals() 方法进行确定），那么就会返回 String Pool 中字符串的引用；否则，就会在 String Pool 中添加一个新的字符串，并返回这个新字符串的引用。

```java
String s1 = new String("aaa");
String s2 = new String("aaa");
System.out.println(s1 == s2);           // false
String s3 = s1.intern();
String s4 = s1.intern();
System.out.println(s3 == s4);           // true
```

如果是采用以下这种字面量的形式创建字符串，会自动地将字符串放入 String Pool 中。

```java
String s5 = "bbb";
String s6 = "bbb";
System.out.println(s5 == s6);  // true
```

