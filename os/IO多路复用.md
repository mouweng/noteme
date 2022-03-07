# I/O多路复用

- [流？I/O 操作？阻塞？epoll?](https://learnku.com/articles/41814)

## 一、流？I/O 操作？阻塞？

### (1) 流

### (2) I/O 操作

### (3) 阻塞



## 二、解决阻塞死等待的办法

##### 办法一：非阻塞、忙轮询

##### 办法二：select

##### 办法三：epoll



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

水平触发的主要特点是，如果用户在监听 epoll 事件，当内核有事件的时候，会拷贝给用户态事件，但是如果用户只处理了一次，那么剩下没有处理的会在下一次 epoll_wait 再次返回该事件。

这样如果用户永远不处理这个事件，就导致每次都会有该事件从内核到用户的拷贝，耗费性能，但是水平触发相对安全，最起码事件不会丢掉，除非用户处理完毕。



### （2）边缘触发

