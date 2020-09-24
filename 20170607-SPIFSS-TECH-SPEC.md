# SPIFSS设计思想
SPIFFS灵感来自于YAFFS. 然而, YAFFS是为NAND Flash和一些具有充足RAM的稍大型的设备设计的. 尽管如此, SPIFFS还是借鉴了许多YAFFS的好的想法. Kudos!

编写SPIFFS最复杂的难题是无法假设目标设备具有堆(Heap). SPIFFS必须只能使用用户传入的RAM缓冲. 这为SPIFFS带来了许多额外的开发工作量.

## SPI NOR Flash 设备

下面的内容对SPI Flash的工作原理做了简要介绍. 帮助用户理解SPIFFS的设计理念及设计选择.

物理层面上SPI Flash可以换分为许多块(block). 对于其中一些Flash, 块仍然可以被细分为多个扇区(sector). 注意, 元器件手册(datasheet)常常混用块和扇区二词.

SPI Flash常见容量有512KB至8MB, (译注: 现今16MB/32MB也很常见, 64MB倒是比较少见) 大部分具有64KB的块(block). 扇区可以是例如4kB(如支持). 许多SPI Flash具有统一的块大小(block size), 也有一些不统一的(同一SPI Flash多种block size, 例如, 前16个块4KB大小, 后面的块64KB大小).

整个存取区为线性结构, 并且何以进行随机读写. 擦除只能按块或者扇区为最小单位.

SPI Flash具有循环擦写的寿命限制, 一般可以擦写10万至100万次, 超出后失效的Flash块将无法正确写入或读出有效数据.

出厂的空SPI Flash的存储空间的所有位将被置1. 批量擦除(Mass erase)操作也可以将Flash清空. 块擦除或者扇区擦除操作也可以将所有的块或者扇区的内容置全1. 对NOR Flash进行写操作将数据由1置0. 对区地址写FF操作数据空操作.

这样我们可以得到结论, 对一个包含0b00001111的地址写入0b10101010将得到0b00001010.

这条"write by nand"规则广泛应用于spiffs中.

SPI Flash的一个普遍特性是读快写慢.

最后一条, 和NAND Flash不同, NOR Flash看起来不需要写错误修正. 从我收集的信息来看, NOR Flash写操作一直成功.

## Spiffs的逻辑结构

正式开始前先看几个术语:

+ 物理块/扇区: 表示元器件手册里定义的物理存储单元大小
+ 逻辑块/页: 表示由开发人员自定义的存储大小


## 块(Blocks)与页(Pages)

用户可以根据需求将SPI Flash的全部或者部分存储空间分给Spiffs. 这部分区域会被分割为逻辑页. 逻辑块的边界必须和物理块的边界一样.

```
例如: 非统一块大小的Flash映射为spiffs的128KB逻辑块

PHYSICAL FLASH BLOCKS               SPIFFS LOGICAL BLOCKS: 128kB

+-----------------------+   - - -   +-----------------------+
| Block 1 : 16kB        |           | Block 1 : 128kB       |
+-----------------------+           |                       |
| Block 2 : 16kB        |           |                       |
+-----------------------+           |                       |
| Block 3 : 16kB        |           |                       |
+-----------------------+           |                       |
| Block 4 : 16kB        |           |                       |
+-----------------------+           |                       |
| Block 5 : 64kB        |           |                       |
+-----------------------+   - - -   +-----------------------+
| Block 6 : 64kB        |           | Block 2 : 128kB       |
+-----------------------+           |                       |
| Block 7 : 64kB        |           |                       |
+-----------------------+   - - -   +-----------------------+
| Block 8 : 64kB        |           | Block 3 : 128kB       |
+-----------------------+           |                       |
| Block 9 : 64kB        |           |                       |
+-----------------------+   - - -   +-----------------------+
| ...                   |           | ...                   |
```

逻辑块将被定义为多个逻辑页. 逻辑页定义了SPIFFS存储数据的最小单元. 因此, 假设有一个文件只包含有一个字节, 这个文件会占用一页用来存储索引, 同时占用另一页用来存储数据, 这样这个文件就需要占用两个逻辑页用来存储数据. 这样看来页尺寸设置的越小越好.

SPIFFS的每一页都需要占用一个5~9个字节的元数据(metadata). 这就是说小的页会使得元数据占比很高, 造成数据浪费. 一个逻辑页为64字节大小的SPIFFS将浪费8-14%, 256字节浪费2-4%. 这样看选择大的页又比较好.

并且, SPIFFS需要一个页大小两倍的一个RAM缓冲区. 这个RAM缓冲区将用来加载和维护SPIFFS的逻辑页, 同时这个缓冲区也将被用于找寻空闲文件ID的算法, 扫描文件系统等等. 使用一个过小的缓冲区会使得SPIFFS有更少的可用缓冲, 同时使得SPIFFS产生更多的读操作, 导致文件系统过慢.

文件系统页大小选用原则和影响因素:
 - 逻辑块的大小
 - 大部分文件的尺寸是多少
 - 可以选配多少RAM给SPIFFS
 - 文件系统需要存入多少数据(VS metadata)?
 - SPIFFS运行速度要多少
 - 其他所有需要注意的事情

所以, 选取最优页尺寸(Optimal Page Size)看似变得非常棘手. 实际也不用烦恼, 世界上本无最优页尺寸, 最优页尺寸取决于设备实际运行环境. 简单的折中考虑可以用如下公式.

```
~~~   Logical Page Size = Logical Block Size / 256   ~~~
```

这样就有了一个好的起点. 最终的页尺寸可以结合实际测试的结果选定.

## Objects, indices and look-ups

File或者Object(SPIFFS中的命名)由一个Object ID表示. 这个设计理念也源自YAFFS. Object ID是每页页首标识的一部分. 因此, 每个页面都准确知道其属于哪一个Object(空白页除外).

每个Object由两类页构成: 索引页(index)和数据页(data). 数据页包含用户写入的数据, 索引页包含Object的构造信息(metadata), 更通俗一点的表述是, 索引页将指出哪些页面是属于本Object的.

页首标识也包含一个名为span index的内容, span index是Object所包含的页索引值. 例如, 一个文件包含三个页面, 第一个页面的索引值为0, 第二个页面的索引值为1, 第三个页面的索引值为2, 以此类推.
最后, 每个页首标识中会包含一个标志, 用以表征该页面状态, 使用中, 已删除, 已写满, 是否包含索引或数据等等.

Object目录中同样包含span index, 具有0索引值的Object索引将作为Object的索引头. 这一页不仅包含数据页的索引列表, 同样包含Object的其他信息, 诸如Object名称, 大小, 标志等信息.

```
例如: SPIFFS的某一个文件占用3个页, 名字为"spandex-joke.txt", ID 12, 则其结构类似下面的描述.
PAGE 0  <things to be unveiled soon>

PAGE 1  page header:   [obj_id:12  span_ix:0  flags:USED|DATA]
        <first data page of joke>

PAGE 2  page header:   [obj_id:12  span_ix:1  flags:USED|DATA]
        <second data page of joke>

PAGE 3  page header:   [obj_id:545 span_ix:13 flags:USED|DATA]
        <some data belonging to object 545, probably not very amusing>

PAGE 4  page header:   [obj_id:12  span_ix:2  flags:USED|DATA]
        <third data page of joke>

PAGE 5  page header:   [obj_id:12  span_ix:0  flags:USED|INDEX]
        obj ix header: [name:spandex-joke.txt  size:600 bytes  flags:FILE]
        obj ix:        [1 2 4]
```
仔细查看上述例子中的PAGE 5, 这个页为Object的索引字头页, Object索引数组为按顺序排列的数据页(data). Object索引数组与数据页的索引相关(译注: 数组下标与数据页的索引值相等).
```
                            entry ix:  0 1 2
                              obj ix: [1 2 4]
                                       | | |
    PAGE 1, DATA, SPAN_IX 0    --------/ | |
      PAGE 2, DATA, SPAN_IX 1    --------/ |
        PAGE 4, DATA, SPAN_IX 2    --------/
```
Page 0 的内容: Spiffs设计目的是为低RAM系统服务, 所以我们不能维护一个动态列表用于存储所有的Object索引值, 来加速文件的访问. SPIFFS工作的系统甚至可能是没有堆的(Heap). 但是与此同时, 我们也不希望去扫描所有页去获取Object索引头.

这样, 每一个block的第一个页被设计为了Object查询表. 这些页与普通页不同, 它们没有头结构(header). 取而代之, 它们包含了一个数组用以指出当前block剩余页的Object ID.
通过使用look-up表, 每次可以通过扫描block的第一页, 来获取包含Object index的页面.

Object lookup表是一个冗余的metadata数据结构. 这里假设Object lookup表的读取开销更少, 从每一个block读取一整页, 而不是从每一页读取一小部分数据. 每一个读操作正常情况下都需要包括额外的数据用来表征SPI操作的类型(读/写/擦除)和具体操作的地址. 根据具体实现, 读操作中的其他额外开销也可能需要考虑, 例如互斥锁等.

```
The veiled example unveiled would look like this, with some extra pages:

PAGE 0  [  12   12  545   12   12   34   34    4    0    0    0    0 ...]
PAGE 1  page header:   [obj_id:12  span_ix:0  flags:USED|DATA] ...
PAGE 2  page header:   [obj_id:12  span_ix:1  flags:USED|DATA] ...
PAGE 3  page header:   [obj_id:545 span_ix:13 flags:USED|DATA] ...
PAGE 4  page header:   [obj_id:12  span_ix:2  flags:USED|DATA] ...
PAGE 5  page header:   [obj_id:12  span_ix:0  flags:USED|INDEX] ...
PAGE 6  page header:   [obj_id:34  span_ix:0  flags:USED|DATA] ...
PAGE 7  page header:   [obj_id:34  span_ix:1  flags:USED|DATA] ...
PAGE 8  page header:   [obj_id:4   span_ix:1  flags:USED|INDEX] ...
PAGE 9  page header:   [obj_id:23  span_ix:0  flags:DELETED|INDEX] ...
PAGE 10 page header:   [obj_id:23  span_ix:0  flags:DELETED|DATA] ...
PAGE 11 page header:   [obj_id:23  span_ix:1  flags:DELETED|DATA] ...
PAGE 12 page header:   [obj_id:23  span_ix:2  flags:DELETED|DATA] ...
...
```
也许你有疑问, 为何上述9到12页被标记为0, 但是这些页又属于ID 23? 这是因为这些页已经被删除了, 所以删除操作同时在本页面与block第0页标记了出来. 这个例子同时也说明了SPIFFS按NAND Flash的方式来写NOR Flash.

事实上有look up页中有两个Object ID号是具有特殊含义的:
obj id 0 (all bits zeroes) - 表示一个已经被删除的页
obj id 0xff.. (all bits ones) - 表示一个未被使用的页

实际上, object id还有另外一个特性: 如果最高位为1表示一个页为object 索引页, 如果最高位为0表示一个页为数据页. 所以上述PAGE 0的完全正确表示如下(*表示最高位为1):

```
PAGE 0  [  12   12  545   12  *12   34   34   *4    0    0    0    0 ...]
```
这个设计也是一个加速Object搜索的办法. 通过查询lookup表中的ID号, 可以直接判断出一个页面是否为索引页还是数据页.



## 术语定义

**块(block)**: SPI Flash最小擦除单位
**页**: SPIFFS文件系统的最小存储单元
**索引页**: SPIFFS中用于存储Object头结构的页
**数据页**: SPIFFS中用于存储数据的页
**Object**: SPIFFS文件系统的文件定义, 等同于其他文件系统的文件(File)
**扇区(Sector)**: 某些SPI Flash数据块物理分区的细分单元
**堆(Heap)**: 一个数据区, 典型的用法是通过malloc和free进行申请或释放
