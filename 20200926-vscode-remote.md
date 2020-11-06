# VSCode Remote SSH 安装及使用

本文以 Windows Client 以及 Linux Host 演示搭建 VSCode Remote （ssh） 工作环境的工作环境。

## 操作过程

1. 搭建一个 Linux 主机，开启 SSHD 服务

2. Windows 客户端安装 Git，使能全局 Git Bash

3. Windows 客户端生成 RSA 密钥对

4. Linux 主机上编辑 `~/.ssh/authorized_keys`，添加公钥使能私钥登录方式

5. Windows 客户端创建文件 `C:\Users\%USERNAME%\.ssh\config`，将 Linux 主机信息填入，格式如下：

    ```
    Host xxxname
        User username
        HostName xx.xx.xx.xx
        Port 22
    ```

6. Windows 客户端上安装 Vscode 软件，并安装 Remote 三件套（container / ssh / wsl）

7. 按 `F1`，输入 `SSH`，然后 "Connect to Host"，连接过程中会再次弹出对话框选择 Host 类型（Linux）

8. 等待自动配置完成，这样就得到了一个 remote 环境 

> 注意：
>
> - SSHD 一般默认使用 22端口，配置文件目录 `/etc/ssh/etc/ssh/sshd_config`
> - RSA 密钥对 Git Bash 中路径为 `~/.ssh/`，对应 Windows 下目录为 `C:\Users\USERNAME\.ssh`

![image-20200926154436352](https://img.juzuq.com/20200926-154438-909.png)

## 使用

- 安装完 Remote SSH 后，可以利用 vscode 登录远程服务器主机，并实时修改主机上的文件。除本地 vscode 之外，其他所有工具链、插件均安装在主机上。
- Linux host 上 vscode-server 安装目录：`~/.vscode-server`

## Tips

- Windows VSCode  Terminal 中，选中内容下按下 `Ctrl + C` 不会发送中断信号，不选中任何内容则发送 INT 信号。
- 

### 无法安装 Python 插件

部署过程中发现会出现无法在远程安装 python 插件的问题，无日志提示。界面上一直显示 `Installing`。最后发现时由于我的 Ubuntu 20.04 上默认安装的是 python3，没有 python 可执行程序导致。出现问题时，未见错误提示，vscode client 上一直显示 installing。

解决方法如下：

```
cd /usr/bin
sudo ln -sf python3 python
```

- 重启 vscode 
- 重新安装插件

### VSCode 利用魔法上网加速下载

设置 http.proxy 字段即可。魔法上网工具需自备。

![image-20200926153705964](https://img.juzuq.com/20200926-153709-043.png)

![image-20200926153615686](https://img.juzuq.com/20200926-153618-917.png)

