---
layout: post
title: UE Object Pool
date: 2024-06-29
categories: GameDev
---

对象池是一种常用的解决方案，它通过缓存对象来加速游戏中的对象创建和销毁，从而提高游戏性能。在Unreal引擎中，对象池可以用来管理大量的对象，以便在需要时快速地创建和销毁对象。

本文受到了 [引擎底层嵌入通用对象池系统](https://zhuanlan.zhihu.com/p/630288735) 的极大启发

你完全可以把本文当作此文章的解释与改良，本文的方法更多的是对对象池实现方法的总结，以及解释为什么这么做

## 对象池的设计理念

在UE中要实现单机环境下的对象池并不复杂，只需要缓存物体，并在需要的时候从缓存中取出来即可，但是在多人联网环境下，需要实现对象复用后的网络同步，事情变得相对复杂。

在参考不同的对象池实现后，得出的一个结论是：对象池的设计应该遵循最核心的理念是"**as if**"原则，即对象池物体的使用和普通物体并无而二致，称之为**一致性**。对象池的设计需要解决的所有问题就是如何保证复用的物体和新建的物体是一致的。

## 对象池在什么层级中实现

这里其实包含两个问题
1. 池化的对象是什么
2. 对象池嵌入的位置在哪里合适

首先，在UE中，能生成的并进行网络同步的物体只有`Actor`是最为合适进行池化的，池化的对象应该是同一类型的`Actor`，由此对象池的目标可以确定为保持对象池中`Actor`与正常新建的`Actor`的一致性

再者，所有的游戏逻辑，包括网络同步的逻辑都通过`UWorld`来进行`Actor`创建与销毁的管理，可以说`UWorld`是`Actor`的原点和终点，通过在`UWorld`嵌入对象池的逻辑是管理对象池`Actor`生命周期的最佳方式

![image-20250101205704912](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101205704912.png)

与 [引擎底层嵌入通用对象池系统](https://zhuanlan.zhihu.com/p/630288735) 中的方法类似，这里也采用一个接口`IReusableActor`来对使用对象池的对象进行标识操作

![image-20250101214103313](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101214103313.png)

## 一致性原则的实现

一致性需要保证的范围十分宽泛，囊括Gameplay中的各类问题以及网络同步的问题。但总体来说，可以划分为以下两大类

![image-20250101215038425](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101215038425.png)

1. 内部一致性：包括Actor对象自身的状态以及其子对象的状态 
2. 外部一致性： 其它对象对此Actor的引用

对一致性的保障，集中体现在Actor的生命周期上，以下是Actor的默认生命周期中的关键点

![image-20250101215806580](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101215806580.png)

加入对象池后，为构造出与Actor等价的生命周期，设计了以下的方案

![image-20250101220026674](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101220026674.png)

需要注意的是，对象池的复用回收流程与 Actor 的创建销毁流程并非完全一一对应，有几个差异点是值得注意
1. 添加到 Level 和从 Level 中移除的步骤被省略：主要是为了方便进行对象池 Actor 的观察，并且 Level 对 Actor 的持有并不影响 Actor 的正常使用
2. Component 的注册和注销缺失：静态组件，即随Actor创建而一同创建的组件被视为池化对象的一部分，因此不需要进行注册和注销的操作
3. Actor 及 Component 的初始化和销毁时的操作被`OnSpawn`和`OnRecycle`替换
4. GC操作

## 内部一致性的保证策略

![image-20250101224946860](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101224946860.png)

内部一致性在于保持Actor内部包括其子物体的的一致性
1. 对Actor要进行状态恢复，如Actor的位置、旋转、缩放、以及各种为Gameplay设计的变量
2. 对于静态子对象，同理进行递归的恢复
3. 对于动态子对象，则需要在回收时进行销毁和复用时重新创建

![image-20250101225401686](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101225401686.png)

**内部一致性的关键是对`OnSpawn`和`OnRecycle`的编写**，也就是需要开发者要手动维护物体在回收和复用时的状态变化。
大部分情况下，这是导致不一致性的根源。

内部一致性的原则是：
1. 执行`OnSpawn`后与执行`BeginPlay`对象**状态一致**
2. 执行`OnRecycle`后与对象销毁的**效果一致**

大致需要实现以下状态的管理
- 值类型成员变量：在回收或复用时，将其成员变量值恢复到CDO状态
- 动态子对象管理：回收销毁动态子对象，复用重新创建
- 渲染/物理/其他组件状态管理：Actor下的组件同样遵循以上两个原则回收时，例如`Scene Component`需要在回收时关闭物理模拟、隐藏Actor，复用时反之

### 专用的类默认对象（CDO）

这也导致了`OnRecycle`后的对象状态其实没有一个标准，极有可能导致对象池物体复用后状态的不一致。

为了能让Actor的回收状态有一个标准的对照，引入一个专用的类默认对象`Pool CDO`专门作为对象回收后的标准状态参照

![image-20250102164945541](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250102164945541.png)

## 外部一致性的保证策略

![image-20250101225056641](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101225056641.png)

### Actor的外部一致性

导致外部一致性问题的原因是：**UE的GC有引用清除的机制**

如果你对GC不是很了解，有两篇对GC机制分析文章可以阅读参考
https://zhuanlan.zhihu.com/p/67055774
https://www.cnblogs.com/kekec/p/13045042.html

具体来说，在对象 `Mark Pending Kill` 后进入GC流程，GC将进行两个重要的工作
- 引用分析中：将 “Pending Kill” 的对象进行**解引用**
- 增量清除中：将对象回收到`UObjectArray`中，**重置对象的序列号**，**通知`Delete Listeners`**

下图是一个简化的GC流程，高亮的部分是相关的步骤

![image-20250101232250199](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101232250199.png)


对外部一致性的保障有两种方法，一种是需要侵入GC流程，給对象池物体开旁路，进行“假销毁”；另一种是将以上两个关键步骤进行抽离，形成一个轻量的“GC”

这里采用的方法是后者，因为自定义的引用清除流程，可以方便设置引用持有的白名单，诸如对象池管理器能在回收期间正常持有引用，组件和Actor间的初始引用能保持，不会破坏内部引用关系。

![image-20250101234709773](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101234709773.png)

显然的，增加一个引用搜索步骤会极大增加性能开销，并且需要将GC Lock的API进行暴露。

但是这个开销是可以避免的，引用搜索是为解引用操作服务，而悬垂引用本身作为一种未定义行为是应当被避免的，所以对对象池Actor的解引用可以作为**开发期间的检察功能**，用于检查对回收对象的“悬垂引用”，将这些引用替换为弱引用。

对于弱引用的解除，只涉及序列号的重置，可以在对象回收时一同完成。

#### 引用收集

![image-20250102171207469](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250102171207469.png)

TFastReferenceCollector需要配置三个对象

1. 引用处理器：处理收集的引用

2. 引用收集器：一般转发到引用处理器中

3. 对象数组：储存需要进行引用分析的对象指针

引用收集的流程：

遍历ArrayPool中的对象与其Stream Token，收集的相关信息交由引用处理器处理

#### 弱引用解除

引用通过对象索引和序列号查找对象指针

- 索引：对象在 ObjectArray 中位置

- 序列号：索引多次复用，通过序列号进行区分

序列号不相同，弱引用即返回空指针，重置序列号为0能让所有弱引用失效，复用时需要重新分配

#### 其它

一些特殊的全局容器如 FSparseDelegateStorage 需要监听UObject的销毁以保证正常工作，在回收对象时同样需要通知监听对象

### 静态子对象的外部一致性

![image-20250101235713738](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250101235713738.png)

静态子对象如静态组件，并不能像Actor一样简单粗暴得进行引用清除，因为在内部一致性中所保证的是：`OnRecycle`后与对象销毁的**效果一致**，这是出于性能的考量。这意味着引擎在对象回收后对静态子对象的引用是合理的，但一旦进行访问操作，则会导致未知后果。

所以如果出现回收期间的访问操作的引用，是需要进行特殊处理的。

可以通过两种方法来检验这种情况，这两种功能也应该是**开发期的检测功能**
1. 对弱引用进行改造，嵌入对回收物体的访问断言
2. 回收后进行子对象的引用查询与排查

经过上述手段的排查，如果所有组件功能都处于非活跃状态，在回收期间，唯一的访问来自于网络同步中的`GUID Cache`查询的弱引用访问

这一处理涉及UE的网络同步，如果对此不了解可以参考

https://zhuanlan.zhihu.com/p/34723199

https://zhuanlan.zhihu.com/p/55596030

这是一张简化的Actor网络同步原理图

![image-20250102003800748](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250102003800748.png)

`Net GUID` 是对象在网络游戏中的唯一标识，由服务端分配，`GUID Cache`缓存了GUID和对象的映射关系，当对象被销毁后，`GUID Cache`中的映射关系因为弱引用的失效而失效。但是**回收后的静态子对象的弱引用仍然有效**。

子对象同步的问题在于
1. 客户端侧
   1. 组件的网络同步先查询`GUID Cache`
      - 问题：因为回收后的组件弱引用仍然有效，所以会导致组件的错误映射
      - 解决：在回收后删除`GUID Cache`中的映射关系
   2. 没有找到的话，再根据**组件路径名**查找组件，并缓存静态组件的GUID映射，并且组件路径名只在首次同步时由服务器发送
      - 问题：因相关性而关闭通道后对象会被回收，后继可能会被复用，但组件路径名只在**首次向某连接同步时由服务器发送**
      - 解决：因相关性而关闭的对象池物体网络通道中重置对连接的ACK值，保证其再次连接后也能发送组件路径名
2. 服务端侧
   1. 组件复用后GUID不变
      - 问题：如果服务端已经销毁并复用物体，但客户端因为某种原因没有销毁，可能导致映射错误
      - 解决：在回收后删除`GUID Cache`中的映射关系



Actor的网络关闭的简化流程如下，黄色高亮的环节为插入的修复

![image-20250102163708159](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image-20250102163708159.png)


## 参考
https://zhuanlan.zhihu.com/p/630288735
https://zhuanlan.zhihu.com/p/67055774
https://www.cnblogs.com/kekec/p/13045042.html
https://zhuanlan.zhihu.com/p/34723199
https://zhuanlan.zhihu.com/p/55596030