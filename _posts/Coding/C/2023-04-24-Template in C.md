---
layout: post
title: 在C语言中实现模板
subtitle: Macro in C
categories: markdown
tags: [C]
---

## C/C++预处理

https://learn.microsoft.com/zh-cn/cpp/preprocessor/preprocessor-directives?view=msvc-170

https://learn.microsoft.com/zh-cn/cpp/preprocessor/preprocessor-operators?view=msvc-170

需要了解的的有

- `#define`/`#undef`
- `#ifdef`/`#ifndef`/`#if`/`#elif`/`#else`/`#endif`
- `#include`
- `#pragma`
- [字符串化运算符 (#)](https://learn.microsoft.com/zh-cn/cpp/preprocessor/stringizing-operator-hash?view=msvc-170)
- [标记粘贴运算符 (##)](https://learn.microsoft.com/zh-cn/cpp/preprocessor/token-pasting-operator-hash-hash?view=msvc-170)
- [defined 运算符](https://learn.microsoft.com/zh-cn/cpp/preprocessor/hash-if-hash-elif-hash-else-and-hash-endif-directives-c-cpp?view=msvc-170)





## 模板

当同样的逻辑需要应用于多种类型要怎么办？

举一个简单的例子：

ADD函数将两个整型值相加

```C
int ADD(int a,int b){ return a+b };
```

现在有另一个需求：需要将两个浮点值相加，于是增加了另一个函数

```C
float ADD_1(float a,float b){ return a+b };
```

此时如果再增加一个需求：校验相加的结果不为负数，这时我们需要修改两处代码以实现这个需求

不难发现，两个针对不同类型的函数的核心逻辑是一样的，但是类型不一致，我们有没有办法只写一次代码就解决所有类型的需求？这便是所谓的**泛化**

### 使用宏解决

当然，对于这个简单的例子，有一个很好的解决方案：使用“宏函数”，“宏函数”并不是函数，它只是使用的形式与函数相似，更像是内联函数，直接镶嵌在使用的代码中

```C
#define ADD(a,b) ((a)+(b))//括号是为了避免展开后的错误逻辑
```

但是当代码的逻辑复杂起来的时候，比如我们需要

- 声明变量
- 调用函数
- 条件分支
- ...

这时会发现使用宏来解决泛化的问题是灾难性的，因为debug极为困难

### 不关心实际的类型

在某些特定的情境下，我们并不关心我们操作的实际的类型是什么，我们只关心其占用的空间，例如数组，这时我们完全可以,不考虑实际的类型，只传入数据类型的大小，例如库函数memmove

```C
void* memmove( void* _Dst,void const* _Src,size_t _Size);
```

### 运行时决定

如果类型决定了逻辑中需要调用的函数、创建变量的所需要的空间需要怎么处理？可以使用传入函数指针来，但是对于变量，我们无法在运算时动态分配栈上空间，只能在堆上进行特定类型变量空间的分配

```C
void func(size_t type_size,void func_ptr1()，void func_ptr2()，...)
{
    ...
    char* variable = (char*)malloc(type_size);
    func_ptr1();
    func_ptr2();
    ...
}
```

这种方法虽然调用繁琐、不安全、性能不佳、debug困难，但是这段代码只会被编译一次，程序体积小。

### 更好的方法？

**注：此方法因为涉及复杂的文件包含与展开，只有在Visual Studio项目中能正常进行语法分析**

是否能在C语言中找到一种方法实现模板编程，并且满足

1. 易于编写与调试
2. 调用方便
3. 高性能
4. 类型安全

回到之前的例子，实现让两值相加的ADD模板？

我们进行如下的命名

```C
int ADD_int(int a,int b){ return a+b };
float ADD_float(float a,float b){ return a+b };
```

现在两个函数只有类型名称的差别了，如果我们能实现替换过程的自动化，便实现了模板编程

想想如何使用预处理指令实现“一次编写，处处通用”

提示：实现模板的方法时需要考虑以下问题

- 如何让调用的方式具有统一性
- 如何进行模板的“实例化”
- 如何处理多个文件共同使用的类型与仅在某个文件中使用的类型
- 是否能将声明与定义写在一个文件中以方便管理
- 避免宏命名的覆盖

# C语言中实现模板编程



## 二分查找算法

先写出最为基础的二分查找算法，

```C
uint64_t BinarySearch_int(int* arr, size_t len, int val)
{
        if (len == 0) return 0;
        if (val > arr[len - 1]) return len;//超出范围返回最大索引+1
        if (val <= arr[0]) return 0;
        uint64_t mid;//搜索位置
        int mid_val;

        uint64_t a = 0;
        uint64_t b = len - 1;

        while (true)
        {
                mid = (a + b) / 2;
                mid_val = arr[mid];

                if (a == mid) return mid + 1;
                else if (mid_val < val) a = mid;
                else if (mid_val >= val) b = mid;
        }
}
```

## 模板

然后我们考虑如何进行类型替换，将需要替换的类型替换

很容易联想到使用`typedef`但是typedef不能重复定义，所以我们要使用宏

需要`#define T [需要的类型]` 然后我们将int类型替换为T

对于函数名称，我们可以使用宏将其粘贴起来，具体的实现方法有很多

这里给出我的方法，这样主要是为了提高可读性

```C
#define _template_ MACRO_CAT(Template,_,_type_)//这个宏是基础代码中的工具宏
#define T int
```

在这种情况下_template_ 会被展开为BinarySearch_int

```C
#define _type_ T//T实际上是交给用户自定义的别名，真正使用的是_type_防止命名冲突
#define Template BinarySearch
uint64_t _template_(T* arr, size_t len, T val){...}
```

上面的是定义，我们往往还需要一个声明

```C
#define Template BinarySearch
uint64_t _template_(T* arr, size_t len, T val);
```

### 如何进行编译



将声明写在xxxTemplate.h中；将定义写在xxxCore.h中，然后在我们需要使用的时候定义T然后包含声明或定义就可以了

![image (1)](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image%20(1).png)

### 为什么我们还需要一个头文件与编译单元（模块）

思考以下情况

- `int`、`float`、`size_t`等类型是内置类型或库中定义的类型，有很多编译单元会用到
- 自定义的结构体或类型有时不会暴露在头文件中，因为它们往往是实现某些功能时的内部细节，我们不希望外部使用它，也是为了防止命名冲突

所以我们把共用的类型在模块中编译，而私有的在个别的编译单元中声明编译

### 包装

当我们实例化了多种类型的时候会看到IDE提示列表中有一堆类型，如何让模板函数的调用更加统一？

使用宏进行包装，把类型作为“参数”

![image](https://cdn.jsdelivr.net/gh/StellarWarp/StellarWarp.github.io@main/img/image.png)

```C
#define BinarySearch(type ,arr, len, val) _TypedVar_(BinarySearch, type)(arr, len, val)//宏包装
```

其中_TypedVar_是如此定义，这里使用到了基础代码中的工具，以便于兼容多个类型

```C
#define _TypedVar_4(val,type1,type2,type3) MACRO_CAT(val,_,type1,_,type2,_,type3)
#define _TypedVar_3(val,type1,type2) MACRO_CAT(val,_,type1,_,type2)
#define _TypedVar_2(val,type) MACRO_CAT(val,_,type)
#define _TypedVar_(val,...) VA_MACRO(_TypedVar,val,__VA_ARGS__)
```

然后就能更加优雅地使用模板

```c
float arr[] = { 1 ,2 ,3 ,4 ,5 ,6 ,7 ,8 ,9 ,10 };
int len = sizeof(arr) / sizeof(arr[O]);
uint64_t index = BinarySearch(float, arr, len, 5);
```

### 更加通用的模板

现在这个模板函数还无法实现字符串的比较，因为在C中><无法用于比较数组

模板最大的好处就是无需传递对应的指针，可以在模板中使用模板

现在我们按照以上的方法再创建一个比较模板

```C
//a > b    1
//a < b   -1
//a==b    0
#define Cmp(type , a , b) _TypedVar_(Cmp,type)(a, b)
```

这次我们不需要编译单元，因为比较的开销小，直接内联可以免去函数调用的开销

```C
#define _type_ T
inline char _template_(T a, T b)
{
        return (a > b) - (a < b);
}
```

再对各种类型进行实例化

```C
#define Template Cmp
#define T char
#include "CompareTemplate.h"
#define T WCHAR
#include "CompareTemplate.h"
#define T int
#include "CompareTemplate.h"
#define T uint32_t
#include "CompareTemplate.h"
#define T int64_t
#include "CompareTemplate.h"
#define T uint64_t
#include "CompareTemplate.h"
#define T float
#include "CompareTemplate.h"
#define T double
#include "CompareTemplate.h"
#undef T

#define Cmp_PWCHAR wcscmp
#define Cmp_PCHAR strcmp
```

`PWCHAR`、`PCHAR`是库中定义的类型，P前缀代表指针

如`Cmp_PWCHAR` 并没有使用模板代码，而是有独立的实现方法，这便是**模板特化**

然后我们将二分查找中的比较替换成比较模板函数即可

### 还有一件事

当模板文件中存在其它函数，而某些类型并不适用

比如和二分查找写在一起的还有一个对整值向上取整到二次幂的函数，这个函数对于非整型数组并不适用

```C
#define Template up_pow2
T _template_(T n){...}
```

添加编译开关以限制模板的使用，只有当定义了INTEGRAL时才能使用此模板

```C
#ifdef INTEGRAL
#define Template up_pow2
T _template_(T n){...}
#endif // INTEGRAL
```

模块中也需要在整型编译区添加此开关

```C
#define INTEGRAL
#define T char
#include "UtilityTemplate.h"
#define T WCHAR
#include "UtilityTemplate.h"
#define T int
#include "UtilityTemplate.h"
#define T int64_t
#include "UtilityTemplate.h"
#define T size_t
#include "UtilityTemplate.h"
#undef INTEGRAL
```

## 运行代码

感受一下模板的优雅吧

```C
int main()
{
        int arr_i[] = { 0,1,2,3,4,5,5,5,6,8,9 };
        size_t len_i = sizeof(arr_i) / sizeof(arr_i[0]);

        float arr_f[] = { 0,1,2,3,4,5,5,5,6,8,9 };
        size_t len_f = sizeof(arr_f) / sizeof(arr_f[0]);

        char arr_c[] = "01234555689";
        size_t len_c = strlen(arr_c);

        WCHAR arr_w[] = L"01234555689";
        size_t len_w = wcslen(arr_w);

        PCHAR arr_pc[] = { "0123","455","5","5689" };
        size_t len_pc = sizeof(arr_pc) / sizeof(arr_pc[0]);

        PWCHAR arr_pw[] = { L"0123",L"455",L"5",L"5689" };
        size_t len_pw = sizeof(arr_pw) / sizeof(arr_pw[0]);

#define RES(func) printf(STRING_OF(func##-->%lld\n),func)

        RES(    BinarySearch(int,    arr_i,  len_i,  5   )      );
        RES(    BinarySearch(float,  arr_f,  len_f,  5.0 )      );
        RES(    BinarySearch(char,   arr_c,  len_c,  '5' )      );
        RES(    BinarySearch(WCHAR,  arr_w,  len_w,  L'5')      );
        RES(    BinarySearch(PCHAR,  arr_pc, len_pc, "5" )      );
        RES(    BinarySearch(PWCHAR, arr_pw, len_pw, L"5")      );
}
```

注：这个测试用例很简单，没有包含所有的情况

## 完整代码

代码与工程文件已上传至GitHub

https://github.com/StellarWarp/QG-RenderingGroup-2023-Winter/tree/main/Stage1/Answer