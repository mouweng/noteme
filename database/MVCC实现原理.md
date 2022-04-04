# MVCC实现原理

- [事务隔离级别和MVCC](https://juejin.cn/book/6844733769996304392/section/6844733770071801870)

> MVCC就是multi-Version Concurrency Controller，也叫多版本并发控制。MVCC的实现原理主要依赖于记录中的三个隐藏字段、Undo-Log和ReadView来实现的！

## MVCC的组成

### 隐藏字段

![隐藏字段](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041342101.jpg)

- DB_TRX_ID：事务ID，最后一次修改该记录的事物ID。
- DB_ROW_ID：隐藏主键，在记录没有主键时，会被创建。
- DB_ROLL_PTR：滚动指针，指向记录上一个版本，配合Undo-Log使用。

### Undo-Log

![UndoLog](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041342582.jpg)

- 回滚日志，保证事务原子性，记录数据多个事务版本。
- 当多个事务对同一个数据进行修改时，每开启一个事务，被操作的数据会生成一条临时数据，隐藏字段DB_TRX_ID的值为当前事务的事务ID，并将这些临时数据已链表的形式存入Undo-Log日志中，DB_ROLL_PTR的值指向Undo-Log链表中具体回滚的数据。
- undo log是逻辑日志，和redo log一样也会写入磁盘，undo log的日志的清理由具体的线程管理。

### ReadView

一致性视图，为某一时刻事务系统的**快照**，之后的读操作根据当前事务ID与快照中事务系统状态做比较，判断数据对事务的可见性。

- TRX_IDS：当前ReadView创建时还在运行的事务id列表
- MIN_TRX_ID：ReadView中最小事务ID
- MAX_TRX_ID：ReadView中最大事务ID+1
- CREATOR_TRX_ID：当前事务ID

#### 可见性规则

- 一行数据的trx_id = CREATOR_TRX_ID，当前事务在访问它自己修改过的记录，可见
- 一行数据的trx_id < MIN_TRX_ID，表明生成该版本的事务在当前事务生成`ReadView`前已经提交，可见
- 一行数据的trx_id >= MAX_TRX_ID，表明生成该版本的事务在当前事务生成`ReadView`后才开启，不可见
- 一行数据的trx_id大于等于MIN_TRX_ID且小于MAX_TRX_ID，如果trx_id在TRX_IDS列表中，表示该事务还未提交，不可见；不在列表中代表已提交，可见。

如果某个版本的数据对当前事务不可见的话，那就顺着版本链找到下一个版本的数据，继续按照上边的步骤判断可见性，依此类推，直到版本链中的最后一个版本。

#### 举例

![举例说明](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041450581.jpg)

## 读已提交和可重复度

在`MySQL`中，`READ COMMITTED`和`REPEATABLE READ`隔离级别的的一个非常大的区别就是它们生成ReadView的时机不同。

- read commited时每次读取数据（一个事务两次读取）都生成一个Readview，所以能看到其他事务已提交的数据；

- repeatable read是每次开启事务只生成一个ReadView，之后都复用这个Readview。

### 举例

#### 1. 初始化

我们需要创建一个表，并插入数据

 ```sql
 CREATE TABLE hero (
     number INT,
     name VARCHAR(100),
     country varchar(100),
     PRIMARY KEY (number)
 ) Engine=InnoDB CHARSET=utf8;
 
 INSERT INTO hero VALUES(1, '刘备', '蜀');
 
 mysql> SELECT * FROM hero;
 +--------+--------+---------+
 | number | name   | country |
 +--------+--------+---------+
 |      1 | 刘备   | 蜀      |
 +--------+--------+---------+
 1 row in set (0.00 sec)
 ```

比方说现在系统里有两个`事务id`分别为`100`、`200`的事务在执行：

```sql
# Transaction 100
BEGIN;

UPDATE hero SET name = '关羽' WHERE number = 1;

UPDATE hero SET name = '张飞' WHERE number = 1;
```

```sql
# Transaction 200
BEGIN;

UPDATE hero SET name = '赵云' WHERE number = 1;

UPDATE hero SET name = '诸葛亮' WHERE number = 1;
```

#### 2. READ COMMITTED 和 REPEATABLE READ

比方说现在系统里有两个`事务id`分别为`100`、`200`的事务在执行, 目前版本链情况如下，事务100做了两条更新但未提交。

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041607139.jpg)

假设现在有一个事务开始执行：

- 如果使用READ COMMITTED

```sql
# 使用READ COMMITTED隔离级别的事务
BEGIN;

# SELECT1：Transaction 100、200未提交
SELECT * FROM hero WHERE number = 1; # 得到的列name的值为'刘备'
```

- 如果使用REPEATABLE READ

```sql
# 使用REPEATABLE READ隔离级别的事务
BEGIN;

# SELECT1：Transaction 100、200未提交
SELECT * FROM hero WHERE number = 1; # 得到的列name的值为'刘备'
```

之后，我们把`事务id`为`100`的事务提交一下，就像这样：

```sql
# Transaction 100
BEGIN;

UPDATE hero SET name = '关羽' WHERE number = 1;

UPDATE hero SET name = '张飞' WHERE number = 1;

COMMIT;
```

然后再到`事务id`为`200`的事务中更新一下表`hero`中`number`为`1`的记录：

```sql
# Transaction 200
BEGIN;

UPDATE hero SET name = '赵云' WHERE number = 1;

UPDATE hero SET name = '诸葛亮' WHERE number = 1;
```

此刻，表`hero`中`number`为`1`的记录的版本链就长这样：

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041605481.jpg)

- 使用`READ COMMITTED`隔离级别的事务中继续查找这个`number`为`1`的记录，如下：

```sql
# 使用READ COMMITTED隔离级别的事务
BEGIN;

# SELECT1：Transaction 100、200均未提交
SELECT * FROM hero WHERE number = 1; # 得到的列name的值为'刘备'

# SELECT2：Transaction 100提交，Transaction 200未提交
SELECT * FROM hero WHERE number = 1; # 得到的列name的值为'张飞' <=注意这里的区别
```

以此类推，如果之后`事务id`为`200`的记录也提交了，再次在使用`READ COMMITTED`隔离级别的事务中查询表`hero`中`number`值为`1`的记录时，得到的结果就是`'诸葛亮'`了。

- 使用`REPEATABLE READ`隔离级别的事务中继续查找这个`number`为`1`的记录，如下：

```sql
# 使用REPEATABLE READ隔离级别的事务
BEGIN;

# SELECT1：Transaction 100、200均未提交
SELECT * FROM hero WHERE number = 1; # 得到的列name的值为'刘备'

# SELECT2：Transaction 100提交，Transaction 200未提交
SELECT * FROM hero WHERE number = 1; # 得到的列name的值仍为'刘备' <=注意这里的区别
```

也就是说两次`SELECT`查询得到的结果是重复的，记录的列`c`值都是`'刘备'`，这就是`可重复读`的含义。如果我们之后再把`事务id`为`200`的记录提交了，然后再到刚才使用`REPEATABLE READ`隔离级别的事务中继续查找这个`number`为`1`的记录，得到的结果还是`'刘备'`



**总结一下就是：使用READ COMMITTED隔离级别的事务在每次查询开始时都会生成一个独立的ReadView，而REPEATABLE READ只在第一次进行普通SELECT操作前生成一个ReadView，之后的查询操作都重复使用这个ReadView。**

