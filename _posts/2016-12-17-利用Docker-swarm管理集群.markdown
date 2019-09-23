---
layout:     post
title:      "Docker Swarm管理Docker集群"
id:         "docker swarm"
date:       2016-12-17
author:     "Milin"
catalog:    true
tags:
 - 技术
 - Docker
---

# 1. 引言
>* 自Docker1.12版本开始，Swarm扩展不需要额外安装，nice！
* 以下内容总结自官方文档。

### 功能亮点
* 与Docker完美集成：不需要额外的协调软件来创建管理集群
* 分散设计：可以维护一个manager以及多个worker，通过manager即可管理所有的Swarm nodes
* service模式：使用service的方式运行container
* 负载均衡：可以设置不同的策略，进行containers的运行
* ...

>更多亮点请参照[官网说明](https://docs.docker.com/engine/swarm/)

在以下步骤中会使用以下host角色：

* manager: 192.168.2.201
* worker1: 192.168.2.202
* worker2: 192.168.2.203

>在进行以下步骤前，先关闭并清除防火墙规则，避免出现无法加入Swarm集群
>
    iptables -F

# 2. 配置Swarm manager
在manager上执行以下命令：

    docker swarm init --advertise-addr 192.168.2.201

执行结果：

    $ docker swarm init --advertise-addr 192.168.2.201
    Swarm initialized: current node (dxn1zf6l61qsb1josjja83ngz) is now a manager.

    To add a worker to this swarm, run the following command:

        docker swarm join \
        --token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
        192.168.2.201:2377

    To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

### 注意事项
为了保证某台manager在异常时不影响整个集群的工作，Swarm官方推荐应该配置多个manger进行容灾恢复

* 拥有3个manager的Docker集群可以容忍1台manger不可用
* 拥有N个manager的Docker集群可以容忍(N-1)/2台manger不可用
* `Swarm官方推荐一个Docker集群包含7个manager`
* 为了保证集群安全，建议每隔一段时间更换join-token，命令：` docker swarm join-token  --rotate [worker|manager] `

# 3. 添加Swarm worker
在以上两台worker上分别执行以下命令

    docker swarm join \
    --token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
    192.168.2.201:2377

# 4. Docker Swarm常用命令
`以下命令在manager上执行`

    docker node ls #列出当前集群节点
    docker node promote worker1 #将worker1升级为manager
    docker node demote manager #将manager降级为worker
    docker service create --name service_name -p port:port --replicas 2 image:version #在集群中启动2个image container
    docker service rm service_name #移除集群中所有的service_name
    docker service inspect service_name #查看服务状态

>可以在docker集群之上再配置一层代理，比如使用HAProxy
