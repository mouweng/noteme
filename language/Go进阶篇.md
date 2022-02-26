# Go语言进阶篇

[Go语言面试宝典-进阶篇&原理篇](https://go-interview.iswbm.com/index.html)

## goroutine存在的意义

线程其实分两种：

- 一种是传统意义的操作系统线程
- 一种是编程语言实现的用户态线程，也称为协程，在 Go 中就是 goroutine

因此，goroutine 的存在必然是为了换个方式解决操作系统线程的一些弊端 – **太重** 。

### 第一：创建和切换太重

操作系统线程的创建和切换都需要进入内核，而进入内核所消耗的性能代价比较高，开销较大；

### 第二：内存使用太重

一方面，为了尽量避免极端情况下操作系统线程栈的溢出，内核在创建操作系统线程时默认会为其分配一个较大的栈内存（虚拟地址空间，内核并不会一开始就分配这么多的物理内存），然而在绝大多数情况下，系统线程远远用不了这么多内存，这导致了浪费；

另一方面，栈内存空间一旦创建和初始化完成之后其大小就不能再有变化，这决定了在某些特殊场景下系统线程栈还是有溢出的风险。

**相对的，用户态的goroutine则轻量得多**

- goroutine是用户态线程，其创建和切换都在用户代码中完成而无需进入操作系统内核，所以其开销要远远小于系统线程的创建和切换；
- goroutine启动时默认栈大小只有2k，这在多数情况下已经够用了，即使不够用，goroutine的栈也会自动扩大，同时，如果栈太大了过于浪费它还能自动收缩，这样既没有栈溢出的风险，也不会造成栈内存空间的大量浪费。

## Go闭包底层原理

```go
package main

import "fmt"

func adder() func(int) int {
    sum := 0
    return func(x int) int {
        sum += x
        return sum
    }
}

func main() {
     valueFunc:= adder()
     fmt.Println(valueFunc(2))     // output: 2
     fmt.Println(valueFunc(2))   // output: 4
}
```

1. **闭包函数里引用的外部变量，是在堆还是栈内存申请的**，取决于，你这个闭包函数在函数 Return 后是否还会在其他地方使用，若会， 就会在堆上申请，若不会，就在栈上申请。
2. 闭包函数里，引用的外部变量，存储的并不是对值的拷贝，存的是值的指针。
3. 函数的返回值里若写了变量名，则该变量是在上级的栈内存里申请的，return 的值，会直接赋值给该变量。

## defer的变量快照什么情况会失效

```go
func func1() {
    age := 0
    defer fmt.Println(age) // output: 0

    age = 18
    fmt.Println(age)      // output: 18
}


func main() {
    func1()
}
```

```go
func func1() {
    age := 0
    defer func() {
        fmt.Println(age) // output: 18
    }()
    age = 18
    return
}

func main() {
    func1()
}
```

- 若 defer 后接的是单行表达式，那defer 中的 age 只是拷贝了 `func1` 函数栈中 defer 之前的 age 的值；
- 
    若 defer 后接的是闭包函数，那defer 中的 age 只是存储的是 `func1` 函数栈中 age 的指针。

## Go抢占式调度

### v1.1 的非抢占式调用

只有当一个协程主动让出 CPU 资源（可以是运行结束，也可以是发生了系统调用或其他阻塞性操作），才能触发调度，进行下一个协程。

### v1.2 基于协作的抢占式调用

1. 如果监控线程发现有个协程 A 执行之间太长了（或者 gc 场景，或者 stw 场景），那么会友好的在这个 A 协程的某个字段设置一个抢占标记 ；
2. 协程 A 在 call 一个函数的时候，会复用到扩容栈（morestack）的部分逻辑，检查到抢占标记之后，让出 cpu，切到调度主协程里；

### v1.4 基于信号的抢占式调用

因为 v1.14 的这种抢占式调用是基于信号的，不管你的协程有没有意愿主动让出 cpu 运行权，只要你这个协程超过某个时间，就会发送信号强行夺取 cpu 运行权。

那么这个时间具体是多少呢？ 20ms

## Go 栈空间的扩容/缩容过程？

### 扩容流程

>  由于当前的 Go 的栈结构使用的是连续栈，并且初始值才 2k 比较小，因此随着函数的调用层级加深，Go 的初始栈空间就可能不够用，不够用的话，就会触发栈空间的扩容。

编译器会为函数调用插入运行时检查`runtime.morestack`，它会在几乎所有的函数调用之前检查当前`goroutine` 的栈内存是否充足，如果当前栈需要扩容，会调用`runtime.newstack` 创建新的栈。

而新的栈空间，是旧栈空间大小（通过保存在`goroutine`中的`stack`信息里记录的栈区内存边界计算出来的）的两倍，但最大栈空间大小不能超过 `maxstacksize` ，也就是 1G。

### 缩容流程

> 在函数返回后，对应的栈空间会回收，如果调用栈比较深，那么随着函数一个一个返回，回收的栈空间会越来越多。

因此在垃圾回收的时候，有必要检查一下栈空间里内存利用率，当利用率低于 25% 时，就要开始进行缩容，缩容成原来的栈空间的 50%，但同时也不能小于栈空间的原始值即最小值，2KB。

### 相同点

不管是扩容还是缩容，都是使用 `runtime.copystack` 函数来开辟新的栈空间，然后将旧栈的数据全部拷贝至新的栈空间，并调整原来指针的指向。

## Go 中哪些动作会触发 runtime 调度？

### 第一种：系统调用 SysCall

当你在 goroutine 进行一些 sleep 休眠、读取磁盘或者发送网络请求时，其实都会发生系统调用，进入操作系统内核。而一旦发生系统调用，就会直接触发 runtime 的调度，当前的 P 就会去找其他的 M 进行绑定，并取出 G 开始运行。

### 第二种：等待锁、通道

此外，在你的代码中，若因为锁或者通道导致代码阻塞了，也会触发调度。

### 第三种：人工触发

在代码中直接调用 runtime.Gosched 方法，也可以手动触发。

## Go 里是怎么比较相等与否

### 1.两个 interface 比较

#### interface 内部结构

interface 的内部实现包含了两个字段，一个是 type，一个是 data

![interface](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220226153735.png)

#### 情况1：type 和 data 都相等

- 在下面的代码中，p1 和 p2 的 type 都是 Profile，data 都是 `{"iswbm"}`，因此 p1 与 p2 相等。

- 而 p3 和 p3 虽然类型都是 `*Profile`，但由于 data 存储的是结构体的地址，而两个地址和不相同，因此 p3 与 p4 不相等。

```go
package main

import "fmt"

type Profile struct {
    Name string
}

type ProfileInt interface {}

func main()  {
    var p1, p2 ProfileInt = Profile{"iswbm"}, Profile{"iswbm"}
    var p3, p4 ProfileInt = &Profile{"iswbm"}, &Profile{"iswbm"}

    fmt.Printf("p1 --> type: %T, data: %v \n", p1, p1)
    fmt.Printf("p2 --> type: %T, data: %v \n", p2, p2)
    fmt.Println(p1 == p2)  // true

    fmt.Printf("p3 --> type: %T, data: %p \n", p3, p3)
    fmt.Printf("p4 --> type: %T, data: %p \n", p4, p4)
    fmt.Println(p3 == p4)  // false
}
```

运行后，输出如下

```shell
p1 --> type: main.Profile, data: {iswbm}
p2 --> type: main.Profile, data: {iswbm}
true
p3 --> type: *main.Profile, data: 0xc00008e200
p4 --> type: *main.Profile, data: 0xc00008e210
false
```

#### 情况2：两个 interface 都是 nil

当一个 interface 的 type 和 data 都处于 unset 状态的时候，那么该 interface 的值就为 nil。

```go
package main

import "fmt"

type ProfileInt interface {}

func main()  {
    var p1, p2 ProfileInt
    fmt.Println(p1==p2) // true
}
```

### 2. interface 与 非 interface 比较

当 interface 与非 interface 比较时，会将 非interface 转换成 interface ，然后再按照 **两个 interface 比较** 的规则进行比较。

```go
package main

import (
    "fmt"
    "reflect"
)

func main()  {
    var a string = "iswbm"
    var b interface{} = "iswbm"
    fmt.Println(a==b) // true
}
```

上面这种例子可能还好理解，那么请你看下面这个例子，为什么经过反射看到的他们不相等？

```go
package main

import (
    "fmt"
    "reflect"
)

func main()  {
    var a *string = nil
    var b interface{} = a

    fmt.Println(b==nil) // false
}
```

因此当 nil 转换为interface 后是 `(type=nil, data=nil)` ，这与 b `(type=*string, data=nil)` 虽然 data 是一样的，但 type 不相等，因此他们并不相等。

##  数组比切片的优势

###  数组可以编译检查越界

由于数组在声明后，长度就是固定的，因此在编译的时候编译器可以检查在索引取值的时候，是否有越界。而切片的长度只有运行时才能知晓，编译器无法检查。

```go
func main() {
    array := [2]int{}
    array[2] = 2  //invalid array index 2 (out of bounds for 2-element array)
}
```

### 长度是类型的一部分

在声明一个数组的类型时，需要指明两点：元素的类型和元素的个数。

```go
var array [2]int
```

因此长度是数组类型的一部分，两个元素类型相同，但可包含的元素个数不同的数组，属于两个类型。

```go
func main() {
    var array1 [2]int
    var array2 [2]int
    var array3 [3]int
    fmt.Println(reflect.TypeOf(array1) == reflect.TypeOf(array2)) // true
    fmt.Println(reflect.TypeOf(array1) == reflect.TypeOf(array3)) // false
}
```

基于这个特点，可以用它来达到一些合法性校验的目的，例如 IPv4 的地址可以声明为 [4]byte，符合该类型的数组就是合法的 ip，反之则不合法。

### 数组可以比较

类型相同的两个数组可以进行比较

```go
func main() {
    array1 := [2]int{1,2}
    array2 := [2]int{1,2}
    array3 := [2]int{2,1}
    fmt.Println(array1 == array2) // true
    fmt.Println(array1 == array3) // false
}
```

类型不同（长度不同）的数组 和 切片均不行。可比较这一特性，决定了数组也可以用来当 map 的 key 使用。

```go
func main() {
    array1 := [2]int{1,2}
    dict := make(map[[2]int]string)
    dict[array1] = "hello"
    fmt.Println(dict) // map[[1 2]:hello]
}
```
