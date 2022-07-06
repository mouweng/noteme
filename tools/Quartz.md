# Quartz定时器

- [Quartz--SpringBoot--整合/使用/教程/实例](https://blog.51cto.com/knifeedge/5257084)
- [Quartz的使用与持久化(springboot整合)](https://www.jianshu.com/p/d2f7ad108ab2)
- [SpringBoot Quartz指定时间执行任务及取消该定时任务](https://blog.csdn.net/qq_45186545/article/details/103818661)

> Quartz是对定时器的封装, 里面用他可以实现各种需求的定时任务, 因为他有强大的cron表达式，并且可以对定时任务进行持久化。

## Springboot整合Quartz

### 1.添加Quartz依赖

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<!--springboot-quartz-->
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-quartz</artifactId>
</dependency>
<!--Quartz 使用的连接池  这里Quartz在持久化任务时使用该jar-->
<dependency>
  <groupId>com.mchange</groupId>
  <artifactId>c3p0</artifactId>
  <version>0.9.5.5</version>
</dependency>
<!--Mysql数据库驱动-->
<dependency>
  <groupId>mysql</groupId>
  <artifactId>mysql-connector-java</artifactId>
  <version>5.1.27</version>
</dependency>
```

### 2.编写配置类

```java
package com.quartz.quartzduring.config;

import org.quartz.Scheduler;
import org.quartz.ee.servlet.QuartzInitializerListener;
import org.springframework.beans.factory.config.PropertiesFactoryBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.scheduling.quartz.SchedulerFactoryBean;

import java.io.IOException;
import java.util.Properties;

/**
 * Qartz配置, 搭配quartz.properties文件自定义配置, 该处目的使定时任务持久化
 */
@Configuration
public class SchedulerConfig {

    /**
     * 读取quartz.properties 文件
     * 将值初始化
     * @return
     */
    @Bean
    public Properties quartzProperties() throws IOException {
        PropertiesFactoryBean propertiesFactoryBean = new PropertiesFactoryBean();
        propertiesFactoryBean.setLocation(new ClassPathResource("/quartz.properties"));
        propertiesFactoryBean.afterPropertiesSet();
        return propertiesFactoryBean.getObject();
    }

    /**
     * 将配置文件的数据加载到SchedulerFactoryBean中
     * @return
     * @throws IOException
     */
    @Bean
    public SchedulerFactoryBean schedulerFactoryBean() throws IOException {
        SchedulerFactoryBean schedulerFactoryBean = new SchedulerFactoryBean();
        schedulerFactoryBean.setQuartzProperties(quartzProperties());
        return schedulerFactoryBean;
    }

    /**
     * 初始化监听器
     * @return
     */
    @Bean
    public QuartzInitializerListener executorListener(){
        return new QuartzInitializerListener();
    }

    /**
     * 获得Scheduler 对象
     * @return
     * @throws IOException
     */
    @Bean
    public Scheduler scheduler() throws IOException {
        return schedulerFactoryBean().getScheduler();
    }
}
```

### 3.编写quartz.properties配置文件

```java
# 实例化ThreadPool时，使用的线程类为SimpleThreadPool
org.quartz.threadPool.class = org.quartz.simpl.SimpleThreadPool
# threadCount和threadPriority将以setter的形式注入ThreadPool实例
# 并发个数
org.quartz.threadPool.threadCount = 5
# 优先级
org.quartz.threadPool.threadPriority = 5
org.quartz.threadPool.threadsInheritContextClassLoaderOfInitializingThread = true
org.quartz.jobStore.misfireThreshold = 5000
#持久化使用的类
org.quartz.jobStore.class = org.quartz.impl.jdbcjobstore.JobStoreTX
#数据库中表的前缀
org.quartz.jobStore.tablePrefix = QRTZ_
#数据源命名
org.quartz.jobStore.dataSource = qzDS
#qzDS 数据源
org.quartz.dataSource.qzDS.driver = com.mysql.jdbc.Driver
org.quartz.dataSource.qzDS.URL = jdbc:mysql://localhost:3306/test?useUnicode=true&characterEncoding=UTF-8
org.quartz.dataSource.qzDS.user = root
org.quartz.dataSource.qzDS.password = 123456
org.quartz.dataSource.qzDS.maxConnections = 10
```

### 4.创建Quartz持久化数据的表

```text
1.qrtz_blob_triggers : 以Blob 类型存储的触发器。
2.qrtz_calendars：存放日历信息， quartz可配置一个日历来指定一个时间范围。
3.qrtz_cron_triggers：存放cron类型的触发器。
4.qrtz_fired_triggers：存放已触发的触发器。
5.qrtz_job_details：存放一个jobDetail信息。
6.qrtz_job_listeners：job监听器。
7.qrtz_locks： 存储程序的悲观锁的信息(假如使用了悲观锁)。
8.qrtz_paused_trigger_graps：存放暂停掉的触发器。
9.qrtz_scheduler_state：调度器状态。
10.qrtz_simple_triggers：简单触发器的信息。
11.qrtz_trigger_listeners：触发器监听器。
12.qrtz_triggers：触发器的基本信息。
```

```sql
DROP TABLE IF EXISTS QRTZ_FIRED_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_PAUSED_TRIGGER_GRPS;
DROP TABLE IF EXISTS QRTZ_SCHEDULER_STATE;
DROP TABLE IF EXISTS QRTZ_LOCKS;
DROP TABLE IF EXISTS QRTZ_SIMPLE_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_SIMPROP_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_CRON_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_BLOB_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_JOB_DETAILS;
DROP TABLE IF EXISTS QRTZ_CALENDARS;

CREATE TABLE QRTZ_JOB_DETAILS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    JOB_NAME  VARCHAR(200) NOT NULL,
    JOB_GROUP VARCHAR(200) NOT NULL,
    DESCRIPTION VARCHAR(250) NULL,
    JOB_CLASS_NAME   VARCHAR(250) NOT NULL,
    IS_DURABLE VARCHAR(1) NOT NULL,
    IS_NONCONCURRENT VARCHAR(1) NOT NULL,
    IS_UPDATE_DATA VARCHAR(1) NOT NULL,
    REQUESTS_RECOVERY VARCHAR(1) NOT NULL,
    JOB_DATA BLOB NULL,
    PRIMARY KEY (SCHED_NAME,JOB_NAME,JOB_GROUP)
);

CREATE TABLE QRTZ_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    JOB_NAME  VARCHAR(200) NOT NULL,
    JOB_GROUP VARCHAR(200) NOT NULL,
    DESCRIPTION VARCHAR(250) NULL,
    NEXT_FIRE_TIME BIGINT(13) NULL,
    PREV_FIRE_TIME BIGINT(13) NULL,
    PRIORITY INTEGER NULL,
    TRIGGER_STATE VARCHAR(16) NOT NULL,
    TRIGGER_TYPE VARCHAR(8) NOT NULL,
    START_TIME BIGINT(13) NOT NULL,
    END_TIME BIGINT(13) NULL,
    CALENDAR_NAME VARCHAR(200) NULL,
    MISFIRE_INSTR SMALLINT(2) NULL,
    JOB_DATA BLOB NULL,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,JOB_NAME,JOB_GROUP)
        REFERENCES QRTZ_JOB_DETAILS(SCHED_NAME,JOB_NAME,JOB_GROUP)
);

CREATE TABLE QRTZ_SIMPLE_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    REPEAT_COUNT BIGINT(7) NOT NULL,
    REPEAT_INTERVAL BIGINT(12) NOT NULL,
    TIMES_TRIGGERED BIGINT(10) NOT NULL,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
        REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ_CRON_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    CRON_EXPRESSION VARCHAR(200) NOT NULL,
    TIME_ZONE_ID VARCHAR(80),
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
        REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ_SIMPROP_TRIGGERS
  (          
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    STR_PROP_1 VARCHAR(512) NULL,
    STR_PROP_2 VARCHAR(512) NULL,
    STR_PROP_3 VARCHAR(512) NULL,
    INT_PROP_1 INT NULL,
    INT_PROP_2 INT NULL,
    LONG_PROP_1 BIGINT NULL,
    LONG_PROP_2 BIGINT NULL,
    DEC_PROP_1 NUMERIC(13,4) NULL,
    DEC_PROP_2 NUMERIC(13,4) NULL,
    BOOL_PROP_1 VARCHAR(1) NULL,
    BOOL_PROP_2 VARCHAR(1) NULL,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP) 
    REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ_BLOB_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    BLOB_DATA BLOB NULL,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
        REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ_CALENDARS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    CALENDAR_NAME  VARCHAR(200) NOT NULL,
    CALENDAR BLOB NOT NULL,
    PRIMARY KEY (SCHED_NAME,CALENDAR_NAME)
);

CREATE TABLE QRTZ_PAUSED_TRIGGER_GRPS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_GROUP  VARCHAR(200) NOT NULL, 
    PRIMARY KEY (SCHED_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ_FIRED_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    ENTRY_ID VARCHAR(95) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    INSTANCE_NAME VARCHAR(200) NOT NULL,
    FIRED_TIME BIGINT(13) NOT NULL,
    SCHED_TIME BIGINT(13) NOT NULL,
    PRIORITY INTEGER NOT NULL,
    STATE VARCHAR(16) NOT NULL,
    JOB_NAME VARCHAR(200) NULL,
    JOB_GROUP VARCHAR(200) NULL,
    IS_NONCONCURRENT VARCHAR(1) NULL,
    REQUESTS_RECOVERY VARCHAR(1) NULL,
    PRIMARY KEY (SCHED_NAME,ENTRY_ID)
);

CREATE TABLE QRTZ_SCHEDULER_STATE
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    INSTANCE_NAME VARCHAR(200) NOT NULL,
    LAST_CHECKIN_TIME BIGINT(13) NOT NULL,
    CHECKIN_INTERVAL BIGINT(13) NOT NULL,
    PRIMARY KEY (SCHED_NAME,INSTANCE_NAME)
);

CREATE TABLE QRTZ_LOCKS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    LOCK_NAME  VARCHAR(40) NOT NULL, 
    PRIMARY KEY (SCHED_NAME,LOCK_NAME)
);


commit;
```

### 5.cron表达式

[cron表达式生成器](http://cron.qqe2.com/)

```java
"0 0 12 * * ?" 每天中午12点触发
"0 15 10 ? * *" 每天上午10:15触发
"0 15 10 * * ?" 每天上午10:15触发
"0 15 10 * * ? *" 每天上午10:15触发
"0 15 10 * * ? 2005" 2005年的每天上午10:15触发
"0 * 14 * * ?" 在每天下午2点到下午2:59期间的每1分钟触发
"0 0/5 14 * * ?" 在每天下午2点到下午2:55期间的每5分钟触发
"0 0/5 14,18 * * ?" 在每天下午2点到2:55期间和下午6点到6:55期间的每5分钟触发
"0 0-5 14 * * ?" 在每天下午2点到下午2:05期间的每1分钟触发
"0 10,44 14 ? 3 WED" 每年三月的星期三的下午2:10和2:44触发
"0 15 10 ? * MON-FRI" 周一至周五的上午10:15触发
"0 15 10 15 * ?" 每月15日上午10:15触发
"0 15 10 L * ?" 每月最后一日的上午10:15触发
"0 15 10 ? * 6L" 每月的最后一个星期五上午10:15触发
"0 15 10 ? * 6L 2002-2005" 2002年至2005年的每月的最后一个星期五上午10:15触发
"0 15 10 ? * 6#3" 每月的第三个星期五上午10:15触发
```

### 6.一个简单的定时器例子

#### a)编写job实现类

Job实现类, 就是定时任务的主要逻辑编辑区

```java
package com.quartz.quartzduring.job;

import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * @author: wengyifan
 * @description:
 * @date: 2022/7/5 5:19 下午
 */
public class HiJob implements Job {
    @Override
    public void execute(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String nowTime = simpleDateFormat.format(new Date());
        //这里为了演示, 只进行打印
        System.out.println(nowTime + ":你好");
    }
}
```

#### b)创建定时任务-->创建JobDetail, Trigger, Scheduler

Quartz的三大核心JobDetail, Trigger, Scheduler

- JobDetail: 主要加载定时逻辑实现的类
-  Trigger: 主要制定定时任务执行的规则
-  Scheduler:用来创建定时任务, 调度任务. 任务的增删改都是由他完成;

```java
package com.quartz.quartzduring.scheduler;

import com.quartz.quartzduring.job.HiJob;
import org.quartz.*;
import org.quartz.impl.StdSchedulerFactory;

import java.util.Date;

/**
 * 使用cron表达式来控制任务
 * 3秒后 每秒执行一次
 */
public class CronScheduler {

    public static void cronScheduler() throws SchedulerException {
        /*
         * JobBuilder.newJob(HiJob.class)  --> 创建执行的job实现类
         * withIdentity("j1", "1") 创建该JobDetail 的名字和所在分组 第一个参数是名字, 第二个参数 分组
         * build()创建对象
         */
        JobDetail build = JobBuilder.newJob(HiJob.class).withIdentity("j1", "1").build();

        Date date = new Date();
        long startTime = date.getTime() + 3000;

        /*
         * TriggerBuilder.newTrigger() 创建一个Trigger
         * startAt(new Date(startTime)) 执行时间, 3秒后执行
         * withIdentity("t1", "1") Trigger所在的名字和分组,
         * 第一个参数是名字, 第二个参数 分组,因为和job是俩个对象, 名字 分组可以跟job重复
         * withSchedule(CronScheduleBuilder.cronSchedule("* * * * * ?")) cron表达式初始化, 每秒执行一次
         * build()创建对象
         */
        CronTrigger c = TriggerBuilder.newTrigger()
                .startAt(new Date(startTime))
                .withIdentity("t1", "1")
                .withSchedule(CronScheduleBuilder.cronSchedule("* * * * * ?"))
                .build();
        //创建SchedulerFactory对象  注意是new的是StdSchedulerFactory Std开头
        SchedulerFactory schedulerFactory = new StdSchedulerFactory();
        //获得Scheduler
        Scheduler scheduler = schedulerFactory.getScheduler();
        //设置调度 的job 和trigger
        scheduler.scheduleJob(build, c);
        //开启调度
        scheduler.start();
    }

}
```

#### c)调用

```java
package com.quartz.quartzduring.controller;

import com.quartz.quartzduring.scheduler.CronScheduler;
import org.quartz.SchedulerException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author: wengyifan
 * @description:
 * @date: 2022/7/5 5:55 下午
 */
@RestController
@RequestMapping("")
public class testController {
    // @Description: 获取定时器信息
    @GetMapping("/test")
    public String getQuartzJob() throws SchedulerException {
        CronScheduler.cronScheduler();
        return "success";
    }

}
```

