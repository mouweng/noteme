# Linux多进程与多线程

- [C语言技术网](https://freecplus.net/d95f4eaf18eb46d19b82383519126dec.html)

## Linux多进程

### 进程的概念

 什么是进程？进程这个概念是针对系统而不是针对程序员的，对程序员来说，我们面对的概念是程序，当输入指令执行一个程序的时候，对系统而言，它将启动一个进程。

进程就是正在内存中运行中的程序，Linux下一个进程在内存里有三部分的数据，就是“代码段”、”堆栈段”和”数据段”。”代码段”，顾名思义，就是存放了程序代码。“堆栈段”存放的就是程序的返回地址、程序的参数以及程序的局部变量。而“数据段”则存放程序的全局变量，常数以及动态数据分配的数据空间（比如用new函数分配的空间）。

系统如果同时运行多个相同的程序，它们的“代码段”是相同的，“堆栈段”和“数据段”是不同的（相同的程序，处理的数据不同）。 

### 查看进程

- `ps`查看当前终端进程

- `ps -ef`查看系统全部的进程。
- `ps -ef | more` 查看系统全部的进程，结果分页显示。

- `ps -ef |grep book`查看系统全部的进程，然后从结果集中过滤出包含“book”单词的记录。

### getpid库函数

```c++
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
 
int main() {
    printf("本程序的进程编号是: %d\n",getpid());
    // 是为了方便查看进程在shell下用ps -ef|grep test查看本进程的编号。
    sleep(30);
}
```

### 多进程

> fork函数用于产生一个新的进程，函数返回值pid_t是一个整数，在父进程中，返回值是子进程编号，在子进程中，返回值是0。

fork在英文中是“分叉”的意思。为什么取这个名字呢？因为一个进程在运行中，如果使用了fork函数，就产生了另一个进程，于是进程就“分叉”了，所以这个名字取得很形象。

```c++
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
 
int main() {
    printf("本程序的进程编号是: %d\n", getpid());

    int ipid = fork();
    // sleep等待进程的生成。
    sleep(1);      
    printf("pid = %d\n", ipid);
    
    if (ipid != 0) 
        printf("父进程编号是: %d\n", getpid());
    else 
        printf("子进程编号是: %d\n", getpid());
    
    // 是为了方便查看进程在shell下用ps -ef|grep book252查看本进程的编号。
    sleep(30);
}
```

```shell
$ gcc -o test test5.cpp

$ ./test  
本程序的进程编号是: 59183
pid = 0
子进程编号是: 59192
pid = 59192
父进程编号是: 59183
```

fork函数创建了一个新的进程，新进程（子进程）与原有的进程（父进程）一模一样。子进程和父进程使用相同的代码段；子进程拷贝了父进程的堆栈段和数据段。子进程一旦开始运行，它复制了父进程的一切数据，然后各自运行，相互之间没有影响。

fork函数对返回值做了特别的处理，调用fork函数之后，在子程序中fork的返回值是0，在父进程中fork的返回是子进程的编号，程序员可以通过fork的返回值来区分父进程和子进程，然后再执行不同的代码。

```c++
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
 
// 父进程流程的主函数
void fatchfunc() {
  printf("我是父进程\n");
}
// 子进程流程的主函数
void childfunc() {
  printf("我是子进程\n");
}
 
int main() {
    printf("fork开始前,父进程会来到这里\n"); 
    if (fork()>0) { 
        printf("这是父进程,将调用fatchfunc()。\n"); 
        fatchfunc();
    } else { 
        printf("这是子进程,将调用childfunc()。\n");  
        childfunc();
    }
    sleep(1); 
    printf("父子进程执行完自己的函数后都来这里。\n"); 
    sleep(1);
}
```

```shell
$ gcc -o test test6.cpp

$ ./test               
fork开始前,父进程会来到这里
这是父进程,将调用fatchfunc()。
我是父进程
这是子进程,将调用childfunc()。
我是子进程
父子进程执行完自己的函数后都来这里。
父子进程执行完自己的函数后都来这里。
```

在上文上已提到过，**子进程拷贝了父进程的堆栈段和数据段，也就是说，在父进程中定义的变量子进程中会复制一个副本，fork之后，子进程对变量的操作不会影响父进程，父进程对变量的操作也不会影响子进程。**

```c++
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
 
int i = 10;
int main() {
  int j = 20;
  if (fork()>0) {
    i ++; j --; 
    printf("父进程: i = %d, j = %d\n", i, j);
  } else {
    i --; j ++;
    printf("子进程: i = %d, j = %d\n", i, j);
  }
}
```

```shell
$ gcc -o test test7.cpp
$ ./test 
父进程: i = 11, j = 19
子进程: i = 9, j = 21
```

## 多进程-课后作业

> 编写一个示例程序，由父进程生成10个子进程，在子进程中显示它是第几个子进程和子进程本身的进程编号。

```c++
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

int main() {
    for (int i = 0; i < 10; i ++) {
        if (fork() > 0) {
            continue;
        } else {
            printf("第%d个子进程: %d\n", i + 1, getpid());
            break;
        }
    }
}
```

```shell
$ gcc -o test ./test8.cpp
$ ./test                 
第1个子进程: 65789
第2个子进程: 65790
第3个子进程: 65791
第4个子进程: 65792
第5个子进程: 65793
第6个子进程: 65794
第7个子进程: 65795
第8个子进程: 65796
第9个子进程: 65797
第10个子进程: 65798
```

> 编写示例程序，由父进程生成子进程，子进程再生成孙进程，共生成第10代进程，在各级子进程中显示它是第几代子进程和子进程本身的进程编号。

```c++
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

int main() {
    for (int i = 0; i < 10; i ++) {
        if (fork() > 0) {
            sleep(20);
            return 0;
        }
        printf("第%d代子进程: %d\n", i + 1, getpid());
    }
}
```

```shell
$ gcc -o test ./test9.cpp
$ ./test                 
第1代子进程: 68092
第2代子进程: 68093
第3代子进程: 68094
第4代子进程: 68095
第5代子进程: 68096
第6代子进程: 68097
第7代子进程: 68098
第8代子进程: 68099
第9代子进程: 68100
第10代子进程: 68101

$ ps -ef | grep test
501 68000     1   0  3:43下午 ttys002    0:00.00 ./test
501 68086 58203   0  3:44下午 ttys002    0:00.00 ./test
501 68092 68086   0  3:44下午 ttys002    0:00.00 ./test
501 68093 68092   0  3:44下午 ttys002    0:00.00 ./test
501 68094 68093   0  3:44下午 ttys002    0:00.00 ./test
501 68095 68094   0  3:44下午 ttys002    0:00.00 ./test
501 68096 68095   0  3:44下午 ttys002    0:00.00 ./test
501 68097 68096   0  3:44下午 ttys002    0:00.00 ./test
501 68098 68097   0  3:44下午 ttys002    0:00.00 ./test
501 68099 68098   0  3:44下午 ttys002    0:00.00 ./test
501 68100 68099   0  3:44下午 ttys002    0:00.00 ./test
```

## Linux多线程

### 线程的概念

和多进程相比，多线程是一种比较节省资源的多任务操作方式。启动一个新的进程必须分配给它独立的地址空间，每个进程都有自己的堆栈段和数据段，系统开销比较高，进行数据的传递只能通过进程间通信的方式进行。在同一个进程中，可以运行多个线程，运行于同一个进程中的多个线程，它们彼此之间使用相同的地址空间，共享全局变量和对象，启动一个线程所消耗的资源比启动一个进程所消耗的资源要少。

### 线程的使用

[Linux多线程编程（10分钟入门）](http://c.biancheng.net/view/9025.html)

```c
// 创建线程
int pthread_create(pthread_t *thread,const pthread_attr_t *attr,void *(*start_routine) (void *),void *arg);

// 终止线程执行
void pthread_exit(void *retval);

// 一个线程可以借助 pthread_cancel() 函数向另一个线程发送“终止执行”的信号。
int pthread_cancel(pthread_t thread);

// pthread_join() 函数会一直阻塞当前线程，直至目标线程执行结束，阻塞状态才会消除。
int pthread_join(pthread_t thread, void ** retval);

```

```c
#include <stdio.h>
#include <pthread.h>

//定义线程要执行的函数，arg 为接收线程传递过来的数据
void* Thread1(void* arg)
{
    printf("This is Thread1!\n");
    return "Thread1成功执行";
}

//定义线程要执行的函数，arg 为接收线程传递过来的数据
void* Thread2(void* arg)
{
    printf("This is Thread2!\n");
    return "Thread2成功执行";
}

int main()
{
    int res;
    //创建两个线程变量 
    pthread_t mythread1, mythread2;
    void* thread_result;
    //创建 mythread1 线程，执行 Thread1() 函数
    res = pthread_create(&mythread1, NULL, Thread1, NULL);
    if (res != 0) {
        printf("线程创建失败");
        return 0;
    }
    //创建 mythread2 线程，执行 Thread2() 函数
    res = pthread_create(&mythread2, NULL, Thread2, NULL);
    if (res != 0) {
        printf("线程创建失败");
        return 0;
    }
    //阻塞主线程，直至 mythread1 线程执行结束，用 thread_result 指向接收到的返回值，阻塞状态才消除。
    res = pthread_join(mythread1, &thread_result);
    //输出线程执行完毕后返回的数据
    printf("%s\n", (char*)thread_result);
    //阻塞主线程，直至 mythread2 线程执行结束，用 thread_result 指向接收到的返回值，阻塞状态才消除。
    res = pthread_join(mythread2, &thread_result);
    printf("%s\n", (char*)thread_result);

    printf("主线程执行完毕\n");
    return 0;
}
```

```shell
$ gcc test10.c -o thread -lpthread
$ ./thread                        
This is Thread1!
This is Thread2!
Thread1成功执行
Thread2成功执行
主线程执行完毕
```

