# Seafile Docker 升级（从 6.3.3 到 7.0.5）

今天早晨偶然想起看一下 Seafile 是否有升级引入一些团队的一些功能需求。然后就开始了历时 8 个小时的漫长升级过程。掉进了一个 mysql 的坑里。

## v6.3.3 至 v6.3.4

只有一个小版本。升级没什么障碍。

这个升级顺利。拉取最新镜像、删除、重启，一气呵成，没什么问题。

```
docker pull seafileltd/seafile:latest
docker rm -f seafile
docker run --restart=always -d --name seafile \
  -e SEAFILE_SERVER_HOSTNAME=192.168.0.100 \
  -v /opt/seafile-data:/shared \
  -p 8888:80 \
  seafileltd/seafile:latest
```

## v6.3.4 至 v7.0.5

[https://download.seafile.com/published/seafile-manual/docker/6.3%20upgrade%20to%207.0.md](https://download.seafile.com/published/seafile-manual/docker/6.3 upgrade to 7.0.md)

seafile v6.3.4 至 v7.0.5 修改了docker 架构，将数据库和缓存库的 docker 文件单独了出来。这样官方打包升级就不需要维护依赖库了，喜欢新的这个方式。

### 备份

```
cd /opt/seafile-data/seafile
sudo tar -cf conf.bak.tar conf

cd /opt/seafile-data
sudo tar -cf db.bak.tar db
```

### 更改数据库目录和配置文件

根据官方教程先进如下操作：

```
// 由于 docker 拆分，用户的数据库访问权限需要重新设置

// root 用户
sudo docker exec -it seafile /usr/bin/mysql -e "grant all on *.* to 'root'@'%.%.%.%' identified by 'db_dev';"

// seafile 用户
for database in {ccnet_db,seafile_db,seahub_db}; do sudo docker exec -it seafile /usr/bin/mysql -e "grant all on ${database}.* to 'seafile'@'%.%.%.%' identified by 'your_ccnet_db_password';"; done
```

然后需要修改文件的 数据库配置：涉及 `ccnet.conf`、 `seafile.conf`、 `seahub_settings.py`

-   ccnet.conf：Change the `HOST` value to `db` in the `[Database]` configuration section ;
-   seafile.conf：Change the `host` value to  `db` in the `[database]` configuration section ;
-   seahub_settings.py：Change the `'HOST'` value to `'db'` in the `DATABASES` dict，and change the `'LOCATION'` value to `'memcached:11211'` in the `CACHES` dict .

将数据库移到新的位置：

```
sudo mkdir -p /opt/seafile-mysql
sudo mv db /opt/seafile-mysql/
```

### 启动 Seafile 7.x

docker-compose.yml 文件可以在如下链接下载。

https://download.seafile.com/d/320e8adf90fa43ad8fee/files/?p=/docker/docker-compose.yml

启动也启动成功了，但是数据库疯狂报错，有问题。不过，新版本的 Seafile 是可以访问的。虽然网上查阅资料有人说这个问题无碍，但是官方没有给任何说法。报错部分截取如下：

```
  # docker-compose up
Starting seafile-memcached ...
Starting seafile-mysql ...
Starting seafile-memcached
Starting seafile-mysql ... done
Starting seafile ...
Starting seafile ... done
Attaching to seafile-memcached, seafile-mysql, seafile
seafile-mysql | 2020-03-21 07:37:40+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 1:10.1.44+maria-1~bionic start
seafile-mysql | 2020-03-21 07:37:40+00:00 [Note] [Entrypoint]: Switching to dedicated user 'mysql'
seafile-mysql | 2020-03-21 07:37:40+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 1:10.1.44+maria-1~bionic start
seafile      | *** Running /etc/my_init.d/01_create_data_links.sh...
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] mysqld (mysqld 10.1.44-MariaDB-1~bionic) starting as process 1 ...
seafile      | *** Running /etc/my_init.d/10_syslog-ng.init...
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: Using mutexes to ref count buffer pool pages
seafile      | Mar 21 07:37:41 3afd66fdcc72 syslog-ng[25]: syslog-ng starting up; version='3.13.2'
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: The InnoDB memory heap is disabled
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: GCC builtin __atomic_thread_fence() is used for memory barrie
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: Compressed tables use zlib 1.2.11
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: Using Linux native AIO
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: Using SSE crc32 instructions
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: Initializing buffer pool, size = 256.0M
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: Completed initialization of buffer pool
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: Highest supported file format is Barracuda.
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: 128 rollback segment(s) are active.
seafile-mysql | 2020-03-21  7:37:40 140625276610560 [Note] InnoDB: Waiting for purge to start
seafile-mysql | 2020-03-21  7:37:41 140625276610560 [Note] InnoDB:  Percona XtraDB (http://www.percona.com) 5.6.46-86.2 started;
seafile-mysql | 2020-03-21  7:37:41 140624313448192 [Note] InnoDB: Dumping buffer pool(s) not yet started
seafile-mysql | 2020-03-21  7:37:41 140625276610560 [Note] Plugin 'FEEDBACK' is disabled.
seafile-mysql | 2020-03-21  7:37:41 140625276610560 [Note] Server socket created on IP: '::'.
seafile-mysql | 2020-03-21  7:37:41 140625276610560 [Warning] 'proxies_priv' entry '@% root@39d51a4d70c4' ignored in --skip-name
seafile-mysql | 2020-03-21 07:37:41 7fe5dfa06700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:41 7fe5dfa06700 InnoDB: Error: Fetch of persistent statistics requested for table "mysql"."gtidnd mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21  7:37:41 140625276610560 [Note] mysqld: ready for connections.
seafile-mysql | Version: '10.1.44-MariaDB-1~bionic'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  mariadb.org binary distr
seafile      | *** Booting runit daemon...
seafile      | *** Runit started as PID 34
seafile      | *** Running /scripts/start.py...
seafile      | Mar 21 07:37:42 3afd66fdcc72 cron[39]: (CRON) INFO (pidfile fd = 3)
seafile      | Mar 21 07:37:42 3afd66fdcc72 cron[39]: (CRON) INFO (Skipping @reboot jobs -- not system startup)
seafile      | [2020-03-21 07:37:42] Skip running setup-seafile-mysql.py because there is existing seafile-data folder.
seafile      | [2020-03-21 07:37:42] Running scripts /opt/seafile/seafile-server-7.0.5/upgrade/upgrade_6.3_7.0.sh
seafile      | [03/21/2020 07:37:42][upgrade]: Running script /opt/seafile/seafile-server-7.0.5/upgrade/upgrade_6.3_7.0.sh
seafile      |
seafile      | -------------------------------------------------------------
seafile      | This script would upgrade your seafile server from 6.3 to 7.0
seafile      | Press [ENTER] to contiune
seafile      | -------------------------------------------------------------
seafile      |
seafile      |
seafile      | Updating seafile/seahub database ...
seafile      |
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "ccnet_db"."Umysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Recalculation of persistent statistics requested for table "ccnet_db"."nt or is corrupted. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seafile_db".d mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Recalculation of persistent statistics requested for table "seafile_db"sent or is corrupted. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seafile_db".ts and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."e_stats and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Recalculation of persistent statistics requested for table "seahub_db". but the required persistent statistics storage is not present or is corrupted. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."ats and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Recalculation of persistent statistics requested for table "seahub_db". but the required persistent statistics storage is not present or is corrupted. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."tats and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Recalculation of persistent statistics requested for table "seahub_db".not present or is corrupted. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Recalculation of persistent statistics requested for table "seahub_db".not present or is corrupted. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Recalculation of persistent statistics requested for table "seahub_db".stics storage is not present or is corrupted. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:42 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile      | [INFO] You are using MySQL
seafile      | [INFO] updating ccnet database...
seafile      | [INFO] updating seafile database...
seafile      | [INFO] updating seahub database...
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.TotalStorageStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.TotalStorageStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.TotalStorageStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.TotalStorageStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.FileOpsStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.FileOpsStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.UserActivityStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.UserActivityStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.UserActivityStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.UserActivityStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1146, "Table 'seahub_db.UserActivityStat' doesn't exist")
seafile      | [WARNING] Failed to execute sql: (1051, "Unknown table 'seahub_db.UserTrafficStat'")
seafile      | [WARNING] Failed to execute sql: (1091, "Can't DROP 'profile_profile_contact_email_0975e4bf_uniq'; check that col
seafile      | Done
seafile      |
seafile      | migrating avatars ...
seafile      |
seafile      | Done
seafile      |
seafile      | updating /opt/seafile/seafile-server-latest symbolic link to /opt/seafile/seafile-server-7.0.5 ...
seafile      |
seafile      |
seafile      |
seafile      | -----------------------------------------------------------------
seafile      | Upgraded your seafile server successfully.
seafile      | -----------------------------------------------------------------
seafile      |
seafile      |
seafile      | [03/21/20 07:37:42] ../common/session.c(132): using config file /opt/seafile/conf/ccnet.conf
seafile      | Starting seafile server, please wait ...
seafile      | ** Message: seafile-controller.c(718): No seafevents.
seafile      |
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seafile_db".and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seafile_db".sql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seafile_db".mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seafile_db".d mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seafile_db". and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:43 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seafile_db".ts and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile      | Seafile server started
seafile      |
seafile      | Done.
seafile      |
seafile      | Starting seahub at port 8000 ...
seafile-mysql | 2020-03-21 07:37:45 7fe5df970700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:45 7fe5df970700 InnoDB: Error: Fetch of persistent statistics requested for table "ccnet_db"."E mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile      |
seafile      | Seahub is started
seafile      |
seafile      | Done.
seafile      |
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."ts and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."db_table_stats and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."db_table_stats and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."tats and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."able_stats and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:53 7fe5df970700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:53 7fe5df970700 InnoDB: Error: Fetch of persistent statistics requested for table "ccnet_db"."Gql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:53 7fe5df970700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:53 7fe5df970700 InnoDB: Error: Fetch of persistent statistics requested for table "ccnet_db"."G mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:53 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:53 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seafile_db". and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:53 7fe5df925700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."s and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:54 7fe5df925700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:54 7fe5df925700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."innodb_table_stats and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:54 7fe5df9bb700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:54 7fe5df9bb700 InnoDB: Error: Fetch of persistent statistics requested for table "seafile_db".nd mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:37:54 7fe5df925700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21 07:37:54 7fe5df925700 InnoDB: Error: Fetch of persistent statistics requested for table "seahub_db"."ble_stats and mysql.innodb_index_stats are not present or have unexpected structure. Using transient stats instead.
seafile-mysql | 2020-03-21 07:40:14 7fe5df925700 InnoDB: Error: Column last_update in table "mysql"."innodb_table_stats" is INT
seafile-mysql | 2020-03-21  7:40:14 140625275148032 [Warning] 'proxies_priv' entry '@% root@39d51a4d70c4' ignored in --skip-name
'
```

## 数据库怎么了？

本来是在生产环境操作的（别跟我学），看着启动日志里的错误我慌张了一秒钟。不过各种改动都有备份，所以还是不怕的。然后把操作都还原了，回退之后一切运行正常，没有大碍。然后就开始复制生产环境搭测试机测试。先打包：（内网操作未压缩，整个文件有 50 G 多，内网千兆网卡稳定传输 100MB/s）

```
tar -xf seafile-data-bak.tar /opt/seafile-data
```

内网完成拷贝、解包后把环境复制了一份，然后再升级。

升级完成之后，尝试使用网上的方法进行修复，各种都没有用。

~~https://github.com/docker-library/mariadb/issues/217~~

~~https://github.com/docker-library/mariadb/issues/61~~

~~https://blog.csdn.net/baidu_35085676/article/details/72180391?utm_source=blogxgwz4~~

~~https://websiteforstudents.com/fix-mariadb-plugin-unix_socket-is-not-loaded-error-on-ubuntu-17-04-17-10/~~

这个帖子里的内容看着更靠谱一些。

https://bbs.seafile.com/t/topic/8175/6

然后我就开始尝试如何在 docker 下面登录到数据库进行操作。试过了各种办法都是不行。一直在报 unix_socket 的错误。由于本人对于 mysql 数据库属于未入门的水平，无法判断错误到底是什么意思。尤其是结合 docker 进行搜索更是不得要领。

```
  # docker exec -it seafile-mysql mysql -uroot -p                                      
Enter password:
ERROR 1524 (HY000): Plugin 'unix_socket' is not loaded

```

查阅资料后无果，然后就想着再回退试一下能否登录数据库。回退之后发现数据库可以登录。接着就查看了一下用户表。

```
use mysql;
slecet * from mysql.user;

MariaDB [mysql]> select * from mysql.user;
+-----------+---------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-------------+-----------------------+------------------+---------+
| Host      | User    | Password                                  | Select_priv | Insert_priv | Update_priv | Delete_priv | Create_priv | Drop_priv | Reload_priv | Shutdown_priv | Process_priv | File_priv | Grant_priv | References_priv | Index_priv | Alter_priv | Show_db_priv | Super_priv | Create_tmp_table_priv | Lock_tables_priv | Execute_priv | Repl_slave_priv | Repl_client_priv | Create_view_priv | Show_view_priv | Create_routine_priv | Alter_routine_priv | Create_user_priv | Event_priv | Trigger_priv | Create_tablespace_priv | ssl_type | ssl_cipher | x509_issuer | x509_subject | max_questions | max_updates | max_connections | max_user_connections | plugin      | authentication_string | password_expired | is_role |
+-----------+---------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-------------+-----------------------+------------------+---------+
| localhost | root    |                                           | Y           | Y           | Y           | Y           | Y           | Y         | Y           | Y             | Y            | Y         | Y          | Y               | Y          | Y          | Y            | Y          | Y                     | Y                | Y            | Y               | Y                | Y                | Y              | Y                   | Y                  | Y                | Y          | Y            | Y                      |          |            |             |              |             0 |           0 |               0 |                    0 | unix_socket |                       | N                | N       |
| 127.0.0.1 | seafile | *xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx | N           | N           | N           | N           | N           | N         | N           | N             | N            | N         | N          | N               | N          | N          | N            | N          | N                     | N                | N            | N               | N                | N                | N              | N                   | N                  | N                | N          | N            | N                      |          |            |             |              |             0 |           0 |               0 |                    0 |             |                       | N                | N       |
| %.%.%.%   | root    | *xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx | Y           | Y           | Y           | Y           | Y           | Y         | Y           | Y             | Y            | Y         | N          | Y               | Y          | Y          | Y            | Y          | Y                     | Y                | Y            | Y               | Y                | Y                | Y              | Y                   | Y                  | Y                | Y          | Y            | Y                      |          |            |             |              |             0 |           0 |               0 |                    0 |             |                       | N                | N       |
| %.%.%.%   | seafile | *xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx | N           | N           | N           | N           | N           | N         | N           | N             | N            | N         | N          | N               | N          | N          | N            | N          | N                     | N                | N            | N               | N                | N                | N              | N                   | N                  | N                | N          | N            | N                      |          |            |             |              |             0 |           0 |               0 |                    0 |             |                       | N                | N       |
+-----------+---------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-------------+-----------------------+------------------+---------+



MariaDB [(none)]> select * from mysql.user;
+-----------+------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+---------
```

最终在用户表里找到了一个关联项 unix_socket。把 plugin 选项清空再升级到新版本后进行尝试后恢复正常，可以正常登录。

```
update user set plugin='' where User='root';
```

 unix_socket 科普：https://mariadb.com/kb/en/authentication-plugin-unix-socket/

为了修复数据库报的错误，则需要手动执行 mysql_upgrade 指令。

## v6.3.4 至 v7.0.5 升级的正确姿势

1.  v6.3.4 根据官方推荐方式进行数据库权限设定
2.  v6.3.4 手动登录到数据库，删除 plugin 依赖
3.  数据库存储位置调整
4.  配置文件中的内容和名称更改
5.  升级并启动 v7.0.5
6.  v7.0.5 手动登录到 mysql 数据库
7.  v7.0.5 执行 mysql_upgrade 指令修复数据库
8.  docker-compose 重新启动镜像

### v7.0.5 正常启动的日志

```
root@hostname /opt/seafile-data
  # docker-compose up                                                                                                                                                                           !394
Starting seafile-memcached ...
Starting seafile-mysql ...
Starting seafile-memcached
Starting seafile-mysql ... done
Starting seafile ...
Starting seafile ... done
Attaching to seafile-memcached, seafile-mysql, seafile
seafile-mysql | 2020-03-21 07:40:52+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 1:10.1.44+maria-1~bionic started.
seafile-mysql | 2020-03-21 07:40:52+00:00 [Note] [Entrypoint]: Switching to dedicated user 'mysql'
seafile-mysql | 2020-03-21 07:40:52+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 1:10.1.44+maria-1~bionic started.
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] mysqld (mysqld 10.1.44-MariaDB-1~bionic) starting as process 1 ...
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] InnoDB: Using mutexes to ref count buffer pool pages
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] InnoDB: The InnoDB memory heap is disabled
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] InnoDB: GCC builtin __atomic_thread_fence() is used for memory barrier
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] InnoDB: Compressed tables use zlib 1.2.11
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] InnoDB: Using Linux native AIO
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] InnoDB: Using SSE crc32 instructions
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] InnoDB: Initializing buffer pool, size = 256.0M
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] InnoDB: Completed initialization of buffer pool
seafile-mysql | 2020-03-21  7:40:52 139683602946048 [Note] InnoDB: Highest supported file format is Barracuda.
seafile-mysql | 2020-03-21  7:40:53 139683602946048 [Note] InnoDB: 128 rollback segment(s) are active.
seafile-mysql | 2020-03-21  7:40:53 139683602946048 [Note] InnoDB: Waiting for purge to start
seafile-mysql | 2020-03-21  7:40:53 139683602946048 [Note] InnoDB:  Percona XtraDB (http://www.percona.com) 5.6.46-86.2 started; log sequence number 99747380
seafile-mysql | 2020-03-21  7:40:53 139682641868544 [Note] InnoDB: Dumping buffer pool(s) not yet started
seafile-mysql | 2020-03-21  7:40:53 139683602946048 [Note] Plugin 'FEEDBACK' is disabled.
seafile-mysql | 2020-03-21  7:40:53 139683602946048 [Note] Server socket created on IP: '::'.
seafile-mysql | 2020-03-21  7:40:53 139683602946048 [Warning] 'proxies_priv' entry '@% root@39d51a4d70c4' ignored in --skip-name-resolve mode.
seafile-mysql | 2020-03-21  7:40:53 139683602946048 [Note] mysqld: ready for connections.
seafile-mysql | Version: '10.1.44-MariaDB-1~bionic'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  mariadb.org binary distribution
seafile      | *** Running /etc/my_init.d/01_create_data_links.sh...
seafile      | *** Running /etc/my_init.d/10_syslog-ng.init...
seafile      | Mar 21 07:40:53 3afd66fdcc72 syslog-ng[25]: syslog-ng starting up; version='3.13.2'
seafile      | *** Booting runit daemon...
seafile      | *** Runit started as PID 32
seafile      | *** Running /scripts/start.py...
seafile      | Mar 21 07:40:53 3afd66fdcc72 cron[38]: (CRON) INFO (pidfile fd = 3)
seafile      | Mar 21 07:40:53 3afd66fdcc72 cron[38]: (CRON) INFO (Skipping @reboot jobs -- not system startup)
seafile      | [2020-03-21 07:40:53] Skip running setup-seafile-mysql.py because there is existing seafile-data folder.
seafile      | [03/21/2020 07:40:53][upgrade]: The container was recreated, running minor-upgrade.sh to fix the media symlinks
seafile      | [03/21/2020 07:40:53][upgrade]: Running script /opt/seafile/seafile-server-7.0.5/upgrade/minor-upgrade.sh
seafile      |
seafile      | -------------------------------------------------------------
seafile      | This script would do the minor upgrade for you.
seafile      | Press [ENTER] to contiune
seafile      | -------------------------------------------------------------
seafile      |
seafile      |
seafile      | ------------------------------
seafile      | migrating avatars ...
seafile      |
seafile      |
seafile      | DONE
seafile      | ------------------------------
seafile      |
seafile      |
seafile      | updating seafile-server-latest symbolic link to /opt/seafile/seafile-server-7.0.5 ...
seafile      |
seafile      | DONE
seafile      | ------------------------------
seafile      |
seafile      |
seafile      | [03/21/20 07:40:53] ../common/session.c(132): using config file /opt/seafile/conf/ccnet.conf
seafile      | Starting seafile server, please wait ...
seafile      | ** Message: seafile-controller.c(718): No seafevents.
seafile      |
seafile      | Seafile server started
seafile      |
seafile      | Done.
seafile      |
seafile      | Starting seahub at port 8000 ...
seafile      |
seafile      | Seahub is started
seafile      |
seafile      | Done.
seafile      |

```

## 7.0.x 功能特性介绍

https://bbs.seafile.com/t/topic/9166

## 其他

升级到 v7.0.5 英文操作系统下设置为页面显示中文并不正常。除 UI 上有些变化外似乎没有太大的改动，可能大部分功能都在 pro 版本中。其他功能有待进一步探索。

## 参考链接

[https://download.seafile.com/published/seafile-manual/docker/6.3%20upgrade%20to%207.0.md](https://download.seafile.com/published/seafile-manual/docker/6.3 upgrade to 7.0.md)

[https://download.seafile.com/published/seafile-manual/docker/6.3%20upgrade%20to%207.0.md](https://download.seafile.com/published/seafile-manual/docker/6.3 upgrade to 7.0.md)

https://download.seafile.com/d/320e8adf90fa43ad8fee/files/?p=%2Fdocker%2Fdocker-compose.yml





