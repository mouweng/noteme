# B树与B+树

> B tree 和 B+ tree是平衡多叉查找树，所有节点的平衡因子都为0。

## B+树

### 特点

- B+ tree是基于B tree和叶子节点顺序访问指针设计实现的
- 在 B+ Tree 中，一个节点中的 key 从左到右递增排列。
- 非叶子节点不存储数据，叶子节点数据用链表连接

### 操作

- 查找操作：在每个节点上进行二分查找，找对key所在的指针，递归直至找到叶子节点。
- 插入删除：会破坏树的平衡性，在插入删除后，要重新维护B+树（分裂、合并、旋转），开销大

### B+ tree比B tree的优势

- 查询性能稳定，所有查询都要找到叶子节点
- 叶子节点有链表相连，便于范围查询和排序
- 非叶子节点只存储主键，单一节点存储的元素更多，更矮胖，查询I/O次数减少

### B+ tree比红黑树、AVL树的优势

- 比二叉树更加矮胖，更少的I/O操作

## B+树详解

![B+树](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041300438.jpg)

如图所示，如果要查找数据项29，那么首先会把磁盘块1由磁盘加载到内存，此时发生一次IO，在内存中用二分查找确定29在17和35之间，锁定磁盘块1的P2指针，内存时间因为非常短（相比磁盘的IO）可以忽略不计，通过磁盘块1的P2指针的磁盘地址把磁盘块3由磁盘加载到内存，发生第二次IO，29在26和30之间，锁定磁盘块3的P2指针，通过指针加载磁盘块8到内存，发生第三次IO，同时内存中做二分查找找到29，结束查询，总计三次IO。真实的情况是，3层的b+树可以表示上百万的数据，如果上百万的数据查找只需要三次IO，性能提高将是巨大的，如果没有索引，每个数据项都要发生一次IO，那么总共需要百万次的IO，显然成本非常非常高。

1. 通过上面的分析，我们知道IO次数取决于b+数的高度h，假设当前数据表的数据为N，每个磁盘块的数据项的数量是m，则有h=㏒(m+1)N，当数据量N一定的情况下，m越大，h越小；而m = 磁盘块的大小 / 数据项的大小，磁盘块的大小也就是一个数据页的大小，是固定的，如果数据项占的空间越小，数据项的数量越多，树的高度越低。这就是为什么每个数据项，即索引字段要尽量的小，比如int占4字节，要比bigint8字节少一半。这也是为什么b+树要求把真实的数据放到叶子节点而不是内层节点，一旦放到内层节点，磁盘块的数据项会大幅度下降，导致树增高。当数据项等于1时将会退化成线性表。
2. 当b+树的数据项是复合的数据结构，比如(name,age,sex)的时候，b+数是按照从左到右的顺序来建立搜索树的，比如当(张三,20,F)这样的数据来检索的时候，b+树会优先比较name来确定下一步的所搜方向，如果name相同再依次比较age和sex，最后得到检索的数据；但当(20,F)这样的没有name的数据来的时候，b+树就不知道下一步该查哪个节点，因为建立搜索树的时候name就是第一个比较因子，必须要先根据name来搜索才能知道下一步去哪里查询。比如当(张三,F)这样的数据来检索时，b+树可以用name来指定搜索方向，但下一个字段age的缺失，所以只能把名字等于张三的数据都找到，然后再匹配性别是F的数据了， 这个是非常重要的性质，即索引的最左匹配特性。
