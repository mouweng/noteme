# 深入理解GMP模型

[Golang深入理解GPM模型](https://www.bilibili.com/video/BV19r4y1w7Nx)

[Golang 调度器 GMP 原理与调度全分析](https://learnku.com/articles/41728)

## 一、Golang调度器的由来

### 1.1 背景

- 单进程时代不需要调度器
- 多进程 / 线程时代有了调度器需求
- 协程来提高 CPU 利用率
    - 进程/线程数量越多、切换成本就越大、设计开发变得复杂

### 1.2 协程

其实一个线程分为 `内核态`线程和`用户态`线程。

一个 `用户态`线程 必须要绑定一个 `内核态`线程，但是 CPU 并不知道有 `用户态`线程 的存在，它只知道它运行的是一个 `内核态`线程(Linux 的 PCB 进程控制块)。

![用户线程与内核线程](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220223111925.png)

这样，我们再去细化去分类一下，内核线程依然叫 `线程` (thread)，用户线程叫 `协程` (co-routine).

![协程与内核线程](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220223112006.png)

所以就分为如下三种映射关系：

#### N：1关系

![N:1关系](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220223112311.png)

- 优点：**协程在用户态线程即完成切换，不会陷入到内核态，这种切换非常的轻量快速**。
- 缺点：无法使用多核、某协程阻塞造成其他携程都无法执行

#### 1:1关系

这种方式和使用线程无区别

![1:1](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220223112950.png)

#### M:N 关系

M 个协程绑定 1 个线程，是 N:1 和 1:1 类型的结合，克服了以上 2 种模型的缺点，但实现起来最为复杂。

![M:N](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220223113111.png)

协程跟线程是有区别的，线程由 CPU 调度是抢占式的，**协程由用户态调度是协作式的**，一个协程让出 CPU 后，才执行下一个协程。

### 1.3 Goroutine

> **Go 为了提供更容易使用的并发方法，使用了 goroutine 和 channel**。

- 占用内存更小（几 kb）
- 调度更灵活 (runtime 调度)

### 1.4 被废弃的 goroutine 调度器

![被废弃的调度器](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220223113440.png)

M 想要执行、放回 G 都必须访问全局 G 队列，并且 M 有多个，即多线程访问同一资源需要加锁进行保证互斥 / 同步，所以全局 G 队列是有互斥锁进行保护的。

- 创建、销毁、调度 G 都需要每个 M 获取锁，这就形成了**激烈的锁竞争**。
- M 转移 G 会造成延迟和额外的系统负载。比如当 G 中包含创建新协程的时候，M 创建了 G’，为了继续执行 G，需要把 G’交给 M’执行，也造成了很差的局部性，因为 G’和 G 是相关的，最好放在 M 上执行，而不是其他 M’。
- 系统调用 (CPU 在 M 之间的切换) 导致频繁的线程阻塞和取消阻塞操作增加了系统开销。

##  二、GMP 模型的设计思想

### 2.1  GMP 模型

>G -> goroutine协程
>
>P -> processor处理器
>
>M -> thread线程

在 Go 中，**线程是运行 goroutine 的实体，调度器的功能是把可运行的 goroutine 分配到工作线程上**。

![GMP模型](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220223144045.jpg)

- **全局队列**：存放等待运行的 G。
- **本地队列**：同全局队列类似，存放的也是等待运行的 G，存的数量有限，不超过 256 个。新建 G’时，G’优先加入到 P 的本地队列，如果队列满了，则会把本地队列中一半的 G 移动到全局队列。
- **P 列表**：所有的 P 都在程序启动时创建，并保存在数组中，最多有 `GOMAXPROCS`(可配置) 个。
- **M内核线程**：线程想运行任务就得获取 P，从 P 的本地队列获取 G，P 队列为空时，M 也会尝试从全局队列拿一批 G 放到 P 的本地队列，或从其他 P 的本地队列偷一半放到自己 P 的本地队列。M 运行 G，G 执行之后，M 会从 P 获取下一个 G，不断重复下去。

**Goroutine 调度器和 OS 调度器是通过 M 结合起来的，每个 M 都代表了 1 个内核线程，OS 调度器负责把内核线程分配到 CPU 的核上执行**。

**M 与 P 的数量没有绝对关系，一个 M 阻塞，P 就会去创建或者切换另一个 M，所以，即使 P 的默认数量是 1，也有可能会创建很多个 M 出来。**

### 2.2 调度器设计策略

**复用线程**：避免频繁的创建、销毁线程，而是对线程的复用。

- work stealing 机制

    > 当本线程无可运行的 G 时，尝试从其他线程绑定的 P 偷取 G，而不是销毁线程。

    **全局 G 队列**：在新的调度器中依然有全局 G 队列，但功能已经被弱化了，当 M 执行 work stealing 先从全局 G 队列获取 G，如果没有，则从其他P队列中偷取。

- hand off 机制

    > 当本线程因为 G 进行系统调用阻塞时，线程释放绑定的 P，把 P 转移给其他空闲的线程执行。

    1）**利用并行**：GOMAXPROCS 设置 P 的数量，最多有 GOMAXPROCS 个线程分布在多个 CPU 上同时运行。GOMAXPROCS 也限制了并发的程度，比如 GOMAXPROCS = 核数/2，则最多利用了一半的 CPU 核进行并行。

    2）**抢占式调度**：在 coroutine 中要等待一个协程主动让出 CPU 才执行下一个协程，在 Go 中，一个 goroutine 最多占用 CPU 10ms，防止其他 goroutine 被饿死，这就是 goroutine 不同于 coroutine 的一个地方。

### 2.3 go func () 调度流程

![go func调度流程](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220223153629.jpg)

 1、我们通过 go func () 来创建一个 goroutine；

 2、有两个存储 G 的队列，一个是局部调度器 P 的本地队列、一个是全局 G 队列。新创建的 G 会先保存在 P 的本地队列中，如果 P 的本地队列已经满了就会保存在全局的队列中；

 3、G 只能运行在 M 中，一个 M 必须持有一个 P，M 与 P 是 1：1 的关系。M 会从 P 的本地队列弹出一个可执行状态的 G 来执行，如果 P 的本地队列为空，会优先从全局队列中获取，如果没有，则从其他MP组合中偷取。

 4、一个 M 调度 G 执行的过程是一个循环机制；

 5、当 M 执行某一个 G 时候如果发生了 syscall 或则其余阻塞操作，M 会阻塞，如果当前有一些 G 在执行，runtime 会把这个线程 M 从 P 中摘除 (detach)，然后再创建一个新的操作系统的线程 (如果有空闲的线程可用就复用空闲线程) 来服务于这个 P；

 6、当 M 系统调用结束时候，这个 G 会尝试获取一个空闲的 P 执行，并放入到这个 P 的本地队列。如果获取不到 P，那么这个线程 M 变成休眠状态， 加入到空闲线程中，然后这个 G 会被放入全局队列中。

### 2.4 调度器的生命周期

![调度的生命周期](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220223154143.png)

- **M0**：是启动程序后的编号为 0 的主线程，这个 M 对应的实例会在全局变量 runtime.m0 中，不需要在 heap 上分配，M0 负责执行初始化操作和启动第一个 G， 在之后 M0 就和其他的 M 一样了。
- **G0**：是每次启动一个 M 都会第一个创建的 goroutine，G0 仅用于负责调度的 G，G0 不指向任何可执行的函数，每个 M 都会有一个自己的 G0。在调度或系统调用时会使用 G0 的栈空间，全局变量的 G0 是 M0 的 G0。

```go
package main

import "fmt"

func main() {
    fmt.Println("Hello world")
}
```

接下来我们来针对上面的代码对调度器里面的结构做一个分析。

1. `runtime` 创建最初的线程 `m0` 和 `goroutine g0`，并把 2 者关联。
2. 调度器初始化：初始化` m0`、栈、垃圾回收，以及创建和初始化由`GOMAXPROCS` 个 `P` 构成的 `P` 列表。
3. 示例代码中的 `main` 函数是 `main.main`，`runtime` 中也有 1 个 `main` 函数 ——`runtime.main`，代码经过编译后，`runtime.main` 会调用 `main.main`，程序启动时会为 `runtime.main` 创建 `goroutine`，称它为 `main goroutine `吧，然后把 `main goroutine` 加入到 `P` 的本地队列。
4. 启动 `m0`，`m0` 已经绑定了`P`，会从 `P` 的本地队列获取 `G`，获取到 `main goroutine`。
5. `G` 拥有栈，`M` 根据`G` 中的栈信息和调度信息设置运行环境
6. `M` 运行 `G`
7. `G` 退出，再次回到 `M` 获取可运行的 `G`，这样重复下去，直到 `main.main` 退出，`runtime.main` 执行 `Defer` 和 `Panic` 处理，或调用 `runtime.exit` 退出程序。

调度器的生命周期几乎占满了一个 Go 程序的一生，runtime.main 的 goroutine 执行之前都是为调度器做准备工作，runtime.main 的 goroutine 运行，才是调度器的真正开始，直到 runtime.main 结束而结束。

## 三、场景过程全分析

### 场景1

`P` 拥有 `G1`，`M1` 获取 `P` 后开始运行 `G1`，`G1` 使用 `go func()` 创建了 `G2`，为了局部性 `G2` 优先加入到 `P1` 的本地队列。

![场景1](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224112653.png)

### 场景2

`G1` 运行完成后 (函数：`goexit`)，M 上运行的 `goroutine` 切换为 `G0`（`G0`和`M`绑定，是`M`的一个成员变量），`G0` 负责调度时协程的切换（函数：`schedule`）。从 `P` 的本地队列取 `G2`，从 `G0` 切换到 `G2`，并开始运行 `G2` (函数：`execute`)。实现了线程 `M1` 的复用。

![场景2](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224121705.png)

### 场景3

假设每个 `P` 的本地队列只能存 3 个 `G`。`G2` 要创建了 6 个 `G`，前 3 个 `G`（`G3`, `G4`, `G5`）已经加入 `P1` 的本地队列，`P1` 本地队列满了。

![场景3](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224121649.png)

### 场景4

`G2` 在创建 `G7` 的时候，发现`P1` 的本地队列已满，需要执行**负载均衡** (把 `P1` 中本地队列中前一半的`G`，还有新创建`G` **转移**到全局队列）

> （实现中并不一定是新的 `G`，如果 `G` 是 `G2` 之后就执行的，会被保存在本地队列，利用某个老的 `G` 替换新`G` 加入全局队列）

![场景4](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224121626.png)

这些 `G` 被转移到全局队列时，会被打乱顺序。所以 `G3`,`G4`,`G7` 被转移到全局队列。

### 场景5

`G2` 创建 `G8` 时，`P1` 的本地队列未满，所以`G8` 会被加入到 `P1` 的本地队列。

![场景5](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224121603.png)

`G8` 加入到 `P1` 点本地队列的原因还是因为 `P1` 此时在与`M1` 绑定，而 `G2` 此时是`M1` 在执行。所以`G2` 创建的新的 `G` 会优先放置到自己的 `M` 绑定的 `P` 上。

### 场景6

规定：**在创建 `G` 时，运行的 `G` 会尝试唤醒其他空闲的 `P` 和 `M` 组合去执行**。

![场景6](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224121542.png)

假定 `G2` 唤醒了 `M2`，`M2` 绑定了 `P2`，并运行 `G0`，但 `P2` 本地队列没有 `G`，`M2` 此时为自旋线程**（没有 `G` 但为运行状态的线程，不断寻找 `G`）**。

### 场景7

`M2` 尝试从全局队列 (简称 `GQ`) 取一批 `G` 放到 `P2` 的本地队列（函数：`findrunnable()`）。`M2` 从全局队列取的`G` 数量符合下面的公式：

```go
n = min(len(GQ)/GOMAXPROCS + 1, len(GQ/2))
```

至少从全局队列取 1 个 `G`，但每次不要从全局队列移动太多的`G` 到 `P` 本地队列，给其他`P`留点。这是**从全局队列到 `P` 本地队列的负载均衡**。

![场景7](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224121519.jpg)

假定我们场景中一共有 4 个 `P`（`GOMAXPROCS` 设置为 4，那么我们允许最多就能用 4 个 `P` 来供 `M` 使用）。所以 `M2` 只从能从全局队列取 1 个 `G`（即 `G3`）移动` P2` 本地队列，然后完成从 `G0` 到 `G3` 的切换，运行 `G3`。

### 场景8

假设 `G2` 一直在 `M1` 上运行，经过 2 轮后，`M2` 已经把 `G7`、`G4` 从全局队列获取到了 `P2` 的本地队列并完成运行，全局队列和 `P2` 的本地队列都空了，如场景 8 图的左半部分。

![场景8](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224121456.png)

全局队列已经没有 `G`，那 `M` 就要执行 `work stealing` (偷取)：从其他有 `G` 的 `P` 哪里偷取一半 `G` 过来，放到自己的`P` 本地队列。`P2` 从 `P1` 的本地队列尾部取一半的` G`，本例中一半则只有 1 个 `G8`，放到 `P2` 的本地队列并执行。

### 场景9

`G1` 本地队列 `G5`、`G6` 已经被其他 `M` 偷走并运行完成，当前 `M1` 和 `M2` 分别在运行 `G2` 和 `G8`，`M3` 和 `M4` 没有 `goroutine` 可以运行，`M3` 和 `M4` 处于自旋状态，它们不断寻找 `goroutine`。

![场景9](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224121433.png)

为什么要让 `M3` 和 `M4` 自旋，自旋本质是在运行，线程在运行却没有执行 `G`，就变成了浪费 CPU. 为什么不销毁现场，来节约 CPU 资源。因为创建和销毁 CPU 也会浪费时间，我们希望当有新 `goroutine` 创建时，立刻能有` M` 运行它，如果销毁再新建就增加了时延，降低了效率。当然也考虑了过多的自旋线程是浪费 CPU，所以系统中最多有 `GOMAXPROCS` 个自旋的线程 (当前例子中的 `GOMAXPROCS=4`，所以一共 4 个 `P`)，多余的没事做线程会让他们休眠。

### 场景10

 假定当前除了 `M3` 和 `M4` 为自旋线程，还有 `M5` 和 `M6` 为空闲的线程 (没有得到 `P` 的绑定，注意我们这里最多就只能够存在 4 个 P，所以 `P` 的数量应该永远是 `M>=P`, 大部分都是 `M` 在抢占需要运行的 `P`)，`G8` 创建了 `G9`，`G8` 进行了阻塞的系统调用，`M2` 和 `P2` 立即解绑，`P2` 会执行以下判断：如果 `P2` 本地队列有 `G`、全局队列有 `G` 或有空闲的 `M`，`P2` 都会立马唤醒 1 个 `M` 和它绑定，否则 `P2` 则会加入到空闲 `P` 列表，等待 `M` 来获取可用的 `P`。本场景中，`P2` 本地队列有 `G9`，可以和其他空闲的线程 `M5` 绑定。

![场景10](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224121403.png)

### 场景11

`G8` 创建了 `G9`，假如 `G8` 进行了**非阻塞系统调用**。

![场景11](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224121331.png)

 `M2` 和 `P2` 会解绑，但 `M2` 会记住 `P2`，然后 `G8` 和 `M2` 进入系统调用状态。当 `G8` 和 `M2` 退出系统调用时，会尝试获取 `P2`，如果无法获取，则获取空闲的 `P`，如果依然没有，`G8` 会被记为可运行状态，并加入到全局队列，`M2` 因为没有 `P` 的绑定而变成休眠状态 (长时间休眠等待 `GC` 回收销毁)。

## 四、总结

总结，Go 调度器很轻量也很简单，足以撑起 goroutine 的调度工作，并且让 Go 具有了原生（强大）并发的能力。Go 调度本质是把大量的 goroutine 分配到少量线程上去执行，并利用多核并行，实现更强大的并发。
