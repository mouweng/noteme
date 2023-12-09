# k8s学习笔记

> 本笔记基于 k8s- 1.18.0教程

- [尚硅谷 Kubernetes（k8s）入门到实战教程](https://www.bilibili.com/video/BV1GT4y1A756/?spm_id_from=333.788.video.desc.click&vd_source=bc627dd34a4fa1077c25bfd0209370cb)

## 一、k8s概念和架构

#### k8s概述和功能

- kubernetes在2014年由谷歌开源，是一种容器化集群管理系统。
- 使用k8s进行容器化应用部署，让整个过程更加简洁和高效。
- 使用k8s利于应用扩展，支持自动化部署、大规模可伸缩、应用容器化管理。
- K8s拥有自动装箱、自我修复（自愈能力）、水平扩展、服务发现（负载均衡）、滚动更新、版本回退、密钥和配置管理、存储编排、批处理。

#### k8s架构组件

- Master node（主控节点）
  - API server：集群统一入口，以restful风格方式请求，交给etcd进行存储
  - Scheduler：节点调度，选择node节点应用部署
  - Controller Manager：处理集群中常规的后台任务，一个资源对应一个控制器
  - etcd：存储部分，保存集群中相关的数据
- Worker node（工作节点）
  - kubelet：master派到node节点的代表，管理本机容器
  - kube-proxy：提供网络代理，实现负载均衡等操作

#### k8s核心概念

- Pod
  - 最小部署单元
  - 一组容器的集合
  - Pod中的容器共享网络
  - 生命周期是短暂的
- Controller
  - 确保预期的Pod副本数量
  - 无状态应用部署/有状态应用部署
  - 确保所有的node都运行同一个Pod
  - 一次性任务和定时任务

- Service
  - 定义一组Pod的访问规则

## 二、从零搭建k8s集群

搭建k8s环境平台规则



#### 基于客户端工具kubeadm



#### 基于二进制包方式



## 三、k8s核心概念

* Pod
* Controller
* Service  Ingress

- RBAC 安全控制模型
- Helm
- 持久存储

## 四、搭建集群监控平台系统



## 五、从零搭建高可用k8s集群



## 六、集群环境部署项目

