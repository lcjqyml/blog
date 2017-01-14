---
layout:     post
title:      "Docker下搭建Jenkins"
date:       2016-12-20
author:     "Milin"
catalog:    true
tags:
 - 技术
 - Docker
 - Jenkins
---

# 1. 获取Jenkins镜像
    docker pull jenkins:latest

# 2. 运行容器
    docker run -d --restart=always --name jenkins -p 8080:8080 -p 50000:50000 \
    -v /var/jenkins_home:/var/jenkins_home jenkins

将jenkins_home挂载到物理机以避免container重启之后数据丢失，启动之后可以通过 host-ip:8080访问Jenkins页面

# 3. 问题

### 安装过程

* 插件无法完成安装：需手动顺序记录失败的插件，再到[jenkins插件仓库][a]手动下载hpi文件安装

[a]: https://updates.jenkins-ci.org/download/plugins/ "jenkins插件仓库"

### 项目配置

* 首次push之后无法再push：project的master分支默认开启了保护，需到gitlab对应项目设置中Protected Branches页面关闭分支保护或者开启push权限
* 自动触发构建：GitLab push之后Jenkins自动触发构建需要Jenkins安装gitlab-hook相关插件，GitLab中需要设置WebHook