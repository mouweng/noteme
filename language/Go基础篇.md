# Go基础篇

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

## Go语言中的异常类型

> 在 Go 没有异常类型，只有错误类型（Error）。

一个函数要是想返回错误，通常会使用返回值来表示错误状态，可逐层返回，直到被处理。

```go
f, err := os.Open("test.txt")
if err != nil {
    log.Fatal(err)
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

