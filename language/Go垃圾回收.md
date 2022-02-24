# Golang中GC回收机制

[Golang中GC回收机制三色标记与混合写屏障](https://www.bilibili.com/video/BV1wz4y1y7Kd)

## Go V1.3之前 标记-清除算法

### 主要步骤

此算法主要有两个主要的步骤：

- 标记(Mark phase)
- 清除(Sweep phase)

![标记清除主要步骤](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224191213.jpg)

**第一步**，STW(stop the world), 找出不可达的对象，然后做上标记。

**第二步**, 开始标记，程序找出它所有可达的对象，并做上标记。

**第三步**, 标记完了之后，然后开始清除未标记的对象。

**第四步**, 停止暂停，让程序继续跑。然后循环重复这个过程，直到process程序生命周期结束。

所以Go V1.3版本之前就是以上来实施的, 流程是

![标记清除](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224190001.webp)

Go V1.3 做了简单的优化,将STW提前, 减少STW暂停的时间范围.如下所示：

![标记清除](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/20220224190029.webp)

**这里面最重要的问题就是：mark-and-sweep 算法会暂停整个程序** 。

### 缺点

- STW，stop the world；让程序暂停，程序出现卡顿 **(重要问题)**。
- 标记需要扫描整个heap
- 清除数据会产生heap碎片

Go是如何面对并这个问题的呢？接下来G V1.5版本 就用**三色并发标记法**来优化这个问题.