# I/O多路复用

- [流？I/O 操作？阻塞？epoll?](https://learnku.com/articles/41814)
- [深入理解Linux中网络I/O复用并发模型](https://www.bilibili.com/video/BV1jK4y1N7ST?p=5)

## 一、流？I/O 操作？阻塞？

### (1) 流

- 可以进行 I/O 操作的内核对象
- 文件、管道、套接字……
- 流的入口：文件描述符 (fd)

### (2) I/O 操作

所有对流的读写操作，我们都可以称之为 IO 操作。

当一个流中， 在没有数据 read 的时候，或者说在流中已经写满了数据，再 write，我们的 IO 操作就会出现一种现象，就是阻塞现象，如下图。

![write阻塞](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220308104728.jpg)

![read阻塞](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220308104734.jpg)

### (3) 阻塞

![阻塞](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220308105322.jpg)

>  **阻塞等待**：不占用 CPU 的时间片

**阻塞场景**: 你有一份快递，家里有个座机，快递到了主动给你打电话，期间你可以休息。

> **非阻塞，忙轮询**：占用 CPU，系统资源

**非阻塞，忙轮询场景**: 你性子比较急躁， 每分钟就要打电话询问快递小哥一次， 到底有没有到，快递员接你电话要停止运输，这样很耽误快递小哥的运输速度。

#### 阻塞的缺点

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220308105526.jpg)

 也就是同一时刻，你只能被动的处理一个快递员的签收业务，其他快递员打电话打不进来，只能干瞪眼等待。那么解决这个问题，家里多买 N 个座机， 但是依然是你一个人接，也处理不过来，需要用影分身术创建都个自己来接电话 (采用多线程或者多进程）来处理。

 这种方式就是没有多路 IO 复用的情况的解决方案， 但是在单线程计算机时代 (无法影分身)，这简直是灾难。

那么如果我们不借助影分身的方式 (多线程 / 多进程)，该如何解决阻塞死等待的方法呢？

## 二、解决阻塞死等待的办法

### 办法一：非阻塞、忙轮询

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220308105800.jpg)

非阻塞忙轮询的方式，可以让用户分别与每个快递员取得联系，宏观上来看，是同时可以与多个快递员沟通 (并发效果)、 但是快递员在在用户沟通时耽误前进的速度 (浪费 CPU)。

```go
while true {
    for i in 流[] {
        if i has 数据 {
            读 或者 其他处理
        }
    }
}
```

### 办法二：select

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220308105814.jpg)

我们可以开设一个代收网点，让快递员全部送到代收点。这个网店管理员叫 select。这样我们就可以在家休息了，麻烦的事交给 select 就好了。当有快递的时候，select 负责给我们打电话，期间在家休息睡觉就好了。

但 select 代收员比较懒，她记不住快递员的单号，还有快递货物的数量。她只会告诉你快递到了，但是是谁到了，你需要挨个快递员问一遍。

```go
while true {
    select(流[]); //阻塞

  //有消息抵达
    for i in 流[] {
        if i has 数据 {
            读 或者 其他处理
        }
    }
}
```

### 办法三：epoll

epoll 的服务态度要比 select 好很多，在通知我们的时候，不仅告诉我们有几个快递到了，还分别告诉我们是谁谁谁。我们只需要按照 epoll 给的答复，来询问快递员取快递即可。

```java
while true {
    可处理的流[] = epoll_wait(epoll_fd); //阻塞

  //有消息抵达，全部放在 “可处理的流[]”中
    for i in 可处理的流[] {
        读 或者 其他处理
    }
}
```



## 三、epoll

- 与 select，poll 一样，对 I/O 多路复用的技术
- 只关心 “活跃” 的链接，无需遍历全部描述符集合
- 能够处理大量的链接请求 (系统可以打开的文件数目)

## 四、epoll 的 API

### （1）创建epoll

```c
/** 
 * @param size 告诉内核监听的数目 
 * @returns 返回一个epoll句柄（即一个文件描述符） 
 */
int epoll_create(int size);
```

```c
int epfd = epoll_create(1000);
```

![create_epoll](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220307212300.jpg)

创建一个 epoll 句柄，实际上是在内核空间，建立一个 root 根节点，这个根节点的关系与 epfd 相对应。

### （2）控制 epoll

```c
/**
* @param epfd 用epoll_create所创建的epoll句柄
* @param op 表示对epoll监控描述符控制的动作
*
* EPOLL_CTL_ADD(注册新的fd到epfd)
* EPOLL_CTL_MOD(修改已经注册的fd的监听事件)
* EPOLL_CTL_DEL(epfd删除一个fd)
*
* @param fd 需要监听的文件描述符
* @param event 告诉内核需要监听的事件
*
* @returns 成功返回0，失败返回-1, errno查看错误信息
*/
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);


struct epoll_event {
    __uint32_t events; /* epoll 事件 */
    epoll_data_t data; /* 用户传递的数据 */
}
/*
 * events : {EPOLLIN, EPOLLOUT, EPOLLPRI, EPOLLHUP, EPOLLET, EPOLLONESHOT}
 */

typedef union epoll_data {
    void *ptr;
    int fd;
    uint32_t u32;
    uint64_t u64;
} epoll_data_t;
```

```c
struct epoll_event new_event;

new_event.events = EPOLLIN | EPOLLOUT;
new_event.data.fd = 5;

epoll_ctl(epfd, EPOLL_CTL_ADD, 5, &new_event);
```

![controll_epoll](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220307212406.jpg)

 创建一个用户态的事件，绑定到某个 fd 上，然后添加到内核中的 epoll 红黑树中。

### （3）等待 EPOLL

 ```c
 /**
 *
 * @param epfd 用epoll_create所创建的epoll句柄
 * @param event 从内核得到的事件集合
 * @param maxevents 告知内核这个events有多大,
 * 注意: 值 不能大于创建epoll_create()时的size.
 * @param timeout 超时时间
 * -1: 永久阻塞
 * 0: 立即返回，非阻塞
 * >0: 指定微秒
 *
 * @returns 成功: 有多少文件描述符就绪,时间到时返回0
 * 失败: -1, errno 查看错误
 */
 int epoll_wait(int epfd, struct epoll_event *event, int maxevents, int timeout);
 ```

```c
struct epoll_event my_event[1000];

int event_cnt = epoll_wait(epfd, my_event, 1000, -1);
```

![等待epoll](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220307212436.jpg)

` epoll_wait` 是一个阻塞的状态，如果内核检测到 I/O 的读写响应，会抛给上层的 epoll_wait, 返回给用户态一个已经触发的事件队列，同时阻塞返回。开发者可以从队列中取出事件来处理，其中事件里就有绑定的对应 fd 是哪个 (之前添加 epoll 事件的时候已经绑定)。

### （4）使用 epoll 编程主流程骨架

```c
int epfd = epoll_crete(1000);

//将 listen_fd 添加进 epoll 中
epoll_ctl(epfd, EPOLL_CTL_ADD, listen_fd, &listen_event);

while (1) {
    //阻塞等待 epoll 中 的fd 触发
    int active_cnt = epoll_wait(epfd, events, 1000, -1);

    for (i = 0 ; i < active_cnt; i++) {
        if (evnets[i].data.fd == listen_fd) {
            //accept. 并且将新accept 的fd 加进epoll中.
        }
        else if (events[i].events & EPOLLIN) {
            //对此fd 进行读操作
        }
        else if (events[i].events & EPOLLOUT) {
            //对此fd 进行写操作
        }
    }
}
```

## 五、epoll的触发模式

### （1）水平触发

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220308110310.jpg)

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220308110320.jpg)

水平触发的主要特点是，如果用户在监听 epoll 事件，当内核有事件的时候，会拷贝给用户态事件，但是如果用户只处理了一次，那么剩下**没有处理的会在下一次 epoll_wait 再次返回该事件**。

这样如果用户永远不处理这个事件，就导致每次都会有该事件从内核到用户的拷贝，耗费性能，但是水平触发相对安全，最起码事件不会丢掉，除非用户处理完毕。

### （2）边缘触发

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220308110340.jpg)

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220308110351.jpg)

边缘触发，相对跟水平触发相反，当内核有事件到达， **只会通知用户一次**，至于用户处理还是不处理，以后将不会再通知。这样减少了拷贝过程，增加了性能，但是相对来说，如果用户马虎忘记处理，将会产生事件丢的情况。