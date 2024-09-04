# Relation


## Introduction

在编写逻辑时，不可能只是处理一个Entity上的数据

Entity与Entity之间往往会产生交互，在没有Relation的ECS中处理这种常见的情况却变得非常棘手

这往往需要在编写逻辑时通过一个Component中记录与之相关的Entity并通过组件的随机访问获取其它Entity中的数据，这回带来很多问题

1. 另一个Entity的生命周期不受控，处理时可能出现非法的Entity
2. 其它Entity的Component不受约束，其它Entity上是否存在某个Component完全由开发者自己在System的编写逻辑中处理，带来可靠性和可维护性上的问题
3. 不能联合访问其它Entity的一组Component，带来更多的随机访问的开销

如果没有一个Relation系统来处理这些繁琐的事情的话，ECS的开发会变得非常痛苦

## Relation Ship



## Relation Query

