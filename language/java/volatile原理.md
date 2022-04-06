# volatile原理

## 原理

> volatile 的底层实现原理是内存屏障

- 对 volatile 变量的**写指令后**会加入写屏障
- 对 volatile 变量的**读指令前**会加入读屏障

#### 写屏障

- 把（写屏障之前）对共享变量的改动同步到主存

- 写屏障之前的代码不会排在写屏障之后

#### 读屏障

- 读取到的是内存中的最新的数据
- 读屏障之后的代码不会排在读屏障之前

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204051340073.jpeg)

## 如何保证可见性

- 写屏障保证写屏障之前的代码对共享变量的改动同步到主存

```java
public void actor1(I_Result r) { 
		// 读屏障
		if(ready) {  // ready 是 volatile 读取值带读屏障 
				r.r1 = num + num; 
		} else {
				r.r1 = 1; 
		}
}
```

- 读屏障之后的代码对共享变量的读取都是主存中的最新数据

```java
public void actor1(I_Result r) { 
		// 读屏障
		if(ready) {  // ready 是 volatile 读取值带读屏障 
				r.r1 = num + num; 
		} else {
				r.r1 = 1; 
		}
}
```

## 如何保证有序性

- 写屏障会确保指令重排时，不会将写屏障之前的代码排在写屏障之后

```java
public void actor2(I_Result r) { 
		num = 2;
		ready = true; // ready 是 volatile 赋值带写屏障
		// 写屏障 
}
```

- 读屏障会确保指令重排时，不会将读屏障之后的代码排在读屏障之前

```java
public void actor1(I_Result r) { 
		// 读屏障
		if(ready) {  // ready 是 volatile 读取值带读屏障 
				r.r1 = num + num; 
		} else {
				r.r1 = 1; 
		}
}
```

## volatile和synchronized的区别

> volatile并不能保证原子性只能保证可见性和有序性
>
> synchronized能保证原子性、有序性、可见性

- 有序性只保证了本线程内相关代码不被重排序
- 可见性只保证了之后读到的代码是最新结果，但不能保证另一线程的读跑到它前面去

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204051335688.jpg)

volatile 比synchronized轻量，但是volatile 关键字只能用于变量而 synchronized 关键字可以修饰方法以及代码块。

