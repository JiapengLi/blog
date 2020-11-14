# C 语言 const 修饰指针

> 文不如图，图不如表。

杨同学说近来面试的一些候选人连 const 的用法也说不全，很沮丧。我觉得有必要整理下用法造福社会。;)

咱们就来聊一聊 const 修饰指针变量的用法，不讲基础，只讲理解和记忆。

## const 修饰指针的八种形式

C 语言中一个典型的指针变量声明语句如下图所示（`int * p;`）。

![image-20201024102837113](http://img.risinghf.com/20201024-102843-513.png)

根据上图所标示可知，`const` 有三个插入的位置。进一步推导，每个图中所示位置对应两种情况，插入 `const` 或者不插入 `const`，最终可以得到 8 种不同的表达方式（`2^3 = 2 * 2 * 2`）。

| 序号 |  D0  |  D1  |  D2  | 语法                           |
| :--: | :--: | :--: | :--: | ------------------------------ |
|  0   |  0   |  0   |  0   | `int * p0;`                    |
|  1   |  1   |  0   |  0   | `const int * p1;`              |
|  2   |  0   |  1   |  0   | `int const * p2;`              |
|  3   |  1   |  1   |  0   | `const int const * p3;`        |
|  4   |  0   |  0   |  1   | `int * const p4;`              |
|  5   |  1   |  0   |  1   | `const int * const p5;`        |
|  6   |  0   |  1   |  1   | `int const * const p6;`        |
|  7   |  1   |  1   |  1   | `const int const *  const p7;` |

注1：表中的 Dx 与图中的标号一一对应。

注2：部分声明语句需要在声明时赋初值，这里未进行标示

这八种表示方法有什么区别？p0 - p7 都适用于哪些场景？且看后文一一道来。

## 指针变量的读写权限控制

一个指针变量可以表示两层含义**指针本身**（`p`）和其所指向的**数据内容**（`*p`），我们用 `p` 来访问指针本身，而用 `*p` 访问指针所指向的内容。默认情况下，`p` 和 `*p` 均是**可读写**的。但是在引入 const 关键字修饰后，`p` 和 `*p` 就多了一个**只读**（`R`）权限控制（作者按：C 语言变量只支持**只读**和**可读写**两种权限，不存在**只写**的情况）。综合起来有如下四种情况：

|  *p  |  p   |    语法     |
| :--: | :--: | :---------: |
| R/W  | R/W  | `int * p0;` |
| R/W  |  R   |     ???     |
|  R   |  R   |     ???     |
|  R   | R/W  |     ???     |

对于最简单的情况 `p0`，我们知道 `p` 和 `*p` 都是 `R/W` 属性，可读可写，这个是最常用的，表示方法也是最简洁的（符合直觉）。但对于 p1 - p7 似乎就多有容易混淆之处。不多啰嗦，咱们先把结论放出来再说。如下表所示，不同声明语句的情况下， `p` 和 `*p` 的 `R/W` 属性不尽相同。

| 序号 | 语法                           |  *p  |  p   |
| :--: | ------------------------------ | :--: | :--: |
|  0   | `int * p0;`                    | R/W  | R/W  |
|  1   | `const int * p1;`              |  R   | R/W  |
|  2   | `int const * p2;`              |  R   | R/W  |
|  3   | `const int const * p3;`        |  R   | R/W  |
|  4   | `int * const p4;`              | R/W  |  R   |
|  5   | `const int * const p5;`        |  R   |  R   |
|  6   | `int const * const p6;`        |  R   |  R   |
|  7   | `const int const *  const p7;` |  R   |  R   |

看似很乱对吗？实则不然。当我们再把各个情况按照 `*p` 和 `p` 的访问权限进行划分时，规律就浮出了水面。如下图所示：

![image-20201024122855995](http://img.risinghf.com/20201024-122903-725.png)

解释说明：


1. 其中 `R R` 和 `R R/W` 两行中各自包含的三种表示方法其实是等价的，p3、p5、p7 完全相同，p2、p4、p6 完全相同。
2. 以星号为界，出现在星号前的 const 修饰指针指向的数据，出现在星号后的 const 修饰指针变量本身（离谁近就修饰谁）
3. `const int`、`int const`、`const int const` 三者等价，其中 `const int const` 这种用法有冗余，AC5 编译器会报一个警告（#83-D: type qualifier specified more than once），不同表示方法的等价性引起了一定程度上的表意混淆，需要注意区分
4. const 修饰指针本身时（`p` 指针的属性为 `R`）该指针必须在声明时进行初始化（编译时确定），为了行文方便，前文表格中未进行标示
5. 指针运算属于运行时赋值操作的一种（例如：p++），属于写操作，故此只有具备 R/W 属性的指针才可进行指针的运行时赋值（表中的 p0 - p3）

结合上述解释进一步简化，等价的声明只取之中可得到下表。删繁就简后和谐了，4 种权限组合方式分别对应 4 种常用的表示方法。

|  *p  |  p   | 语法                    |
| :--: | :--: | ----------------------- |
| R/W  | R/W  | `int * p0;`             |
| R/W  |  R   | `int * const p1;`       |
|  R   |  R   | `const int * const p5;` |
|  R   | R/W  | `const int * p4;`       |

## const 的作用知多少？

前文的读写权限控制其实只是 const 的表层含义，在实战中 const 的作用主要有以下两种：

1. 利用编译器进行代码检查，在编译阶段进行数据访问的排错（减少 bug）
2. 根据修饰的内容不同控制编译器在编译过程中变量存储区域的分配

其中利用编译器对 const 的功能支持限制读写访问很好理解，一旦不匹配程序无法通过编译，这里不再展开。下面通过一个实例来看一下存储区分配的实例。

对比如下四种声明语句的区别：

```c
char *  str0 __attribute__((used)) = "aaaa";
const char * str1 __attribute__((used)) = "bbbb";
char * const str2 __attribute__((used)) = "cccc";
const char * const str3 __attribute__((used)) = "dddd";
```

调试结果如下图所示，利用 str0 - str3 可以分别访问其指向的字符串。查看 &str0 - &str3 可以观察到指针变量存储的位置， str0、str1 存储在 RAM 中，str2、str3 存储在 ROM 中。

![rect6096](http://img.risinghf.com/20201024-151703-667.png)

移除声明语句编译，对比资源占用结果，进行对比验证，结果符合图示标示。

```
Program Size: Code=856 RO-data=584 RW-data=20 ZI-data=16388  （全）

Program Size: Code=856 RO-data=576 RW-data=16 ZI-data=16384  （移除 str0，RO 少 8 字节，RW 少 4 字节）
Program Size: Code=856 RO-data=576 RW-data=16 ZI-data=16384  （移除 str1，RO 少 8 字节，RW 少 4 字节）
Program Size: Code=856 RO-data=572 RW-data=20 ZI-data=16388  （移除 str2，RO 少 12 字节）
Program Size: Code=856 RO-data=572 RW-data=20 ZI-data=16388  （移除 str3，RO 少 12 字节）
```

注：ZI data 变化是由于编译器按 8 字节对齐数据自动进行 padding 造成的，str0 和 str1 的声明影响了 ZI-Data 的起始地址，这里不用理会（Padding 的字节数记录到了 ZI data 中）。

```
    Exec Addr    Load Addr    Size         Type   Attr      Idx    E Section Name        Object

    0x20000000   0x0000059c   0x00000008   Data   RW            8    .data               main.o
    0x20000008   0x000005a4   0x00000004   Data   RW          100    .data               a.o
    0x2000000c   0x000005a8   0x00000008   Data   RW          245    .data               b.o
    0x20000014   0x000005b0   0x00000004   PAD
    0x20000018        -       0x00004000   Zero   RW          149    STACK               arm_startup.o
```

分析：

1. str0 & str1 & str2 & str3 在资源耗费上相同（都是 12 个字节），不同的是 str0 与 str1 的数据会在运行时复制到 RAM 中（**RW-DATA (ROM) -> RW-DARTA (RAM)**)
2. const 修饰指针类型时 （`*p` 为只读），主要作用是防止指针所指向区域的数据由于编程人员疏忽而误篡改，又分为两种情况需要注意：
   - `*p` 位于 RAM 区，数据本身支持随机写入，防止发生逻辑错误使得程序运行呈现玄学状态
   - `*p` 位于 ROM 区，数据本身不支持随机写入，防止发生逻辑错误而出现总线访问错误（如 HardFault）
3. 实例中的编译结果字符串存储是按照 4 字节对齐的，看似用了 5 个字节 （字符串结尾标志 `'\0'` 占一个字节），实则是 8 个字节
4. RAM 区域的 str0 和 str1 的初始化数据，实际也是存储在 ROM 中的，编译器会负责这部分数据的拷贝工作，str0 和 str1 的声明比 str2 / str3 声明语句多耗费 4 字节的 RAM。
   - str0 和 str1 的初始化值存储在 RW-DATA 区域（注意：RW-DATA 区域实际上是在 ROM 中的一个代理副本，运行时在 RAM 中生成主体） 
   - str2 和 str3 的初始化值存储在 RO-DATA 区域

