---
layout:     post
title:      "Docker下搭建GitLab"
date:       2016-12-13
author:     "Milin"
catalog:    true
tags:
 - 技术
 - Docker
 - GitLab
---

# 1. 引言

Docker用来隔离应用还是很方便的，一来本身的操作较为简单，二来资源占用也比虚拟机要小得多，三来也较为安全，因为像数据库这样的应用不会再全局暴露端口，同时应用间的通信通过加密和端口转发，更加安全。

GitLab是目前比较流行的开源类GitHub代码管理平台。GitLab使用Rails开发，使用PostgreSQL或MySQL数据库，Redis做缓存。一般自己搭建私有代码仓库，GitLab通常是首选。这里简单介绍一下dockerized GitLab。

GitLab的docker镜像早已有人做好了，并且维护相当不错。大家可以前往其[GitHub仓库](https://github.com/sameersbn/docker-gitlab)了解该镜像的情况。官方repo的readme中已经有详细的安装配置方案，这里我简单的梳理一下部署流程。

# 2. 安装docker-gitlab
使用如下命令可以使Docker下载对应版本的GitLab镜像:

    docker pull sameersbn/gitlab:7.5.3

上面的命令下载7.5.3版的GitLab，如果想下载最新版本，可以输入以下命令:

    docker pull sameersbn/gitlab:latest

待下载完成后就算完成安装了。
也可以Clone刚才的提到的仓库，然后在本机上build镜像：

    git clone https://github.com/sameersbn/docker-gitlab.git
    cd docker-gitlab
    docker build --tag="$USER/gitlab" .

注意上面最后一行命令结尾有一个"."符号，不要掉了。

# 3. 安装PostgreSQL
GitLab推荐使用PostgreSQL作为数据库。既然使用了docker，那么我们为何不考虑把所有的组件都用docker包装起来？我们一样可以下载PostgreSQL的镜像完成安装，这种安装更加便捷。

首先输入以下命令下载PostgreSQL镜像：

    docker pull sameersbn/postgresql:latest

然后我们要为数据库默认的表空间建立目录以存放数据：

    mkdir -p /opt/postgresql/data

这里/opt/postgresql/data部分可以替换成你自己希望建立的地址。
如果是使用SELinux，那么还需要改变一下这个目录的安全设置：

    sudo chcon -Rt svirt_sandbox_file_t /opt/postgresql/data

如果没有使用SELinux，可以跳过上面一条命令。

最后使用以下命令行启动数据库：

    docker run --name gitlab-postgresql -d \
        --env 'DB_NAME=gitlabhq_production' \
        --env 'DB_USER=gitlab' --env 'DB_PASS=password' \
        --env 'DB_EXTENSION=pg_trgm' \
        --restart on-failure:5 \
        --volume /srv/docker/gitlab/postgresql:/var/lib/postgresql \
        sameersbn/postgresql:latest

这里，"--env"选项后面的内容请不要随意变更，这里的配置都是GitLab默认的数据库配置，如果没有在后面GitLab镜像启动的设置里面做相应的修改的话，这里的修改会让程序无法正常运行。

# 4. 安装Redis
同样，我们可以使用docker来安装Redis：

    docker pull sameersbn/redis:latest

然后启动它:

    docker run --name=gitlab-redis -d --restart on-failure:5 sameersbn/redis:latest

# 5. 启动GitLab
在最终启动GitLab之前，我们还需要为GitLab创建一个目录用来存放提交上来的代码，docker-gitlab内部使用/home/git/data这个目录存放代码，我们在容器外部创建一个目录然后在启动的时候挂载到这个路径即可：

    mkdir -p /opt/gitlab/data
    mkdir -p /opt/gitlab/backups

同样，如果使用SELinux，需要修改目录的安全配置:

    sudo chcon -Rt svirt_sandbox_file_t /opt/gitlab/data
    sudo chcon -Rt svirt_sandbox_file_t /opt/gitlab/backups

在完成上面所有的步骤以后，我们可以用以下命令启动GitLab：

        docker run --name gitlab -d \
            --restart on-failure:5 \
            --link gitlab-postgresql:postgresql --link gitlab-redis:redisio \
            --publish 10022:22 --publish 10080:80 \
            --env 'GITLAB_PORT=10080' --env 'GITLAB_SSH_PORT=10022' \
            --env 'GITLAB_SECRETS_DB_KEY_BASE=long-and-random-alpha-numeric-string' \
            --env 'GITLAB_SECRETS_SECRET_KEY_BASE=long-and-random-alpha-numeric-string' \
            --env 'GITLAB_SECRETS_OTP_KEY_BASE=long-and-random-alpha-numeric-string' \
            --env 'GITLAB_HOST=192.168.2.201' \
            --volume /opt/gitlab/data:/home/git/data \
            --volume /opt/gitlab/backups:/home/git/data/backups \
            sameersbn/gitlab:latest

上面的命令将使用10080作为GitLab的Web访问端口，10022将作为ssh push和pull代码的端口。
在本地可以使用浏览器打开http://192.168.2.201:10080 来访问GitLab。`注意：命令中ip为运行GitLab容器所在server的ip`

这里解释一下各参数：

    -d: 后台运行
    -e：配置GitLab运行的环境变量，这个参数很重要，具体有哪些环境变量，后面列举
    -p: 端口转发规则
    -v: 共享目录挂载，即docker容器内外数据共享

>特别注意：以上命令中：`long-and-random-alpha-numeric-string`为自己产生的随机密码，可以自己随机生成填上去, 官方推荐64位随机密码

GitLab的环境变量配置比较多，这里列举一下比较重要的GitLab的环境变量：

* GITLAB_HOST: 这个是GitLab服务器的hostname，你需要将此设定为网站的域名或者ip（不带端口号），默认值为localhost，这个值会被GitLab用来生成repo的链接，所以必须要设置。否则，在创建的repo中，会发现所有的repo链接都是以localhost为hostname。
* GITLAB_PORT: GitLab网站的访问端口，这里的设置要结合端口转发一起设置，否则会导致网站无法访问，默认值为80
* GITLAB_SSH_PORT: GitLab的SSH代码提交方式使用的SSH端口，这里的设置要结合端口转发一起设置，否则会导致代码无法提交，默认值为22。如果是在VPS上部署，这个值请使用别的端口，比如上面提到的10022端口，否则会与VPS原本的SSH端口产生冲突，造成SSH无法登录VPS
* GITLAB_BACKUPS: GitLab的自动备份配置，有disable, daily, weekly, monthly四个可选值，默认为disable。建议打开自动备份
* GITLAB_BACKUP_DIR: GitLab自动备份目录，默认值为/home/git/data/backups

### 参考文档
1. https://segmentfault.com/a/1190000002421271
2. https://github.com/sameersbn/docker-gitlab#installation