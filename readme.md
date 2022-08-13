### 简介
集创赛项目，本系统命名为大白鹅处理器  
与基础的蜂鸟E203v2 SoC相比，大白鹅处理器完成如下改进和扩展  
1. 内核扩展  
- 添加RV32 B(Bitmanip)指令集扩展。
- 乘法器更换为高性能单周期乘法器。
- 添加CNN手写数字识别网络接口。
- 添加Cordic坐标旋转数字算法接口。

2. 外设扩展
- 开启FIO快速IO总线，挂载自定义外设。
- 添加AD/DAC模数/数模转换外设，需要外围模拟电路配合。
- 添加USB CDC UART外设，无需专用PHY。
- 添加LCD1602显示驱动外设，可直接驱动LCD1602。

3. 低速处理器
- DTCM访问范围扩展至128kB。
- 添加Yduck大黄鸭低速低功耗处理器，工作于常开域。
- DTCM高64kB用于大黄鸭处理器的指令空间。
- 可使用DMA传输大黄鸭处理器的指令。
- 大黄鸭处理器的外设接口连接至GPIO IOF。

4. 视频接口：
- 添加DVP视频采集与HDMI输出接口。
- 添加图像下采样模块，执行分辨率变换。

### 目录结构
使用前需要把软硬件工程移至非中文路径。  
[Vivado_prj]是硬件代码，本项目FPGA设计建立的工程，Vivado版本2019.2，器件为Xilinx 7K325T。  
源码位于 `Vivado_prj\e203\e203.srcs\sources_1`  
约束文件位于 `Vivado_prj\e203\e203.srcs\constrs_1`  
[NucleiStudio_prj]是软件代码，本项目程序设计建立的工程，NucleiStudio版本2022.1。  
[img2hex640]是用于CNN仿真的图像数据。  

### 使用说明
本项目基于NucleiStudio+Vivado开发，使用Vivado完成仿真、综合、调试任务。若烧录程序或进行仿真，需要使用NucleiStudio对程序进行编译。  
系统仿真使用tb_e203_top.v作为顶层文件，可以仿真除CNN、图像采集以外的所有模块。其中，需要将
```
`define app_path
```
宏定义修改为NucleiStudio编译生成的.verilog文件路径，以导入软件程序。  
CNN、图像下采样模块仿真使用tb_NN.v作为顶层文件。仿真前必须载入用于测试的图片，则需要将$readmemh()修改为img2hex640文件夹中`obj*.txt`的文件路径。原tb_NN.v文件中的$readmemh()指向的路径为绝对地址，想要复现则需要修改。  
