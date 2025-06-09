# 编译依赖脚本

构建平台 **Android** **Linux**

针对 **Android** 平台的 **ABI**:
    * armeabi-v7a
    * arm64-v8a
    * x86
    * x86_64

针对 **Linux** 平台的 **ABI**:
    * x86_64

构建 **Linux** 平台的依赖是因为 **Android** 和 **Linux** 的 **ABI** 不同，编译生成的**Android**的依赖无法在**x86_64**架构的处理器机器上运行，所以需要针对该架构单独编译一个版本，以用于后面的测试。

## OpenCV

## ONNXRuntime

## Boost

## fmt

## Eigen3

## **common** 文件

## `common_color.sh`**导出变量**一览
文件描述：控制台文本输出颜色控制

| **常规颜色**        
| 变量名   | 描述 |
| ------- | --- |
| BLACK   | 黑色 |
| RED     | 红色 |
| GREEN   | 绿色 |
| YELLOW  | 黄色 |
| BLUE    | 蓝色 |
| PURPLE  | 紫色 |
| CYAN    | 洋色 |
| WHITE   | 白色 |
| NC      | 无色 |

| **粗体颜色**
| 变量名    | 描述    |
| -------- | ------ |
| BBLACK   | 粗体黑色 |
| BRED     | 粗体红色 |
| BGREEN   | 粗体绿色 |
| BYELLOW  | 粗体黄色 |
| BBLUE    | 粗体蓝色 |
| BPURPLE  | 粗体紫色 |
| BCYAN    | 粗体洋色 |
| BWHITE   | 粗体白色 |

| **背景颜色**
| 变量名      | 描述    |
| ---------- | ------ |
| ON_BLACK   | 背景黑色 |
| ON_RED     | 背景红色 |
| ON_GREEN   | 背景绿色 |
| ON_YELLOW  | 背景黄色 |
| ON_BLUE    | 背景蓝色 |
| ON_PURPLE  | 背景紫色 |
| ON_CYAN    | 背景洋色 |
| ON_WHITE   | 背景白色 |

## `common_git.sh`**导出变量**一览

导出函数`git_clone_or_update`

```bash
# 函数: git_clone_or_update
# 功能: 如果目标目录不存在或不是一个git仓库，则克隆;否则，fetch并检出指定版本。
# 参数: 
#   $1: Repository URL (仓库地址)
#   $2: Target directory (目标本地目录的绝对或相对路径)
#   $3: Optional Git Version(tag, branch, commit tag) to checkout.
#       如果为空、"master"或"main"，将尝试更新当前分支或检出默认分支并更新
# 注意: 此函数会改变当前目录，并在结束时返回到原始目录
```

## `common_env.sh`**导出变量**一览
| 主机编译和交叉编译的相关变量
| 变量名                   | 描述                  |
| ----------------------- | -------------------- |
| ANDROID_SDK_HOME        | ANDROID_SDK_HOME 路径 |
| ANDROID_NDK_HOME        | ANDROID_NDK_HOME 路径 |
| NDK_VERSION_STRING      | ANDROID_NDK 版本信息   |
| CLANG_COMPILER_PATH     | NDK Clang(C)路径      |
| CLANG_CXX_COMPILER_PATH | NDK Clang(C++)路径    |
| CLANG_VERSION_STRING    | NDK Clang 版本信息     |
| HOST_GCC_PATH           | 主机 gcc 路径          |
| HOST_GXX_PATH           | 主机 g++ 路径          |
| HOST_GCC_VERSION        | 主机 gcc 版本          |
| HOST_CLANG_PATH         | 主机 clang 路径        |
| HOST_CLANGXX_PATH       | 主机 clang++ 路径      |
| HOST_CLANG_VERSION      | 主机 clang 版本        |
