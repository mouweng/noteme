# MVCC实现原理

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

- 一行数据的trx_id = CREATOR_TRX_ID，表示数据是由当前事务修改的，可见。
- 一行数据的trx_id < MIN_TRX_ID，表示数据在事务创建之前修改的，可见。
- 一行数据的trx_id >= MAX_TRX_ID，表示数据在事务创建之后修改的，不可见。
- 一行数据的trx_id大于等于MIN_TRX_ID且小于MAX_TRX_ID，如果trx_id在TRX_IDS列表中，表示该事务还未提交，不可见；不在列表中代表已提交，可见。

#### 举例

![举例说明](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202204041450581.jpg)

## 读已提交和可重复度

- read commited时每次读取数据（一个事务两次读取）都生成一个Readview，所以能看到其他事务已提交的数据；

- repeatable read是每次开启事务只生成一个ReadView，之后都复用这个Readview。

