---
layout:     post
title:      "Docker下搭建Jira"
date:       2017-01-14
author:     "Milin"
catalog:    true
tags:
 - 技术
 - Docker
 - Jira
---

# 1. 概述
Jira是一款非常强大的流程管理软件，是atlassian公司推出的收费软件，此处提供的并非官方的Jira Docker镜像安装教程，而是blacklabelops下的jira。

>部署过程会连带破解流程一起描述

# 2. 安装
安装jira总共分3大部分

* 数据库安装，此处使用blacklabelops/postgres
* Jira安装配置，使用blacklabelops/jira
* Jira汉化配置，官方下载汉化包配置

## 2.1 数据库安装
    docker run --name postgres -d \
    -e 'POSTGRES_USER=jira' \
    -e 'POSTGRES_PASSWORD=jira' \
    -e 'POSTGRES_DB=jiradb' \
    -e 'POSTGRES_ENCODING=UTF-8' \
    -e 'POSTGRES_COLLATE=C' \
    -e 'POSTGRES_COLLATE_TYPE=C' \
    -v /opt/postgres:/var/lib/postgresql \
    -p 5432:5432 \
    blacklabelops/postgres

>注意：官方文档里面缺少了初始化db配置 -e 'POSTGRES_DB=jiradb'

## 2.2 Jira安装
安装之前需要先构建破解版镜像，然后再进行后续操作

### 2.2.1 构建破解版镜像
* 在Docker主机下创建一个临时的jira构建目录 jira-build

        mkdir -p /opt/docker/build/jira-build/

* 下载[atlassian-extra.3.1.2.jar][a]，并放入`/opt/docker/build/jira-build/`
* 新建`/opt/docker/build/jira-build/Dockerfile`，并加入以下内容

        FROM blacklabelops/jira
        ENV JIRA_LIB_HOME=/opt/jira/atlassian-jira/WEB-INF/lib
        RUN rm ${JIRA_LIB_HOME}/atlassian-extra*.jar
        COPY ./atlassian-extras-3.1.2.jar ${JIRA_LIB_HOME}/atlassian-extras-3.1.2.jar

* 构建破解版镜像

        docker build -t milin/jira /opt/docker/build/jira-build/

[a]: https://github.com/lcjqyml/Study/blob/master/Docs/jira/jira%E7%A0%B4%E8%A7%A3%E8%A1%A5%E4%B8%81/atlassian-extras-3.1.2.jar

### 2.2.2 启动Jira容器并配置
    docker run -d --name jira \
    -e "JIRA_DATABASE_URL=postgresql://jira@postgres/jiradb" \
    -e "JIRA_DB_PASSWORD=jira"  \
    --link postgres:postgres \
    -v /opt/jira:/var/atlassian/jira \
    -p 8888:8080 milin/jira

* 若Jira容器在192.168.2.204上运行，则输入192.168.2.204:8888，等待启动界面完成
* Set up application properties

![Set up application properties](/img/jira/1.png)

* Specify your license key. 在这一步中，点击下方的“generate a JIRA trial license”，到官网申请一个30天的临时license。不过，由于中国的GFW，官网账号注册页面的验证码出不来，所以需要各自翻墙或者vpn到国外去注册，我使用freebrowser手机注册的账号。然后，license构建选择如下图：

![Specify your license key](/img/jira/2.png)

* 将第3步产生的license填入后Next，等待Jira配置完毕，进入“Set up administrator account”页面，配置系统管理员账号密码，Next
* Set up email notifications -> Later -> Finish

## 2.3 汉化Jira
* 进入[汉化包下载][b]页面，下载对应的插件包：JIRA Core-7.3.0-language-pack-zh_CN.jar
* 进入Jira页面，登录系统管理员账号，右上角齿轮图标（以下简称设置） -> Add-ons -> 左侧 Manage add-ons -> 右侧 Upload add-on -> 选择下载的汉化包 upload
* 右上角设置 -> System -> 右侧 Edit Setting -> Internationalization -> Indexing language 选择 Chinese / Default language 选择 中文（中国）
* 最下方Update搞定

PS: 书写此博客时，由于官方汉化包缺陷，系统仪表盘会有乱码出现，按照以下方式可解决：

* 在jira安装文件夹下bin目录找到setenv.sh文件，此方式需要进入到jira容器内部，进入方法：

        docker exec -ti jira bash

* 文件找到JVM_SUPPORT_RECOMMENDED_ARGS=
* 添加-Dfile.encoding=utf8，重启就可以了，重启方式：

        docker restart jira

[b]: https://translations.atlassian.com/dashboard/download?lang=zh_CN#/JIRA Core/7.3.0