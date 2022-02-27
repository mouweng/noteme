# Go基础篇

[Go语言面试宝典-基础篇](https://go-interview.iswbm.com/index.html)

## = 与 := 的区别

```go
// 声明
var age int
// 赋值
age = 18

// 声明并赋值
age := 18
```

- `=` 是赋值
- `:=` 是声明并赋值

一个变量只能声明一次，使用多次 `:=` 是不允许的，而当你声明一次后，却可以赋值多次，没有限制。

## 指针

### 指针和指针变量

> 普通的变量，存储的是数据；而指针变量，存储的是数据的内存地址。

- `&`：地址运算符，从变量中取得值的内存地址

```go
// 定义普通变量并打印
age := 18
fmt.Println(age) //output: 18

ptr := &age
fmt.Println(ptr) //output: 0xc000014080
```

- `*`：解引用运算符，从内存地址中取得存储的数据

```go
myage := *ptr
fmt.Println(myage) //output: 18
```

### 指针的意义

- **意义一：省内存**

当你往一个函数传递参数时，若该参数是一个值类型的变量，则在调用函数时，会将原来的变量的值拷贝一遍。

- **意义二：易编码**

写了一个函数来实现更新某对象里的一些数据，在值类型的变量中，若不使用指针，则函数需要重新返回一个更新过的全新对象。而有了指针，则可以不用返回。

## 多值返回的作用

- Go 中实现变量的交换，就不需要再使用中间变量

```go
func swap(a int, b int) (int, int) {
    return b, a
}
```

- 若返回的值，有的不需要，可以直接使用 占位符 `_` 接收，表示丢弃这个值。

```go
a, _ = swap(a, b)
```

- 在 Go 中没有异常机制，当一个函数运行出错的时候，除了返回该功能函数的结果外，还应该返回一个 error 类型的值。这是 Golang 这门语言的设计哲学。

```go
if err != nil {
  // handle error
}
```

## rune 和 byte的区别

在 Go 中字符类型有两种，分别是：

- byte 类型：字节，是 uint8 的别名类型，1字节
- rune 类型：字符，是 int32 的别名类型，4字节

byte 和 rune ，虽然都能表示一个字符，但 byte 只能表示 ASCII 码表中的一个字符（ASCII 码表总共有 256 个字符），数量远远不如 rune 多，rune 表示的是 Unicode字符中的任一字符。

```go
var a byte = 'A'
var b rune = 'B'
fmt.Printf("a 占用 %d 个字节数\n", unsafe.Sizeof(a))
fmt.Printf("b 占用 %d 个字节数\n",unsafe.Sizeof(b))

// output
a 占用 1 个字节数
b 占用 4 个字节数
```

更多区别可以阅读：[go 的 [] rune 和 [] byte 区别](https://learnku.com/articles/23411/the-difference-between-rune-and-byte-of-go)

## 深拷贝与浅拷贝

### 拷贝

当你把 a 变量赋值给 b 变量时，其实就是把 a 变量拷贝给 b 变量。

```go
a := "hello"
b := a
```

- 你往一个函数中传参
- 你向通道中传入对象

这些其实在 Go编译器中都会进行拷贝的动作。

### 深浅拷贝

go语言中的数据结构分为如下两种类型：

- **值类型** ：String，Array，Int，Struct，Float，Bool
- **引用类型**：Slice，Map

对于值类型来说，你的每一次拷贝，Go 都会新申请一块内存空间，来存储它的值，改变其中一个变量，并不会影响另一个变量。

```go
func main() {
    aArr := [3]int{0,1,2}
    fmt.Printf("打印 aArr: %v \n", aArr)
    bArr := aArr
    aArr[0] = 88
    fmt.Printf("打印 aArr: %v \n", aArr)
    fmt.Printf("打印 bArr: %v \n", bArr)
}
```

对于引用类型来说，你的每一次拷贝，Go 不会申请新的内存空间，而是使用它的指针，两个变量名其实都指向同一块内存空间，改变其中一个变量，会直接影响另一个变量。

```go

func main() {
    aslice := []int{0,1,2}
    fmt.Printf("打印 aslice: %v \n", aslice)
    bslice := aslice
    aslice[0] = 88
    fmt.Printf("打印 aslice: %v \n", aslice)
    fmt.Printf("打印 bslice: %v \n", bslice)
}

```

## 字面量的定义与寻址问题

### 什么是字面量

在 Go 中内置的基本类型有：

- 布尔类型：`bool`
- 11个内置的整数数字类型：`int8`, `uint8`, `int16`, `uint16`, `int32`, `uint32`, `int64`, `uint64`, `int`, `uint`和`uintptr`
- 浮点数类型：`float32`和`float64`
- 复数类型：`complex64`和`complex128`
- 字符串类型：`string`

而这些基本类型值的文本，就是基本类型字面量。

比如下面这两个字符串，都是字符串字面量，没有用变量名或者常量名来指向这两个字面量，因此也称之为 **未命名常量**。

```
"hello, iswbm"

`hello,
iswbm`
```

### 字面量的寻址问题

字面量，说白了就是未命名的常量，跟常量一样，他是不可寻址的，必须要有变量接受才行。

 ```go
 func foo() [3]int {
     return [3]int{1, 2, 3}
 }
 
 func main() {
     fmt.Println(&foo())
     // cannot take the address of foo()
     
     bar := foo()
     fmt.Println(&bar)
 }
 ```

## 对象选择器自动解引用

当你对象是结构体对象的指针时，你想要获取字段属性时，按照常规理解应该这么做

 ```go
 type Person struct {
     name string
 }
 
 func (p *Person) Say() {
     fmt.Println((*p).name)
 }
 ```

但还有一个更简洁的做法，可以直接省去 `*` 取值的操作，选择器 `.` 会直接解引用，示例如下

```go
type Person struct {
    name string
}

func (p *Person) Say() {
    fmt.Println(p.name)
}
```

## Map值不可寻址的解决方案

要回答本题，需要你知道什么是不可寻址。

```go
package main

type Person struct {
    Age int
}

func (p *Person) GrowUp() {
    p.Age++
}

func main() {
    m := map[string]Person{
        "iswbm": Person{Age: 20},
    }
    m["iswbm"].Age = 23
    m["iswbm"].GrowUp()
}
```

没错，这段代码是错误的，当你编译时，会直接报错呢？原因在于这两行

```go
m["iswbm"].Age = 23
m["iswbm"].GrowUp()
```

我们知道 map 的值是不可寻址的，当你使用 `m["zhangsan"]` 取得值时，其实返回的是其值的拷贝，虽然与原数据值相同，但是在内存中并不是同一个数据。

也正是这样，当 map 的值是一个普通对象（非指针），是无法直接对其修改的。

针对这种错误，解决方法有两种：

- 第一种：新建变量，修改后再覆盖

```go
func main() {
    m := map[string]Person{
        "iswbm": Person{Age: 20},
    }
    p := m["iswbm"]
    p.Age = 23
    p.GrowUp()
    m["iswbm"] = p
}
```

- 第二种：使用指针的方式

```go
func main() {
    m := map[string]*Person{
        "iswbm": &Person{Age: 20},
    }
    m["iswbm"].Age = 23
    m["iswbm"].GrowUp()
}
```

## 为什么传参使用切片而不使用数组

>  Go里面的数组是值类型，切片是引用类型。

**值类型**的对象在做为实参传给函数时，形参是实参的另外拷贝的一份数据，对形参的修改不会影响函数外实参的值。

因此在如下例子中两次打印的指针地址是不一样的:

```go
package main

import "fmt"

func arrayTest (x [2]int) {
    fmt.Printf("%p \n", &x)  // 0xc0000b4030
}

func main() {
    arrayA := [2]int{1,2}
    fmt.Printf("%p \n", &arrayA) // 0xc0000b4010
    arrayTest(arrayA)
}
```

假想每次传参都用数组，那么每次数组都要被复制一遍。如果数组大小有 100万，在64位机器上就需要花费大约 800W 字节，即 8MB 内存。这样会消耗掉大量的内存。

而**引用类型**，则没有这个拷贝的过程，实参与形参指向的是同一块内存地址。

```go
package main

import "fmt"

func sliceTest (x []int) {
    fmt.Printf("%p \n", x)
}

func main() {
    sliceA := make([]int, 0)
    fmt.Printf("%p \n", sliceA)
    sliceTest(sliceA)
}
```

由此我们可以得出结论：

把第一个大数组传递给函数会消耗很多内存，采用切片的方式传参可以避免上述问题。切片是引用传递，所以它们不需要使用额外的内存并且比使用数组更有效率。

那么你肯定要问了，数组指针也是引用类型啊，也不一定要用切片吧？

确实，传递数组指针是可以避免对值进行拷贝的内存浪费。

## 引用类型与指针的区别

切片是一个引用类型，将它作为参数传入函数后，你在函数里对数据作变更是会实时反映到实参切片的。

```go
func foo(s []int)  {
    s[0] = 666
}

func main() {
    slice := []int{1,2}
    fmt.Println(slice) // [1 2]
    foo(slice)
    fmt.Println(slice) // [666 2]
}
```

此时切片这一引用类型，是不是有点像指针的效果？是的。

但它又和指针不一样，这一点主要体现在：在形参中所作的操作并不一定都会反映在实参上。

还是以切片为例，我在形参上对切片进行扩容，发现形参扩容后，实参并没有发生改变。

```go
func foo(s []int)  {
    s = append(s, 666)
}

func main() {
    slice := []int{1,2}
    fmt.Println(slice) // [1 2]
    foo(slice)
    fmt.Println(slice) // [1 2]
}
```

这是为什么呢？

这是因为当你对一个切片 append 的时候，它会做这些事情：

1. 新建一个新的切片 slice2，其实长度与 slice1 一样，但容量是 slice1 的两倍，此时 slice2 底层指向的匿名数组和 slice1 不是同一个。
2. 将 slice1 底层的数组的元素，一个一个的拷贝给 slice2 底层的数组。
3. 并把扩容的元素也拷贝到 slice2中
4. 最后把新的 slice2 返回回来，这就是为什么指针不用返回，而 slice.append 也要返回的原因

因此切片的形参做扩容，并不会影响到实参。

## 函数的参数为切片时是传引用还是传值

Golang中函数的参数为切片时是传引用还是传值？

对于这个问题，可能会有很多认为是传引用，就比如下面这段代码

```go
func foo(s []int)  {
    s[0] = 666
}

func main() {
    slice := []int{1,2}
    fmt.Println(slice) // [1 2]
    foo(slice)
    fmt.Println(slice) // [666 2]
}
```

如果你不了解 Go 中切片的底层结构，你很可能会误信上面的观点。

但其实不是，**Go语言中都是值传递，而不是引用传递，也不是指针传递**。

Go 中切片的底层结构是这样的

```go
type slice struct {
    array unsafe.Pointer
    len   int
    cap   int
}
```

而当你将切片作为实参传给函数时，函数是会拷贝一份实参的结构和数据，生成另一个切片，实参切片和形参切片，不仅是长度、容量相等，连指向底层数组的指针都是一样的。

通过分别打印实参切片和形参切片的指针地址，就能验证这一观点

```go
func foo(s []int)  {
    fmt.Printf("%p \n", &s) // 0xc00000c080
    s = append(s, 666)
}

func main() {
    slice := []int{1,2}
    fmt.Printf("%p \n", &slice)  // 0xc00000c060
    foo(slice)
    fmt.Printf("%p \n", &slice)  // 0xc00000c060
}
```

## Go语言中哪些是不可寻址的？

- 常量

```go
import "fmt"

const VERSION  = "1.0"

func main() {
    fmt.Println(&VERSION)
}
```

- 字符串

```go
func getStr() string {
    return "iswbm"
}
func main() {
    fmt.Println(&getStr())
    // cannot take the address of getStr()
}
```

- 函数或方法

```go
func getStr() string {
    return "iswbm"
}
func main() {
    fmt.Println(&getStr)
    // cannot take the address of getStr
}
```

- 基本类型字面量

```go
func getInt() int {
    return 1024
}

func main() {
    fmt.Println(&getInt())
    // cannot take the address of getInt()
}

```

- map 中的元素

```go
func main() {
    p := map[string]string {
        "name": "iswbm",
    }

    fmt.Println(&p["name"])
    // cannot take the address of p["name"]
}
```

- 数组字面量

数组字面量是不可寻址的，当你对数组字面量进行切片操作，其实就是寻找内部元素的地址，下面这段代码是会报错的

```go
func main() {
    fmt.Println([3]int{1, 2, 3}[1:])
    // invalid operation [3]int literal[1:] (slice of unaddressable value)
}
```

## 异常机制：panic和recover

### 触发panic

手动触发宕机，是非常简单的一件事，只需要调用 panic 这个内置函数即可，就像这样子。

```go
package main

func main() {
    panic("crash")
}
```

运行后，直接报错宕机:

```go
$ go run main.go
go run main.go
panic: crash

goroutine 1 [running]:
main.main()
        E:/Go-Code/main.go:4 +0x40
exit status 2
```

### 捕获 panic

`recover`可以让程序在发生宕机后起死回生。

但是 recover 的使用，有一个条件，就是它必须在 defer 函数中才能生效，其他作用域下，它是不工作的。

```go
import "fmt"

func set_data(x int) {
    defer func() {
        // recover() 可以将捕获到的panic信息打印
        if err := recover(); err != nil {
            fmt.Println(err)
        }
    }()

    // 故意制造数组越界，触发 panic
    var arr [10]int
    arr[x] = 88
}

func main() {
    set_data(20)

    // 如果能执行到这句，说明panic被捕获了
    // 后续的程序能继续运行
    fmt.Println("everything is ok")
}
```

运行后，输出如下:

```go
$ go run main.go
runtime error: index out of range [20] with length 10
everything is ok
```

通常来说，不应该对进入 panic 宕机的程序做任何处理，但有时，需要我们可以从宕机中恢复，至少我们可以在程序崩溃前，做一些操作，举个例子，当 web 服务器遇到不可预料的严重问题时，在崩溃前应该将所有的连接关闭，如果不做任何处理，会使得客户端一直处于等待状态，如果 web 服务器还在开发阶段，服务器甚至可以将异常信息反馈到客户端，帮助调试。

### 总结一下

Golang 异常的抛出与捕获，依赖两个内置函数：

- panic：抛出异常，使程序崩溃
- recover：捕获异常，恢复程序或做收尾工作

revocer 调用后，抛出的 panic 将会在此处终结，不会再外抛，但是 recover，并不能任意使用，它有强制要求，必须得在 defer 下才能发挥用途。

## Go语言中的异常类型

> 在 Go 没有异常类型，只有错误类型（Error）。

一个函数要是想返回错误，通常会使用返回值来表示错误状态，可逐层返回，直到被处理。

```go
f, err := os.Open("test.txt")
if err != nil {
    log.Fatal(err)
}
```

