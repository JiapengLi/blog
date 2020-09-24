# Hard Fault

今天在调试程序时运行过程中突然报了一个Hard Fault, 但是所使用IDE调试手段很欠缺, 不能回溯程序调用栈定位出问题的代码.

1. 首先想到对IDE进行升级, 升级后调试IDE, 发现新版IDE添加了HardFault支持, 获取到了一些线索.
   - "Bus fault is caused by precise data access violation."
   - IDE给了一个地址, 通过查看汇报代码搜索地址, 大致定位了出问题的代码
2.  然后也尝试使用https://github.com/armink/CmBacktrace
   - 这个工具确实很不错, 对堆栈分析的很到位.
   - 根据此工具的反馈, 定位的代码跟IDE出示的结果是一样的
3. 根据调试过程中的蛛丝马迹怀疑是访问数组元素造成的的, 但是始终无法定位问题.
4. 最后通过对目标代码(下图2号位)进行修改根据打印的结果发现, 程序所引用的i过大, 导致内存访问越界, 最终导致了"Bus fault is caused by precise data access violation."

![](https://img.risinghf.com/20200921-131536-849.png)

5. 下次再看到类似的现象第一反应应该就是数组下标越界问题

## CMBackTrace工具

```
Firmware name: ***, hardware version: 1.0, software version: 0.0.4
Fault on interrupt or bare metal(no OS) environment
===== Thread stack information =====
  addr: 200013b0    data: 0803f9c4
  addr: 200013b4    data: 00000000
  addr: 200013b8    data: 00000000
  addr: 200013bc    data: 20015ad0
  addr: 200013c0    data: 20015bfc
  addr: 200013c4    data: 20015ad0
  addr: 200013c8    data: 20015ad0
  addr: 200013cc    data: 20015bfc
  addr: 200013d0    data: 00000000
  addr: 200013d4    data: 20014e28
  addr: 200013d8    data: 00000000
  addr: 200013dc    data: 00000000
  addr: 200013e0    data: 00000000
  addr: 200013e4    data: 0804c1f7
  addr: 200013e8    data: 00000000
  addr: 200013ec    data: 080323ff
  addr: 200013f0    data: 08032474
  addr: 200013f4    data: 61000000
  addr: 200013f8    data: 0804c492
  addr: 200013fc    data: 61000000
  addr: 20001400    data: 00000000
  addr: 20001404    data: 00000000
  addr: 20001408    data: 00000000
  addr: 2000140c    data: 00000000
  addr: 20001410    data: 00000000
  addr: 20001414    data: 00000000
  addr: 20001418    data: 00000002
  addr: 2000141c    data: ffffffff
  addr: 20001420    data: 0000002a
  addr: 20001424    data: 00072921
  addr: 20001428    data: 200144f0
  addr: 2000142c    data: 0000a9e3
  addr: 20001430    data: 00000001
  addr: 20001434    data: 00000000
  addr: 20001438    data: 00000000
  addr: 2000143c    data: 00000000
  addr: 20001440    data: 00000000
  addr: 20001444    data: 0804c4cb
  addr: 20001448    data: 00002580
  addr: 2000144c    data: 01010008
  addr: 20001450    data: 00000000
  addr: 20001454    data: 00000000
  addr: 20001458    data: 00000000
  addr: 2000145c    data: 0804c55b
====================================
=================== Registers information ====================
  R0 : 40027c18  R1 : 20012df0  R2 : 00000000  R3 : 20001674
  R12: 00000000  LR : 0804b877  PC : 0804ba9c  PSR: 81000000
==============================================================
Bus fault is caused by precise data access violation
The bus fault occurred address is 40027e7c
Show more call stack info by run: addr2line -e lwct.out -a -f 0804ba9c 0804b873 0803f9c0 0804c1f3 080323fb 08032470 0804c48e 0804c4c7 0804c557 
```

```
$ addr2line -e a.out -a -f 0804ba9c 0804b873 0803f9c0 0804c1f3 0803bc49 0803bc2e 0804c4a4 0804c4c7 0804c557
0x0804ba9c
lwct_evt
src\app\nucleof746zg\lwct/lwct.c:2785
0x0804b873
lwct_evt
src\app\nucleof746zg\lwct/lwct.c:2705
0x0803f9c0
.text_181
src\drv\lorawan\lw-log.c:?
0x0804c1f3
lwsrv_evt
src\app\nucleof746zg\lwct/lwsrv.c:144
0x0803bc49
led_evt
src\drv/led.c:104
0x0803bc2e
led_evt
src\drv/led.c:101
0x0804c4a4
main
src\app\nucleof746zg\lwct/main.c:171
0x0804c4c7
main
src\app\nucleof746zg\lwct/main.c:179
0x0804c557
_call_main
??:?
```

