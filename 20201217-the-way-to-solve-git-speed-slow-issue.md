# Windows SSH connect代理下Git Push速度慢的解决办法

> 如果对问题发现过程不感兴趣，请直接跳转至”[开启Git代理的正确姿势](#gitproxy)“

想准确描述这次遇到的问题还不太容易，需要加好几个限定词。

- 使用**Git**
- 使用**代理**
- 使用**SSH**模式（https模式无此问题）
- 使用Windows（其他环境下不会出现，如Linux）
- 在进行`git push`时（git clone 无此问题）、

在满足以上几个条件下进行git push时，速度都只有稳定的100kB，几乎没有波动。

![image-20201218080446906](https://img.juzuq.com/20201218-080449-686.png)

没有波动这个事情就让我觉得很蹊跷，有些不合常理，因为没有访问速度波动通常说明链路上大概率有**主动限流**，没有达到网络速度的瓶颈。

## 发现问题

先说说我是怎么发现和定位问题的。

最近使用Github频繁，直连是肯定没戏的，所以在使用过程中全程开启魔法上网。

然后发现了一个奇怪的现象，下行clone速度可以达到2.5MB/s，但是上行push只有大概100KB/s的速度，基本没啥波动。一开始我并没有十分在意，因为生活在一个有着神奇网络环境的国家久了，对于莫名其妙的网络相关的事情有些麻木了。但是后来我有了上传大文件到github的需求，只是一个100MB的文件传到github，用100kB/s传输，需要半个小时才能传完！这怎么能行！

忍无可忍之下，开始了本次的问题解决之旅。

最初怀疑的对象是代理工具可能存在上行的限流，简单使用Google Drive进行测试，上传速度峰值可以达到接近3MB/s（文件比较小，没测出峰值带宽）。

![image-20201218125706167](https://img.juzuq.com/20201218-125708-785.png)

这样我得出了一个github限制上行，要么是代理服务器进了github黑名单的**不靠谱结论**。

同时我也上网进行了搜索，github、speed、bandwith等关键字，发现只是在超大文件存储这块github才有限速，没有发现其他任何跟限速相关的内容。

后来，咨询了一下重度使用github的 [coco](https://img.juzuq.com/20201218-083229-922.png)（点击链接打开图片可扫描关注她的公众号），她没有遇到类似的情况，并特意帮我做了搜索还发了一篇文章让我参考。[【已解决】github.io的git的push非常慢 – 在路上](https://www.crifan.com/github_io_git_push_speed_too_slow/)（非常感谢 ）

文章描述的问题跟我遇到的问题不太一致，但是这篇文章对问题描写的很细致，做了很多资料查询和对比测试，这就让我意识到其实我也可以做一个系统测试来分析问题。事后看，当时我其实是走入了一个思维误区，先是错误进行归因，然后极力想证明归因的假设是正确的，一直没想过问题其实是别的原因导致的。

有了新想法，又顺着新思路开始重新搜索了一番，这次有了一个新发现，有个网友遇到了跟我一样的问题：
https://walkedby.com/sshwindowsproxy/

![image-20201218084821305](https://img.juzuq.com/20201218-084823-469.png)

博客作者也给了一个Ta的猜想。看到有人跟自己的问题一模一样，限制思路的自我怀疑立刻消失，一下子感觉多了一些力量。

## 分析问题

**0. 思路整理**

有了新思路后，重新理顺了自己的猜想，然后针对各种假设进行测试排除然后锁定问题。

- 速度限制是否为私有仓库引起？
- 速度限制是否为代理服务器进了github黑名单？
- 代理的使用姿势不对？

**1. 创建公开仓库**

选择创建公开仓库进行测试，是为了排除私有仓库可能影响上传速度的这一个因素。

https://github.com/JiapengLi/SpeedTest

**2. 本地进行推送测试，复现问题**

在本地仓库中添加了许多图片，提交后开始尝试推送，问题可以稳定复现。

![image-20201218090055895](https://img.juzuq.com/20201218-090058-155.png)

**3. 把仓库传到代理服务器进行`git push`测试**

SSH推送直连有接近12MB的速度，是本地传输速度的100多倍。

![image-20201218090346458](https://img.juzuq.com/20201218-090348-631.png)

![image-20201218090510030](https://img.juzuq.com/20201218-090512-289.png)

**4. 验证是否跟传输协议有关，本地https协议git push推送速度测试**

验证结果喜人，而且有一定的戏剧性，竟然有接近11MB的速度。原来这个问题直接换用https就能解决。我从2012年开始使用git进行开发，打从一开始就是使用的ssh协议，而且可以说是一直极力避免使用https。原因也很简单，SSH用起来方便啊，一把私钥走天下，也不用密码。

![image-20201218090949503](https://img.juzuq.com/20201218-090951-765.png)

**5. 为啥SSH走代理速度就奇慢呢？**

基于SSH正常进行clone的速度测下来大概平均2MB，这样推理，`git push`的速度理想情况应该也在这个附近不应偏离太远。

![image-20201218090828924](https://img.juzuq.com/20201218-090831-291.png)



为了验证这个假设，我找了一个Linux主机进行对比测试，结果符合预期，git push和git clone速度很接近。

Linux客户端代理配置：（~/.ssh/config，使用nc做代理转发）

```ssh_config
Host github.com
    User git
    Hostname github.com
    Port 22
    ProxyCommand nc -v -x localhost:1080 %h %p
```

速度测试结果：

![image-20201218093050632](https://img.juzuq.com/20201218-093052-918.png)

而Windows客户端的代理配置是这样的：

```ssh_config
Host github.com
    User git
    Hostname github.com
    Port 22
    ProxyCommand connect -S localhost:1080 %h %p
```

测试环境下所有除了使用的代理指令不同外，其他 均一致，这样我得出了一个初步结论，**Windows connect工具影响了SSH代理通信的速度。**

## 解决问题

### **换用 ncat 代理来解决问题**

既然怀疑到可能是connect的问题了，最直接的方法是找到替换方案。找到的方法是利用nmap工具包中的ncat工具。 https://nmap.org/ 

使用ncat的代理配置：（注意将`ncat`目录添加到`PATH`中）

```
 Host github.com
    User git
    Hostname github.com
    Port 22
    ProxyCommand ncat --verbose --proxy-type socks5 --proxy 127.0.0.1:1080 %h %p
```

![image-20201218100631683](https://img.juzuq.com/20201218-100633-920.png)

速度有了很大提升，但是还是低于预期（2.5MB/s）。

> 中间由于粗心以为指令名称是netcat，导致认为方案不行，好在写作本文时及时发现了这个问题。

### 阅读 connect 源码，给 connect 打补丁

找到connect路径，发现是mingw64下附带的一个包。

```
$ type connect
connect is /mingw64/bin/connect
```

找到出处：https://github.com/msys2/MINGW-packages/

但是这个包太老了，原链接失效了。

开了个issue询问，https://github.com/msys2/MINGW-packages/issues/7453

维护人员很快就回复并做了修改。https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-connect/PKGBUILD

响应速度出乎意料的快，这让我对msys2的维护团队好感顿生。开源造福世界！

这样就获知源码仓库：https://github.com/gotoh/ssh-connect 。

核对了一下版本号是 1.105，最新版，没错。

fork到自己的账户，然后clone回本地，阅读源代码，发现有一个 `-d` 选项可以开启debug。

开启调试后进行测试：

![image-20201218102620217](https://img.juzuq.com/20201218-102622-441.png)

**分析：**

- 每次sent都是1024字节，缓存疑似可以开大
- 获取sent关键字，进一步阅读源码，核心的函数是`do_repeater`

```C
/* relay byte from stdin to socket and fro socket to stdout.
   returns reason of termination */
int
do_repeater( SOCKET local_in, SOCKET local_out, SOCKET remote )
```

- 再进一步阅读，发现了一段奇怪代码。每次运行select函数会等待10ms，然后发送1KB数据（每秒发送100次1KB的数据包）。这样100KB/s限速的根源就找到了。

![image-20201218114844721](https://img.juzuq.com/20201218-114847-045.png)

**修改：**

找到问题了，修改方法就顺着思路来，调小延时时间以及同时调大缓冲区大小。补丁如下：

```diff
$ git diff b65b09a0ee06950972233e8ea86ef87c4e63b3c9 HEAD
diff --git a/connect.c b/connect.c
index f4c68cb..f78914e 100644
--- a/connect.c
+++ b/connect.c
@@ -2664,17 +2664,20 @@ stdindatalen (void)
 }
 #endif /* _WIN32 */

+char lbuf[512*1024];
+char rbuf[512*1024];
+
 /* relay byte from stdin to socket and fro socket to stdout.
    returns reason of termination */
 int
 do_repeater( SOCKET local_in, SOCKET local_out, SOCKET remote )
 {
     /** vars for local input data **/
-    char lbuf[1024];                            /* local input buffer */
+                              /* local input buffer */
     int lbuf_len;                               /* available data in lbuf */
     int f_local;                                /* read local input more? */
     /** vars for remote input data **/
-    char rbuf[1024];                            /* remote input buffer */
+                         /* remote input buffer */
     int rbuf_len;                               /* available data in rbuf */
     int f_remote;                               /* read remote input more? */
     int close_reason = REASON_UNK;              /* reason of end repeating */
@@ -2706,7 +2709,7 @@ do_repeater( SOCKET local_in, SOCKET local_out, SOCKET remote )
                    So use select() with short timeout and checking data
                    in stdin by another method. */
                 win32_tmo.tv_sec = 0;
-                win32_tmo.tv_usec = 10*1000;    /* 10 ms */
+                win32_tmo.tv_usec = 1;    /* 10 ms */
                 tmo = &win32_tmo;
             } else
 #endif /* !_WIN32 */
@@ -2832,7 +2835,11 @@ accept_connection (u_short port)
     int connection;
     struct sockaddr_in name;
     struct sockaddr client;
-    SOCKLEN_T socklen;
+#ifdef _WIN32
+    int socklen;
+#else
+    socklen_t socklen;
+#endif
     fd_set ifds;
     int nfds;
     int sockopt;

```

修改后的测速结果实测2.5MB/s以上。这下符合预期了！

![image-20201218115732995](https://img.juzuq.com/20201218-115738-875.png)

注意：这种临时修改可以满足我个人的SSH使用需求，但是改法过于简单粗暴，可能会导致CPU占用高或者其他我没有认知到的问题，暂时未做进一步深究。

### 打补丁后的性能对比测试

我分别在Ubuntu系统、Windows系统对同一个代理程序进行了速度测试。

- Ubuntu `nc` 
- Ubuntu `connect`
- Windows `connect` （打补丁后）

Ubuntu connect 

![image-20201217143737056](https://img.juzuq.com/20201217-143739-907.png)

Ubuntu nc 

![image-20201217143814808](https://img.juzuq.com/20201217-143817-463.png)

Windows connect （打补丁后）

![image-20201217144144194](https://img.juzuq.com/20201217-144146-552.png)

打补丁之后的Windows `connect`速度上与`nc`和Linux下的`connect`非常接近，几乎没有明显性能差异。

代码仓库：https://github.com/JiapengLi/ssh-connect

## 开启Git代理的正确姿势 <span id="gitproxy"> </span>

### SSH协议

本示例假定读者已经在本地1080端口部署了socks5的代理以及http代理。

#### 1. 利用connect工具

connect 支持全平台，不过在windows下面使用比较广

```
Host github.com
    User git
    Hostname github.com
    Port 22
    ProxyCommand connect -d -S localhost:1080 %h %p
```

#### 2. 利用nc / ncat工具

**nc **（Linux平台）

```
 Host github.com
    User git
    Hostname github.com
    Port 22
    ProxyCommand nc -v -x localhost:1080 %h %p
```

**ncat** （Windows）

```
 Host github.com
    User git
    Hostname github.com
    Port 22
    ProxyCommand ncat --verbose --proxy-type socks5 --proxy 127.0.0.1:1080 %h %p
```

#### 3. 利用ssh跳板机

使用ssh直连进行代理，需要走两次SSH加密，速度不太理想，在我的网络条件下，只有1MB/s的速度。

这种方法不需要本地安装任何代理工具，适合临时搭建代理之用。

```
Host example
    User uname
    HostName example.com
    Port 22

Host github.com
    User git
    Hostname github.com
    Port 22
    ProxyCommand ssh -W %h:%p example
```

### https协议

使能https代理：

```
git config --global http.proxy http://127.0.0.1:1080
```

关闭https代理：

```
git config --global --unset http.proxy
```

## SSH协议与HTTPS协议代理模式下的速度对比测试

### Git Clone 

![image-20201217143347137](https://img.juzuq.com/20201217-143350-538.png)

### Git Push

![image-20201218124350508](https://img.juzuq.com/20201218-124353-000.png)

## 总结

> 以下结论是根据在我个人的网络中的测试结果做的推论，请在不同网络环境下酌情参考。

- 直连模式下（不走代理），SSH和HTTPS的访问速度没太大差异
- 代理模式下，HTTPS速度完败SSH
- 连`github`优先选用`https`

## 番外

安利一个极简灵感记录工具——flomo，可以简单认为是**个人私密推特**。 

推荐注册链接：https://flomoapp.com/register2/?Mzg1OQ

![image-20201218075901403](https://img.juzuq.com/20201218-075904-265.png)

在命令行下使用flomo：

https://gist.github.com/JiapengLi/14592f9b9e87ea65666565be7db3f85b