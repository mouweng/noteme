# volatile原理

> volatile 的底层实现原理是内存屏障

- 对 volatile 变量的写指令后会加入写屏障
- 对 volatile 变量的读指令前会加入读屏障