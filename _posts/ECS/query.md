# Query

## Introduction

ECS是这样的，用户只要关心System里的逻辑和Query的数据就可以了，而ECS考虑的就很多了

Query是连接逻辑和数据的途径，它是ECS的核心概念

Query需要通过数据的描述找到对应的数据

许多ECS实现中Query的查询并不复杂，如
使用 Archetype 的实现中，一般的实现是将所有的Archetype都遍历一遍来筛选需要的数据。因为对于只使用Archetype的ECS来说Query的查询并不是性能热点。
使用 SparseSet 的实现中，Query往往需要缓存满足条件的实体，并监听各有关组件表的增删来更新缓存

因为HECS的混合存储架构，以及需要聚合优化、考虑存在大量Query和Archetype下的性能等原因，Query的算法复杂度增加不少，以至于需要独立的模块来处理这些问题

Query主要分为两部分，数据更新访问 与 数据查询

## 访存模型



## 数据查询

Query到底在做什么

Query的条件指定了集合的查询区域

Archetype是集合中的一点

无非要做两件事
1. 新增 Query 查询匹配的 Archetype
2. 新增 Archetype 查询匹配的 Query

### In-Group Query

支持的查询类型有
- 全匹配：all
- 任一匹配：any
- 排除：none

一个完整的条件可以被描述为
`base... tag... ((base...|tag...) ...) none(base...,tag...)`

拆分为三部分为
- all part `base... tag...`
- any part `(base...|tag...) ...`
- none part `none(base...,tag...)`

根据是否有 tag， Query可以被分为以下几类

- untag query / direct query
  - 条件不含 tag
  - 直接访问 Archetype
  - `base... (base...) none(base...)`
- mix query
  - 条件含 tag
  - 直接访问 Archetype 或访问 Tag Archetype
  - `base... tag... ((base...|tag...) ...) none(base...,tag...)`
- pure tag query
  - 全匹配的条件只有 tag
  - 只访问 Tag Archetype
  - `tag... ((base...|tag...) ...) none(base...,tag...)`


还有一类特殊的 Query
- archetype query，其用于查询有着相同arhcetype的tag archetype
- component query，只有一个Component的Query，作为基础节点


#### Subquery

Subquery 指一个 Query 的 Entity 集是另一个 Query 的子集

通过从父查询中筛选Archetype可减少查询量



### Cross-Group Query

跨Group的Query则要通过潜在组合的计数来实现

一个计数表：记录Entity对应Match的Group的数量
一个Entity缓存表：记录满足条件的Entity


