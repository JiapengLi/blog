# Ubuntu Host 下 VirtualBox 搭建


> 快速把一件事做到及格水平完结它，比「追求质量不断延期」好一百倍，比「害怕失败，总觉得准备不充分而迟迟无法开始」好一万倍。—— 推特章工
> https://twitter.com/435Hz/status/1524561244212051968

装了很久的vbox遇到了无法无法创建网卡的问题，进行解决，并记录一下配置过程。
*遇到一个打开 Vbox 的菜单无法截图的问题，暂未解决，故所有菜单相关操作没有图片。*

## 安装

```
sudo apt-get remove --purge virtualbox

sudo apt update
sudo apt-get install virtualbox virtualbox—ext–pack
```

## 导入虚拟机

点击 Tools，点击 Add。选择文件进行导入。

![image-20220516103707552](https://img.jiapeng.me/image-20220516103707552.png)

![image-20220516103806136](https://img.jiapeng.me/image-20220516103806136.png)

## 网络配置

File -> Host Network Manager 添加网卡，可以选择是否开启 DHCP 功能。

![image-20220516105047484](https://img.jiapeng.me/image-20220516105047484.png)

宿主机上可以看到 vbox 对应的网卡

![image-20220516105431196](https://img.jiapeng.me/image-20220516105431196.png)

开启 Adapter2 并启用网卡。

![image-20220516105234733](https://img.jiapeng.me/image-20220516105234733.png)

虚拟机上配置并启用对应的网卡

![image-20220516105607588](https://img.jiapeng.me/image-20220516105607588.png)

## 虚拟机与主机共享文件夹

VBox 软件中挂载相应的文件

![image-20220516105722248](https://img.jiapeng.me/image-20220516105722248.png)

Guest 下安装 VBox Guest Addition 包

```
sudo mkdir /media/cdrom
sudo mount /dev/cdrom /media/cdrom
cd /media/cdrom
sudo ./VBoxLinuxAdditions.run

```

```
## 将用户添加到 vboxsf 分组，进行 vboxsf 访问
sudo adduser ${username} vboxsf
```

![image-20220516110949715](https://img.jiapeng.me/image-20220516110949715.png)



## 参考资料

https://www.techrepublic.com/article/how-to-install-virtualbox-guest-additions-on-a-gui-less-ubuntu-server-host/

https://maheshhika.com/2012/09/28/virtual-box-verr_pdm_media_locked/

