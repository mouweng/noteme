# RabbitMQ

- [docker安装RabbitMq](https://juejin.cn/post/6844903970545090574)
- [保姆级别的RabbitMQ教程！一看就懂！](https://www.cnblogs.com/ZhuChangwu/p/14093107.html)
- [RabbitMQ最全使用教程-小白也能看懂](https://zhuanlan.zhihu.com/p/238317528)
- [RabbitMQ延迟队列](https://juejin.cn/post/6844904163168485383)
- [RabbitMQ 安装延迟队列插件实现延时消息](https://blog.csdn.net/zhuyu19911016520/article/details/103633482)
- [黑马程序员RabbitMQ全套教程，rabbitmq消息中间件到实战](https://www.bilibili.com/video/BV15k4y1k7Ep?p=31&spm_id_from=333.1007.top_right_bar_window_history.content.click&vd_source=bc627dd34a4fa1077c25bfd0209370cb)

> 由erlang语言开发，基于AMQP协议，在erlang语言特性的加持下，RabbitMQ稳定性要比其他的MQ产品好一些，而且erlang语言本身是面向高并发的编程的语言，所以RabbitMQ速度也非常快。且它基于AMQP协议，对分布式、微服务更友好。

## Docker安装RabbitMQ

### 拉取镜像

1. 使用`docker search rabbitMq`命令获取镜像列表

2. 使用`docker pull docker.io/rabbitmq:3.8-management` 拉取镜像

### 创建rabbitMq容器

1. 使用`docker images`获取查看RabbitMQ镜像ID
2. 执行`docker run --name rabbitmq -d -p 15672:15672 -p 5672:5672 [ContainerID]`命令创建RabbitMQ容器
3. `docker logs -f [ContainerID]`命令可以查看容器日志

### 访问Web界面

在浏览器输入你的`主机IP:15672`回车即可访问RabbitMq的Web端管理界面，默认用户名和密码都是`guest`

### 新添加一个账户

默认的`guest` 账户有访问限制，默认只能通过本地网络(如 localhost) 访问，远程网络访问受限，所以在使用时我们一般另外添加用户，例如我们添加一个root用户：

1. 执行`docker exec -i -t [ContainerID] bin/bash`进入到RabbitMQ容器内部
2. 执行`rabbitmqctl add_user root 123456` 添加用户，用户名为root,密码为123456
3. 执行`abbitmqctl set_permissions -p / root ".*" ".*" ".*"` 赋予root用户所有权限
4. 执行`rabbitmqctl set_user_tags root administrator`赋予root用户administrator角色
5. 执行`rabbitmqctl list_users`查看所有用户即可看到root用户已经添加成功

执行`exit`命令，从容器内部退出即可。这时我们使用root账户登录web界面也是可以的。



## RabbitMQ中的概念

### Message

不具名。由消息头和消息体构成。消息体是不透明的，消息头是由一系列的可选属性组成。

- `routing-key`路由键

- `priority`相对其他消息的优先权

- `delivery-mode`指出该消息是否需要永久存储等。

### Queue

消息的容器，一个消息可以放在一个或者多个队列中。

### Exchange

用来接受message并且将message路由给queue。有3种类型，即决定消息发布到哪个队列，具体有以下的类型：

- `Fanout`：广播模式，每个发送到fanout类型的交换器消息，交换器会将消息发送到它绑定的所有队列中，它转发消息是最快的。

  ![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202206301557377.png)

- `Direct`：完全匹配模式，根据消息中的路由键(routingkey)，如果和Binding中的binding key一致，那么就将消息发到对应的队列中。

  ![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202206301558591.png)

- `Topic`：主题模式，可以设置模糊匹配，会识别`#`和`*`号，#表示匹配0个或者多个单词,`*`匹配一个单词，单词之间使用`:`隔开。

  ![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202206301558852.png)

### Binding(绑定)

用于消息队列和交换器之间的关联，一个绑定就是基于路由键将交换机和消息队列连接起来的路由规则，交换器跟队列的绑定可以是多对多的关系。

### Channel(信道)

多路复用连接中的一条独立的双向数据流通道，信道是建立在真实的TCP连接内的虚拟通道,AMQP命令都是通过信道发出去的,不管是发布消息,订阅队列,还是接收消息，都是通过信道完成,因为对于操作系统来说创建和销毁一个TCP连接都是很昂贵的开销,所以使用信道以实现复用一条TCP连接。

### Connection(网络连接)

如一个Tcp连接。

### virtual host

可以类比于Mysql中的Database。即小型的RabbitMQ服务器，它表示一批交换器，消息队列和相关对象,连接时必须指定，默认是:/(以路径区分)。



![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202206301533123.jpg)



## Springboot整合RabbitMQ

### (一) 添加依赖

```xml
<dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-amqp</artifactId>
            <version>2.2.1.RELEASE</version>
</dependency>
```

### (二) 设置配置信息

```yml
spring:
  application:
    name: RabbitMQ-Test # 应用名称
  rabbitmq:
    host: localhost #rabbitServer的地址
    port: 5672 # 端口
    username: guest # 用户名称
    password: guest # 连接密码
    virtual-host: /
```

### (三) 启动类添加EnableRabbit注解

```java
@SpringBootApplication
@EnableRabbit
public class RabbitMqTestApplication {
    public static void main(String [] args){
        SpringApplication.run(RabbitMqTestApplication.class,args);
    }
}
```

### (四)连接部分

#### **Spring提供操作RabbitMQ的工具类**

**1、RabbitTemplate:** 是Spring集成RabbitMQ而提供的一个工具类,跟JdbcTemplate一样,可以通过它进行消息的发送和接收。

**2、RabbitAdmin :** 主要用于管理交换机和队列的信息。

```java
class RabbitmqDemoApplicationTests {
    private static AmqpAdmin amqpAdmin;
    private static CachingConnectionFactory connectionFactory;

    @BeforeEach
    public void loadNeedBean() {
        ConnectionFactory connFactory = new ConnectionFactory();
        connFactory.setHost("0.0.0.0");
        connFactory.setPort(5672);
        connFactory.setUsername("root");
        connFactory.setPassword("123456");
        connFactory.setVirtualHost("/");
        connectionFactory = new CachingConnectionFactory(connFactory);
        amqpAdmin = new RabbitAdmin(connectionFactory);
    }
}
```

### (五) 操作交换机(Exchange)

```java
@Test
public void rabbitExchangeTest() throws Exception{
    // 创建交换机
    // 参数分别是: 交换机名称,是否持久化，是否自动删除
    Exchange exchange = new DirectExchange("direct_test",true,false);
    amqpAdmin.declareExchange(exchange);
    // 删除交换机
    amqpAdmin.deleteExchange("direct_test");
}
```

### (六) 操作队列(Queue)

```java
@Test
public void rabbitExchangeAndQueueTest() throws Exception{
    // 创建队列
    Queue queue = new Queue("queue_test");
    amqpAdmin.declareQueue(queue);
    // 删除队列
    amqpAdmin.deleteQueue("task_queue");
}
```

### (七) 交换机和队列的绑定

```java
@Test
public void rabbitQueueTest() {
    // 创建交换机
    Exchange exchange = new DirectExchange("direct_test2", true, false);
    amqpAdmin.declareExchange(exchange);

    // 创建队列
    Queue queue = new Queue("queue_test2", true);
    amqpAdmin.declareQueue(queue);

    // 队列绑定到交换机
    Binding binding = new Binding("queue_test2", Binding.DestinationType.QUEUE, "direct_test2", "rount-key",null);
    amqpAdmin.declareBinding(binding);
}
```

### (八) 消息生产者发送消息到消息队列中

```java
@Test
public void messageProductTest(){
    // 消息操作模板
    RabbitTemplate template = new RabbitTemplate(connectionFactory);

    // 发送消息方式一
    String msg = "hello world";
    Message message = new Message(msg.getBytes());

    // 发送消息方式二
    HashMap map = new HashMap();
    map.put("key","value");

    template.convertAndSend("direct_test2","rount-key", message);
}
```

### (九) 消息消费者从队列中消费(手动执行的方式)

```java
@Test
public  void messageConsumerTest() throws Exception {
    RabbitTemplate template = new RabbitTemplate(connectionFactory);
    // 从队列中获取消息
    Message queue_test = template.receive("queue_test2");
    System.out.println(new String(queue_test.getBody(),"UTF-8"));
}
```

### (十) 消息消费者从队列中消费(自动监听，使用注解的方式)

```java
@RestController
public class RabbitController {
    @RabbitListener(queues = "queue_test2")
    public void messageListener(Message data) throws Exception {
        System.out.println("收到数据:----------");
        System.out.println(new String(data.getBody(),"UTF-8"));
    }
}
```

## 死信队列

> DLE, Dead Letter Exchange(死信交换机)，当消息成为Dead Message之后，可以被发送到另一个交换机，这个交换机就是DLE。

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202207051039685.png)

消息成为Dead Message的条件

- 消息TTL过期，且未被消费
- 队列消息长度达到限制，比如一个队列最大容量10条，当第11条来的时候，成为死信消息。
- 消费者拒绝消费消息，且不把消息重新放入原目标队列，requeue=false

队列绑定死信交换机

- 给队列设置参数：x-dead-letter-exchange和x-dead-letter-routing-key

## 实现延时队列

> 延迟队列也是一个消息队列，只是它是一个带延迟功能的消息队列。消息进入队列后不会立即被消费，只有到达指定之间后才会被消费。

- 订单下单之后30分钟未支付会自动取消订单
- MatchUs匹配消息延迟发送

可能有人会问，以上情况，我起个**定时任务**轮询处理，也能达到目的。是的，确实能达到目的，但是如果在该类业务数据量大的情况，处理起来就会十分麻烦，对服务器造成较大压力，并且轮询会有较大误差产生。如果使用延时队列来完成可以避免此类问题。

rabbitmq本身是不直接支持延时队列的，RabbitMQ的延迟队列基于消息的存活时间TTL（Time To Live）和死信交换机DLE（Dead Letter Exchanges）实现：

1. TTL：RabbitMQ可以对队列和消息各自设置存活时间，规则是两者中较小的值，即队列无消费者连接的消息过期时间，或者消息在队列中一直未被消费的过期时间
2. DLE：过期的消息通过绑定的死信交换机，路由到指定的死信队列，消费者实际上消费的是死信队列上的消息

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202207051033572.png)

### 1.安装插件

需要安装插件：[详见文章](https://blog.csdn.net/zhuyu19911016520/article/details/103633482)

### 2.配置信息

```yml
spring:
  application:
    name: RabbitMQ-Test # 应用名称
  rabbitmq:
    host: localhost #rabbitServer的地址
    port: 5672 # 端口
    username: guest # 用户名称
    password: guest # 连接密码
    virtual-host: /
```

### 3.配置类

```java
@Configuration
public class RabbitMqDelaydConfig {
    // 初始化延时队列
    @Bean
    public Queue delayedQueue() {
        return new Queue("delayed.queue");
    }
  
    // 定义一个延迟交换机
    @Bean
    public CustomExchange delayExchange() {
        Map<String, Object> args = new HashMap<String, Object>();
        args.put("x-delayed-type", "direct");
        return new CustomExchange("delay_exchange", "x-delayed-message", true, false, args);
    }

    // 绑定队列到这个延迟交换机上
    @Bean
    public Binding bindingNotify(@Qualifier("delayedQueue") Queue queue,
                                 @Qualifier("delayExchange") CustomExchange customExchange) {
        return BindingBuilder
          		.bind(queue)
          		.to(customExchange)
          		.with("delayed.queue.routingkey")
          		.noargs();
    }
}
```

### 4.编写消息发送者

```java
@Component
public class DelaySender {
    @Autowired
    private AmqpTemplate rabbitTemplate;

    public void delayedMessage() {
        String context = "test delay message";
        System.out.println("Send time: " + LocalDateTime.now() + "  Send: " + context);
        //延时时间6秒
        rabbitTemplate.convertAndSend("delay_exchange", 
                                      "delayed.queue.routingkey", 
                                      context, 
                                      a -> {
            a.getMessageProperties().setDelay(10000);
            return a;
        });
    }
}
```

### 5.编写消息消费者

```java
@Component
public class DelayReceiver {
    @RabbitListener(queues = "delayed.queue")
    public void receive(Message message, Channel channel) throws IOException {
        String s = new String(message.getBody());
        System.out.println("Received time: " + LocalDateTime.now() + "  Received: " + s);
        channel.basicAck(message.getMessageProperties().getDeliveryTag(), false);
    }
}
```

### 6.测试发送

```java
@RestController
public class DemoController {
    @Autowired
    private DelaySender delaySender;

    @GetMapping("/delaySender")
    public String delaySender() {
        delaySender.delayedMessage();
        return "ojbk";
    }
}
```

访问：`localhost:8080/delaySender`。至此，可以看到，6秒之后接收到消息，延时消息发送成功与接收成功。

## 消息可靠性保障

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202207041619091.jpg)

## 消息幂等性保障

用CAS乐观锁来保障

