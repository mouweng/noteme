# Redis分布式锁

- [漫画：什么是分布式锁？](https://mp.weixin.qq.com/s/8fdBKAyHZrfHmSajXT_dnA)
- [分布式锁的实现之 redis 篇](https://xiaomi-info.github.io/2019/12/17/redis-distributed-lock/)
- [Redis 分布式锁的正确实现方式（ Java 版 ）](https://developer.aliyun.com/article/307547)

## 分布式锁使用场景

对于单进程并发场景，我们可以使用语言和类库提供的锁。比如Java里面的Synchronized和ReentrantLock，但是在分布式环境中，这种方式就失效了。

所以我们这个时候需要用到分布式锁，来保证不同机器上的不同线程对代码和资源的同步访问。

## 分布式锁的类型

- **Memcached分布式锁**：利用Memcached的**add命令**（原子操作）。
- **Redis分布式锁**：和Memcached的方式类似，利用Redis的**setnx命令**（原子操作）。
- **Zookeeper分布式锁**：利用Zookeeper的**顺序临时节点**，来实现分布式锁和等待队列。
- **Chubby**：Google公司实现的粗粒度分布式锁服务，底层利用了Paxos一致性算法。

## Redis分布式锁原理

### setnx key value

加锁命令。

- 当一个线程执行setnx返回1，说明key原本不存在，该线程成功得到了锁；

- 当一个线程执行setnx返回0，说明key已经存在，该线程抢锁失败。

### del key

有加锁就得有解锁。

当得到锁的线程执行完任务，需要释放锁，以便其他线程可以进入。释放锁的最简单方式是执行del指令。释放锁之后，其他线程就可以继续执行setnx命令来获得锁。

### expire key timeSec

setnx的key必须设置一个**超时时间**，以保证即使没有被显式释放，这把锁也要在一定时间后自动释放。如果一个得到锁的线程在执行任务的过程中挂掉，来不及显式地释放锁，这块资源将会永远被锁住，别的线程再也别想进来。

但是setnx不支持超时参数，所以需要额外的expire指令。

综合起来，我们分布式锁实现的第一版伪代码

```java
if（setnx（key，1） == 1）{
  expire（key，30)
  try {
		do something ......
	} finally {
    del（key）
	}
}
```

但是setnx和expire的非原子性，就会存在如下问题：当某线程执行setnx，成功得到了锁，还未来得及执行expire指令就挂掉了。这样这把锁就永远访问不了了。

### set key value [ex|px time] nx

Redis 2.6.12以上版本为**set**指令增加了可选参数

这样setnx和expire就变成一个原子操作！

```shell
set key value [EX seconds] [PX milliseconds] [NX|XX]
  
案例：设置name=mouweng，失效时长100s，不存在时设置
set name mouweng ex 100 nx
```

### del误删情况改进

某线程成功得到了锁，并且设置的超时时间是30秒。如果某些原因导致线程A执行的很慢很慢，过了30秒都没执行完，这时候锁过期自动释放，线程B得到了锁。随后，线程A执行完了任务，线程A接着执行del指令来释放锁。但这时候线程B还没执行完，**线程A实际上删除的是线程B加的锁**。

解决方案：**加锁的时候把当前的线程ID当做value，并在删除之前验证key对应的value是不是自己线程的ID。**

```java
set（key，threadId ，ex, 30，NX）
  
if(threadId == get(key)){
    del(key)
}
```

但是又存在一个问题：**判断和释放锁非原子操作**

### Lua脚本实现del

```java
String luaScript = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end";
eval(luaScript, key, threadId);
```

这样一来，验证和删除过程就是原子操作了。

### 守护线程进行锁续航

还是刚才del误删场景，虽然我们避免了线程A误删掉key的情况，但是同一时间有A，B两个线程在访问代码块，仍然是不完美的。

可以让获得锁的线程开启一个**守护线程**，用来给快要过期的锁“续航”。当过去了29秒，线程A还没执行完，这时候守护线程会执行expire指令，为这把锁“续命”20秒。守护线程从第29秒开始执行，每20秒执行一次。

## 总结

- `set key value [ex|px time] nx` 保证原子性添加分布式锁，value设置为线程threadId
- `del`使用lua脚本，进行验证threadId和del的原子操作
- 设置守护进程为运行慢的线程续航分布式锁

## Java实现Redis分布式锁

```xml
<dependency>
  <groupId>redis.clients</groupId>
  <artifactId>jedis</artifactId>
  <version>2.9.0</version>
</dependency>
```

```java
import redis.clients.jedis.Jedis;

import java.util.Collections;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * @author: wengyifan
 * @description:
 * @date: 2022/4/13 12:12 上午
 */
public class RedisTool {
    private static final String LOCK_SUCCESS = "OK";
    private static final String SET_IF_NOT_EXIST = "NX";
    private static final String SET_WITH_EXPIRE_TIME = "EX";
    private static final Long RELEASE_SUCCESS = 1L;

    public static boolean tryGetDistributedLock(Jedis jedis, String lockKey, String requestId, int expireTime) {
        String result = jedis.set(lockKey, requestId, SET_IF_NOT_EXIST, SET_WITH_EXPIRE_TIME, expireTime);
        if (LOCK_SUCCESS.equals(result)) {
            return true;
        }
        return false;
    }

    public static boolean releaseDistributedLock(Jedis jedis, String lockKey, String requestId) {
        String script = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end";
        Object result = jedis.eval(script, Collections.singletonList(lockKey), Collections.singletonList(requestId));
        if (RELEASE_SUCCESS.equals(result)) {
            return true;
        }
        return false;
    }

    public static void main(String[] args) {
        ThreadPoolExecutor executor = new ThreadPoolExecutor(
                2,
                4,
                60,
                TimeUnit.SECONDS,
                new ArrayBlockingQueue<Runnable>(2)
        );
        Runnable r = ()->{
            Jedis jedis = new Jedis("localhost");
            String tname = Thread.currentThread().getName();
            System.out.println(tname + " 开始运行");
            while (!tryGetDistributedLock(jedis, "java", tname, 60)) {}
            System.out.println(tname + " 获取锁");
            try {
                Thread.sleep(5000L);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println(tname + " 执行完毕");
            if (releaseDistributedLock(jedis, "java", tname)) {
                System.out.println(tname + " 释放锁");
            }
        };
        executor.execute(r);
        executor.execute(r);
    }
}

```

