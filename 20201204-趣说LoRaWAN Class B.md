# 趣说LoRaWAN Class B

> 初稿完成于2018年，2020年发布，有修订。
>
> 本文假定读者有LoRaWAN Class A的知识背景。

由于工作的关系，早在LoRaWAN V1.0.2B 与V1.1协议发布之前就已经开始了对于LoRaWAN Class B的探索。我也亲历了LoRaWAN Class B从初稿，修改，再修改，定稿的整个过程，一路风雨。让我们从LoRaWAN Class B的前世今生讲起。

## 名词解释

节点: LoRaWAN通讯系统中的完成物联网传感/控制或其他特定功能的设备

网关: 又称集中器，用于采集节点端的数据，完成

服务器: 完成对网关节点的管理工作，并对节点采集的数据进行存储并分析处理的功能

上行数据: 由节点发送的数据

下行数据: 用网关发送的给节点的数据

NTP: 一种网络校时协议

## LoRaWAN Class B是什么?

 首先来讲讲什么是LoRaWAN Class B。来看一张图：

![](https://img.juzuq.com/20201204-160848-398.png)

有点儿懵圈，对吗？别急，衣服我们一层一层脱。

先唠叨几句LoRaWAN，啥是LoRaWAN？LoRa联盟是这样解释的：

> The LoRaWAN specification is a Low Power，Wide Area (LPWA) networking protocol designed to wirelessly connect battery operated ‘things’ to the internet in regional，national or global networks，and targets key Internet of Things (IoT) requirements such as bi-directional communication，end-to-end security，mobility and localization services。

下面开始说人话。LoRaWAN本质上是一种双向无线通信协议(此处可以联想一下WIFI)，适应的使用场景是**低速率低功耗远距离**。那么有人会问了，**怎么才算低功耗？**设备不吃不喝不停地运行，多则十年，少则三年五年，再少你都好意思跟人打招呼。**那多远才算远距离呢？**典型通讯距离3-5公里以内，不打折。

再来说说LoRaWAN的设备类定义，截止目前LoRaWAN已经定义了3种设备通信协议用以涵盖大部分应用场景，分别为A / B / C。

- A类协议节点为主动方，是每次通信的发起者，无需通信时可以视情况最大限度的处于睡眠模式。
- C类协议节点与服务器(或网关)双方均为主动方，每次通信可由任意一方发起，由此该类节点需长时间的处于接收状态，时刻等候下行数据。
- B类协议与C类节点相似，节点与服务器(或网关)双方均为主动方，每次通信可由任意一方在**事先约定好的时间点**发起，由此该类设备的节点一方仅需在特定的时段内进行接收即可(由PingSlot或BeaconReserve决定)。

这样我们不难发现，LoRaWAN设备A -> B -> C，能耗越来越高，实时性越来越好。自古以来，**功耗**与**实时性**就是鱼与熊掌不能兼得的仇家。

言归正传，我们详细讲一讲LoRaWAN Class B协议。前文描述中提到了B类通信双方需要在`事先约定好的时间`发起。其实这事儿就像新闻联播，几十年如一日雷打不动的在北京时间7:00整播出，不能早一秒也不能晚一秒，大部分时间持续30分钟整，不多一秒亦不少一秒。基于以上种种新闻联播的特性，LoRaWAN Class B内定义的Beacon(信标)与其有着一样的属性，我们横向对比一下.

| 项目 | 新闻联播 |   Beacon   |
| :--: | :------: | :--: |
| 周期 |    24hr      |   128秒   |
| 时间 | 每天19:00 | 128整数倍的GPS时间 |
| 时长 | >=30分钟 | <=2.12s |

我们继续分析新闻联播的特性，还记得那句**"现在是北京时刻7点整"**吗? 在计算机智能手机时代以前，NTP还没有诞生或者没有这么广泛地被使用，那时候人们是不那么容易获取到准确的时间的，在这种情况下这句准时准点的播报起到了为全国人民统一时间的作用。

设想一个场景，我完全不记得自己的时间了。这时我需要知道时间，完成时间同步，重新融入社会，我应该怎么办? 我的办法就是：24小时锁定频道至CCTV1即可！19:00新闻联播开播你就得到了准确的时间。LoRaWAN Class B的设备也是这样，需要对时？很简单，锁定Beacon的信道128s以上即可，每128秒至少有一次对时的机会。

所以，我们搞清楚了LoRaWAN Class B的**Beacon，是一种按固定周期在特定时间由网关发射的射频信号(LoRa数据包)，节点设备可利用Beacon同步时间。**

前面提到说需要盯住CCTV1套24小时才能同步时间，这样的方法是很耗神的。其实我们有更简便的方法，比如跟其他有准确时间的人同步，同步之后每天19:00前再去跟新闻联播对时，**防止长时间不对时出现时间误差**。同样地，LoRaWAN Class B中也提供了与之对应的方法。那就是DevTimeReq / DevTimeAns，这一对Mac指令提供给设备随时随地跟服务器(或网关)对时的手段，在设备搜索Beacon前，可以先尝试通过DevTimeReq/Ans 对时，然后再有的放矢地去搜索Beacon，节省不必要的功耗浪费。

讲到此处我们再回头看文首的LoRaWAN Class B通信时序图。

![](https://img.juzuq.com/20201204-160848-398.png)

- `Beacon`: 信标，由网关发送，节点接收，节点利用Beacon同步与网关的时间
- `BEACON_PERIOD`: 128s。连续两个Beacon相隔的时间，所谓的Beacon周期
- `BEACON_RESERVED`: 2.12s。为Beacon数据包预留时间窗口
- `BEACON_GUARD`: 3s。Beacon窗口的保护时间，此时间段内，节点不得发起Class A通信
- `BEACON_WINDOW`: 122.88s。`BEACON_PERIOD`除去`BEACON_RESERVED`与`BEACON_GUARD`所剩余的时间，用于Class B下行通信，Ping 与 PingSlot可以利用的时间窗口
- `pingOffset`: `pingSlot`在每个Beacon周期内的伪随机延时，使得不同的设备在相同的周期内的pingSlot时机偏移抗干扰
- `pingPeriod`: 同Beacon周期内相邻`pingSlot`的时间间隔
- `slotLen`: `BEACON_WINDOW`的最小时间单位，固定30ms，`pingOffset`与`pingPeriod`均以此为单位.

总结，LoRaWAN Class B提供了一种使得节点 / 网关 / 服务器进行时钟同步的机制，并且利用网络内所有组成部分时钟同步特定，限制各组成部分在特定的时间进行通信，从而达到同时兼顾低功耗与上下行数据传输实时性的目的。

## Class B 发展史

在LoRaWAN V1.0的早期版本中，Class B的定义存在严重缺陷，重要的有两条：

1. 使用了UTC作为时间戳，导致Beacon会受闰秒影响（现已改为GPS时间戳）
2. BeaconTimeReq/Ans，采用下一条Beacon相对时间，无法对跳频的Beacon频率进行预测

最新版软件已经对这些内容进行了修正。