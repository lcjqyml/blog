---
layout:     post
title:      "Docker下搭建Confluence"
date:       2017-02-11
author:     "Milin"
catalog:    true
tags:
 - 技术
 - Docker
 - Confluence
---

# 1. 概述
Confluence是企业级的Wiki解决方案，但是它并不是免费的。此博客将介绍怎样在Docker下安装Confluence并手动破解之。

# 2. 破解并安装
* 通过以下maven依赖下载jar包

        <dependency>
            <groupId>com.atlassian.extras</groupId>
            <artifactId>atlassian-extras-decoder-v2</artifactId>
            <version>3.2</version>
        </dependency>

* 反编译修改Version2LicenseDecoder.java的loadLicenseConfiguration方法，代码如下

        try {
            Properties props = new Properties();
            new DefaultPropertiesPersister().load(props, text);
            String desc = props.getProperty("Description");
            props.put("conf.LicenseTypeName", "COMMERCIAL");
            props.put("Description", desc.replace("Evaluation", "Commercial"));
            props.put("Evaluation", "false");
            props.put("ContactEMail", "XX@XX.XX");
            props.put("MaintenanceExpiryDate", "2099-09-29");
            props.put("LicenseExpiryDate", "2099-09-29");
            return props;
        } catch (IOException e) {
            throw new LicenseException("Could NOT load properties from reader", e);
        }

* 重新打jar包之后，开始构建破解版confluence镜像
* 创建Dockerfile并将jar包放入Dockerfile所在文件夹，Dockerfile内容如下：

        FROM blacklabelops/confluence
        RUN mv /opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.2.jar /opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.2.jar.bak
        COPY ./atlassian-extras-decoder-v2-3.2.jar /opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.2.jar

* 构建镜像

        docker build -t milin/confluence dockerfilepath

* 创建持久化本地路径(mkdir /opt/postgres4confluence)并启动confluence数据库容器

        docker run -d --name postgres4confluence -p 5432:5432 -v /opt/postgres4confluence:/var/lib/postgresql \
            -e 'POSTGRES_USER=confluence' \
            -e 'POSTGRES_PASSWORD=confluence' \
            -e 'POSTGRES_DB=confluencedb' \
            -e 'POSTGRES_ENCODING=UTF-8' \
            -e 'POSTGRES_COLLATE=C' \
            -e 'POSTGRES_COLLATE_TYPE=C' \
            blacklabelops/postgres

* 启动confluence容器，预先创建好持久化数据目录(mkdir /opt/confluence)

        docker run -d --name confluence -p 8888:8090 -p 8091:8091 -v /opt/confluence:/var/atlassian/confluence \
            --link postgres4confluence:postgres \
            milin/confluence

* 启动之后，通过 http://docker-host-ip:8888 访问confluence并配置，在配置的过程中需要去官网注册confluence试用码，参考本站“Docker下搭建Jira”博客
* 数据库配置页面需要如下配置：

    1. 选择Direct JDBC
    2. Driver Class Name: org.postgresql.Driver
    3. Database URL: jdbc:postgresql://postgres:5432/confluencedb
    4. User Name: confluence
    5. Password: confluence

* 最后是汉化，参考参考本站“Docker下搭建Jira”博客

### 参考文档
1. <https://github.com/blacklabelops/confluence>