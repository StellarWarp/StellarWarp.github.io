# Hybrid ECS Overview

有段时间使用Unity的ECS开发Demo感觉性能还行，但是Unity的ECS远远谈不上好用

后来查找了一些资料和ECS库后，感觉自己似乎也可以尝试搓一个更好用的ECS库


## ECS (Entity Component System)

对于ECS的，已经有相当多的资料和项目可参考

可参见下面的链接

https://docs.unity3d.com/Packages/com.unity.entities@0.50/manual/ecs_core.html

https://www.youtube.com/watch?v=W3aieHjyNvw&ab_channel=GDC

https://www.cnblogs.com/KillerAery/p/11746639.html

https://neil3d.github.io/3dengine/why-ecs.html

https://skypjack.github.io/2021-08-29-ecs-baf-part-12/

https://www.cnblogs.com/hggzhang/p/17161722.html

https://zhuanlan.zhihu.com/p/141255752



FLECS 的作者对当前的 ECS 发展有很全面的概述

https://github.com/SanderMertens/ecs-faq
https://www.flecs.dev/ecs-faq/


## ECS 要解决什么问题

### DOP(Data Oriented Programming)

ECS 除了逻辑上的解耦之外，一大优势是能写出性能更好的代码。

这个优势来源于两方面

1. 数据结构更加缓存友好
2. System的组织便于并行化

#### 数据结构（Component）

todo



#### 数据操作（System）

todo


## Component存储

当前ECS的存储实现方式主要分为两大流派

## Archetype(异构数组)

具有相同组件集的实体被分组到同一个数组中，这个数组称为一个“Archetype Array”

诸如 Unity、Unreal、flecs 等ECS的存储方案都是采用Archetype的方式

使用Archetype的一大好处在于对于使用了相同Component的实体，他们的数据能被按顺序紧密排列在一起，从而能在遍历时更加缓存友好

但是使用Archetype会带来一些问题

1. 当实体的组件发生改变时，需要将其所有的数据转移到新的Archetype中，带来高拷贝的开销
2. 只有当实体的组件完全相同才会被放入同一个Archetype中
   1. 当Archetype中的实体数量较少时会造成较多的内存浪费
   2. 实体的Component组合具有多样性时，会导致存储碎片化，最糟糕的情况是每个实体都在不同的Archetype中，不仅不能提高缓存命中率，加上间接组件寻址的开销其性能变得相当糟糕
3. 组件的随机访问寻址开销更高

## SparseSet(稀疏集)

与其称之为SparseSet，其实叫组件表Component Tables，可能更加合适

在这种结构中，每个组件类型都有自己的表，实体通过索引映射到各个组件表中的数据。

所谓SparseSet是针对Entity映射以及遍历进行优化的映射表容器，功能与哈希表相同。

entt 是使用这种结构的代表

这种结构可以避免使用Archetype中的问题，能做到灵活地添加和删除组件。以及更好的随机访问访问性能

此外能带来一个独有的有优点：可以对某个组件进行排序

使用这种数据结构的trade-off是
1. 对于Component的组合查询，只能对其中一个Component进行有序访问，其它Component需要进行随机访问，但这也属于是Archetype的优势应用场景
2. Query更加复杂：使用Archetype时，Query只要知道有哪些Archetype是查询目标即可；但是对于SparseSet，Query需要通过与其有关的组件表追踪实体的组件状态，考虑是否要将实体加入到访问列表中。相当于对于SparseSet中的Query而言，每个一个实体都是一个Archetype


## Hydrid Method

其实Archetype方法与SparseSet方法都有其最适用的场景，属于是互补的关系

如果能将这两种方法结合起来，就能在更多的场景下得到更好的性能表现

显然的Archetype适用于有大量相同的实体的场景，而SparseSet则能更好应对碎片化的场景



通常对于一个实体来说，其上会挂载各个模块的组件

例如，一个entity上可能有关于渲染、物理、AI、以及其它Gameplay逻辑的模块，各个模块中都有不同的组件组合

如果有$M$个模块，每个模块中有$N_i$个组件组合，最坏的情况是在全局中出现$\prod_{i=1}^{M}N_i$个组合，这样就会出现碎片化问题

### Component Group

这是混合方法的核心

将Component按照功能划分进入不同的Group中，在Group中才会形成Archetype，这样在全局中的组件组合数可以被极大降低，变成了$\sum_{i=1}^{M}N_i$

每个Group中的Archetype都是独立的，能大幅度避免碎片化的问题，当需要跨Group进行组件查询时，需要随机访问

因为主要的计算和数据交换都集中在某一个模块内部，将模块中适用的Component划分到一个Group中可以保证在模块内部的热点计算上有足够好的缓存命中率

（其实entt中也有Group的思考在，但其只能指定组件形成一个对应排序，相当于一个Group中只有一个Archetype）

### Hydrid Storage

因为Archetype在组合中Entity较少时不仅会产生内存浪费，也会带来碎片化的问题，所以这里还采用一个混合存储方法：Hydrid Storage

当Archetype的内存使用低于一个阈值，其会采用 SparseSet 存储，当 Archetype 的内存使用高于一个阈值，其会采用 Archetype 的 Chunk 进行存储，降低组件随机访问的寻址开销；在一些情况下因为 SparseSet 每个 Component 都是紧密排布的，能增加一些随机访问时的缓存命中率

### Tag Component

在使用 Archetype 存储时增加或删除组件会带来的拷贝开销

组件的增删是应当尽可能避免的，但是在ECS的开发中不可避免得会通过频繁的增删组件来控制System的执行

各家都给出了些解决方案：
如 Unity 中的 `IEnableableComponent` ，其也像正常的组件一样会占用 Archetype 中的空间。通过在存储中增加一串掩码来标识当前的实体是否拥有该组件。这个方案虽然简单，但带来的问题是内存的浪费以及查询时需要遍历Archetype的开销，尤其当一个Archetype中只有一小部分实体需要这种特性时这种方案会带来不必要的开销




将需要频繁的增删组件标记为Tag Component

Tag Component 不存储在 Archetype 中，而是存储在 SparseSet 中，这样就避免了内存的浪费问题，也天然对增删友好；对于空的Component，则不需要存储

> 通常来 Tag Component 是：不携带数据的组件，一般来说是空结构体
> 因为我确实没有想到什么好名字，还是觉得 Tag Component 最适合描述这种情况

为了能对 Tag Component 进行高效的查询，这里也延伸出了 Tag Archetype ，本质上来说一个 Tag Archetype 标识了一个 Archetype 中的子集。

Tag Archetype 与 Tag Archetype 间没有交集，但 Tag Archetype 一定是某个 Archetype 的子集

在查询时也会对同一个 Archetype 下的 Tag Archetype 做聚合，这样就能有更好的缓存命中率


## 总结

从 Global - Component Group - Hydrid Storage - Tag Component 的策略，可以优化使用ECS构建复杂逻辑时的性能






