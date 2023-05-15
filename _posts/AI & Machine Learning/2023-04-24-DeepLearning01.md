## 神经网络

The basic structure of a neural network consists of multiple layers of neurons, each layer performing a specific type of computation on the input data. The first layer, known as the input layer, receives the raw input data, which is then passed through one or more hidden layers before being processed by the final output layer.

During the training process, the network is fed a large set of input-output pairs and adjusts the weights of its connections between neurons to minimize the difference between its predictions and the actual outputs. This process is known as backpropagation and allows the network to learn complex patterns in the data and make accurate predictions on new, unseen data.

```mermaid
graph LR
A(输入层) --> B(隐藏层)
B --> C(输出层)
```

https://www.bilibili.com/video/BV1bx411M7Zx

### 神经元

一个神经元通常包含三个部分：输入部分、激活函数和输出部分。输入部分包括输入值 $a^{(l-1)}$ 和对应的权重 $W^{(l)}$，其作用是将输入值乘以相应的权重并加以加权和。激活函数作用于加权和，输出一个非线性变换后的结果 $z^{(l)}$。最后，输出部分将 $z^{(l)}$ 传递给下一层的神经元或输出层。


### 激活值

激活值是神经元的输出值，它是由输入值和权重值计算得到的

权重与偏置

对于第k层的第j个神经元，它的激活值为
$$
a^{(k)}_j = \sigma\left(\sum_{i=1}^n w_{ji}^{(k)} a^{(k-1)}_i + b_j^{(k)}\right)
$$
用线性代数的角度来看，第k层的激活值可以表示为（第k层有m个神经元，第k-1层有n个神经元）
$$
a^{(k)} = \sigma(W^{(k)} a^{(k-1)} + b^{(k)})\newline\newline

=\sigma\left(
    \begin{bmatrix}
        w^{(k)}_{0,0} & w^{(k)}_{0,1} & w^{(k)}_{0,2} & \cdots & w^{(k)}_{0,n} \\
        w^{(k)}_{1,0} & w^{(k)}_{1,1} & w^{(k)}_{1,2} & \cdots & w^{(k)}_{1,n} \\
        w^{(k)}_{2,0} & w^{(k)}_{2,1} & w^{(k)}_{2,2} & \cdots & w^{(k)}_{2,n} \\
        \vdots & \vdots & \vdots & \ddots & \vdots \\
        w^{(k)}_{m,0} & w^{(k)}_{m,1} & w^{(k)}_{m,2} & \cdots & w^{(k)}_{m,n} \\
    \end{bmatrix}

    \begin{bmatrix}
        a_0^{(k-1)} \\
        a_1^{(k-1)} \\
        a_2^{(k-1)} \\
        \vdots \\
        a_n^{(k-1)} \\
    \end{bmatrix}
    +
    \begin{bmatrix}
        b^{(k)}_0 \\
        b^{(k)}_1 \\
        b^{(k)}_2 \\
        \vdots \\
        b^{(k)}_m \\
    \end{bmatrix}
\right)
$$

### 激活函数
**sigmoid函数**
$$
\sigma(x) = \frac{1}{1+e^{-x}}
$$
**ReLU函数**
$$
c \max(0, b+w x_1) + c^\prime \max(0, b^\prime+w^\prime x_1)
$$



## Loss Function / Cost Function

Loss function是机器学习中的一个概念，用于衡量模型预测的输出与实际值之间的差异。在训练神经网络时，目标是通过调整模型的参数来最小化这个损失函数，从而提高模型的准确性。

损失函数通常是一个数值，它代表了模型的预测输出与真实值之间的差异，也可以理解为误差或成本。在监督学习中，损失函数通常基于模型的输出和真实标签之间的距离计算得出

- MAE (Mean Absolute Error)：平均绝对误差，是预测值与真实值之差的绝对值的平均值， $\frac{1}{n}\sum_{i=1}^n|y_i-\hat{y}_i|$
- MSE (Mean Squared Error)：均方误差，是预测值与真实值之差的平方的平均值， $\frac{1}{n}\sum_{i=1}^n(y_i-\hat{y}_i)^2$
- RMSE (Root Mean Squared Error)：均方根误差，是均方误差的算术平方根， $\sqrt{\frac{1}{n}\sum_{i=1}^n(y_i-\hat{y}_i)^2}$

优化算法会尝试将损失函数最小化，以调整模型参数来改善模型的性能。这可以通过计算损失函数的**梯度**来实现，然后使用**梯度下降**等优化算法来更新模型参数，使其朝着更优的方向移动。

### 梯度下降

梯度下降（Gradient Descent）是一种常用的优化算法，用于调整模型参数以最小化损失函数。梯度下降的基本思想是沿着损失函数梯度的反方向更新模型参数，直到达到损失函数的最小值。

在训练神经网络时，梯度下降被广泛应用于调整网络中的权重和偏置。梯度下降的过程通常可以分为以下几个步骤：

随机初始化模型的参数（权重和偏置）
从训练集中随机选择一个样本作为输入
使用模型进行前向传播，计算预测值
计算损失函数的梯度
使用梯度下降算法更新模型参数
重复步骤2到5，直到达到收敛条件（例如达到最大迭代次数或损失函数的变化不大）
梯度下降的核心是计算损失函数的梯度。在神经网络中，通常使用反向传播算法（Backpropagation）来计算损失函数相对于每个参数的梯度。反向传播算法通过将梯度从输出层向输入层逐层传递来计算梯度，然后使用梯度下降算法更新模型参数。

梯度下降算法的性能受到多个因素的影响，例如学习率、批大小和优化算法等。一般来说，较小的学习率可以使模型更加稳定，但可能需要更多的迭代次数才能达到最小值。较大的学习率可能会导致算法无法收敛或者收敛到次优解。批大小的选择也会影响梯度估计的准确性，较小的批大小通常可以提高训练的速度，但可能会导致梯度估计的方差较大。优化算法的选择也会影响算法的性能，例如常用的优化算法包括梯度下降、随机梯度下降、Adam等

## 反向传播算法

从网络的输出开始，逐层计算每个节点的误差信号，然后根据误差信号计算每个参数的梯度，最后使用梯度下降算法更新参数，以最小化损失函数。

具体来说，反向传播算法的思路可以概括为以下几个步骤：

1. 前向传播：将输入数据输入神经网络，逐层计算每个节点的输出。
2. 计算损失函数：将神经网络的输出与真实标签进行比较，计算损失函数。
3. 反向传播误差信号：从输出层开始，根据链式法则计算每个节点的误差信号，将其向前传播到每一层隐藏层和输入层。
4. 计算梯度：使用误差信号计算每个参数（权重和偏置）的梯度。
5. 更新参数：使用梯度下降算法，根据梯度更新每个参数的值。
6. 重复上述步骤：不断重复上述步骤，直到达到预定的训练轮数或者达到一定的准确率。

对于输出层的一个节点$a^{(k)}_j = \sigma\left(\sum_{i=1}^n w_{ji}^{(k)} a^{(k-1)}_i + b_j^{(k)}\right)$,增加或减小其值有三个途径：
- 增加或减小权重$W$
- 增加或减小偏置$b$
- 增加或减小输入值$a$（间接）
通过标签的值$y$和输出值$a$的差异来计算误差信号$\delta$，我们可以给出对于此节点，其期望的输出值$a$应该增加或减小多少，即$\delta$的值。然后，我们可以使用链式法则来计算损失函数对于权重$W$和偏置$b$的梯度，从而更新这些参数。



假设我们有一个 $L$ 层的神经网络，每一层的权重矩阵为 $W^{(l)}$，偏置向量为 $b^{(l)}$，输入为 $x$，输出为 $\hat{y}$。设 $a^{(l)}$ 表示第 $l$ 层的激活值，$z^{(l)}$ 表示第 $l$ 层的加权输入。

反向传播是用于计算神经网络中的梯度的方法。反向传播的过程分为两个阶段：前向传播和反向传播。在前向传播阶段，我们计算每一层的激活值和加权输入。在反向传播阶段，我们计算每一层的误差和梯度，用于更新权重和偏置。

下面是多层神经网络反向传播的公式：

#### 前向传播

输入层： $a^{(0)} = x$

第 $l$ 层：

$$z^{(l)} = W^{(l)}a^{(l-1)} + b^{(l)}$$

$$a^{(l)} = g^{(l)}(z^{(l)})$$

其中，$g^{(l)}(\cdot)$ 是第 $l$ 层的激活函数。

输出层： $\hat{y} = a^{(L)}$

#### 反向传播

第 $L$ 层：

$$dz^{(L)} = \hat{y} - y$$

其中，$y$ 是真实的标签。

第 $l$ 层到第 $L-1$ 层：

$$
dz^{(l)} = (W^{(l+1)})^Tdz^{(l+1)}*g^{(l)'}(z^{(l)})
$$

其中，$*$ 表示点乘，$g^{(l)'}(\cdot)$ 表示第 $l$ 层的激活函数的导数。
$(W^{(l+1)})^T$ 表述了从第 $l+1$ 层到第 $l$ 层的权重关系

偏置的梯度：

$$
db^{(l)} = \frac{1}{m}\sum_{i=1}^mdz^{(l)}_i
$$

权重的梯度：

$$
dW^{(l)} = \frac{1}{m}dz^{(l)}(a^{(l-1)})^T
$$

其中，$m$ 是训练样本的数量。

假设学习率为 $\eta$，则权重参数的更新公式可以表示为：
$$
w_{ij} \leftarrow w_{ij} - \eta \delta_j x_i
$$
其中，$x_i$ 表示输入层的输入数据，$\delta_j$ 表示神经网络中第 $j$ 个神经元的误差。

通常使用批量梯度下降法（batch gradient descent）或随机梯度下降法（stochastic gradient descent）来更新权重和偏置。

##### 推导

在反向传播算法中，假设神经元处于第 $l$ 层，误差 $dz^{(l)}$ 表示第 $l$ 层对误差的贡献，需要计算该误差对于输入部分的梯度。根据链式法则，$dz^{(l)}$ 可以分解为 $dz^{(l)} = \frac{\partial J}{\partial z^{(l)}}$，其中 $J$ 表示整个神经网络的损失函数。

根据上述定义，可以推导出单个神经元的误差项 $dz^{(l)}$ 的计算公式：

$$
dz^{(l)} = \frac{\partial J}{\partial z^{(l)}} = \frac{\partial J}{\partial a^{(l)}} * \frac{\partial a^{(l)}}{\partial z^{(l)}} = \frac{\partial J}{\partial a^{(l)}} * g^{(l)'}(z^{(l)})
$$

其中，$a^{(l)}$ 表示第 $l$ 层神经元的输入值，即 $a^{(l)} = \sum\limits_{i=1}^{n^{(l-1)}} W_{i}^{(l)} a_{i}^{(l-1)}$，$n^{(l-1)}$ 表示第 $l-1$ 层神经元的个数，$g^{(l)'}(z^{(l)})$ 表示第 $l$ 层神经元的激活函数在 $z^{(l)}$ 处的导数。

进一步，将 $dz^{(l)}$ 展开，可以得到：

$$
dz^{(l)} = \frac{\partial J}{\partial z^{(l)}} = \frac{\partial J}{\partial a^{(l)}} * \frac{\partial a^{(l)}}{\partial z^{(l)}} = \sum\limits_{i=1}^{n^{(l+1)}} \frac{\partial J}{\partial z_{i}^{(l+1)}} * \frac{\partial z_{i}^{(l+1)}}{\partial a^{(l)}} * g^{(l)'}(z^{(l)})
$$

其中，$\frac{\partial z_{i}^{(l+1)}}{\partial a^{(l)}} = W_{i}^{(l+1)}$，表示第 $l+1$ 层神经元的输出值对于第 $l$ 层神经元输入值的偏导数。

将上述式子进一步化简，得到：

$$
dz^{(l)} = (W^{(l+1)})^Tdz^{(l+1)}*g^{(l)'}(z^{(l)})
$$

其中，$(W^{(l+1)})^Tdz^{(l+1)}$ 表示第 $l+1$ 层神经元的误差项在经过权重矩阵 $W^{(l+1)}$ 的转置后，传递给第 $l$ 层神经元的误差项。$g^{(l)'}(z^{(l)})$ 表示第 $l$ 层神经元激活函数在 $z^{(l)}$ 处的导数，用于将误差项映射到输入部分。

因此，从单个神经元的角度来看，反向传播算法中的 $dz^{(l)} = (W^{(l+1)})^Tdz^{(l+1)}*g^{(l)'}(z^{(l)})$ 表示将第 $l+1$ 层神经元的误差项传递给第 $l$ 层神经元，并对传递下来的误差项进行映射，以计算第 $l$ 层神经元的误差项。



自动求导

https://zhuanlan.zhihu.com/p/403382297

Autograd 是反向传播（Back propagation）中运用的自动微分系统。 从概念上来说，autograd 会记录一张有向无环图（Directed acyclic graph），这张图在所有创建新数据的操作被执行时记录下这些操作。图的叶子（leaves）是输入张量，根（root）是输出张量。 通过从根到叶追踪这张图，可以使用链式法则自动计算梯度。
