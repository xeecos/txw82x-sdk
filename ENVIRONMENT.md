# TXW828 / TXW82x 开发环境

本机（Windows）已搭好的 TXW828 开发环境说明。搭建依据是厂商公开资源，**不是** `docs.txw.ac/docs/develop/getting_started`
（原因见第 1 节）。

---

## 1. 关于官方文档的重要说明

`https://docs.txw.ac/docs/develop/getting_started` 是一篇**通用入门页，面向 TXW81x 系列**：

- 页面里引用的 SDK 是 `TXW81x_FPV-2.5.4.7.zip`，与 TXW828 无关；
- 三个下载链接（`cdk-windows-2.24.14.zip`、`TXW81x_FPV-2.5.4.7.zip`、`Booster-1.0.0.zip`）的 `href` 都是**空字符串**，
  文档只写「Download CDK from TXW developer website」，实际需要通过 `dev.txw.ac` 门户（带登录）获取；
- 页面里的 Booster 用于 TXW81x 的示例工程搭建，**不适用于** TXW82x 的 CDK 双核工程流程。

TXW828 属于 **TXW82x 系列**。该系列的 SDK、编译器、调试器都有厂商**公开仓库**，因此本环境直接从公开源搭建：

| 组件 | 来源 | 许可证 |
| --- | --- | --- |
| SDK | `github.com/Taixin-Semiconductor/TXW82x_FPV` | Apache-2.0 |
| C-SKY 工具链 | `github.com/Taixin-Semiconductor/XuanTie-CSKY-Toolchains` | 见上游 |
| 调试服务器 | `github.com/Taixin-Semiconductor/XuanTie-DebugServer` | 见上游 |

---

## 2. 目录布局

工具链已**收进本项目**，整个 `D:\Projects\txw82x_sdk` 就是一个自包含的开发包，可以整体拷贝或归档：

```
D:\Projects\txw82x_sdk\               <- 项目根，同时是 git 仓库
├── ENVIRONMENT.md                    <- 本文件（入库）
├── setup_tools.ps1                   <- 一键下载 + 校验 + 解压工具链（入库）
├── env.ps1 / env.cmd                 <- 会话激活脚本（入库）
├── build.ps1                         <- 命令行编译封装（入库）
├── txw_tools\                        <- 本地工具目录（被 .gitignore 排除，不入库）
│   ├── csky-elfabiv2\                <- C-SKY GCC 工具链（317 MB）
│   ├── xuantie-debugserver\          <- DebugServer 安装包（21 MB）
│   ├── dl\                           <- 原始压缩包缓存（94 MB，可删）
│   └── check_env.py                  <- 环境自检脚本
├── project\  sdk\  csky\  libs\  doc\  ohos\  tools\   <- 厂商 SDK 原有内容
```

目录名叫 `txw_tools` 而不是 `tools`，是因为 SDK 里**已经有一个厂商的 `tools/` 目录**
（`alios_stack.exe`、`cpu.txt`），不能重名。

### 2.1 已安装内容与校验

| 组件 | 版本 / 标识 | 位置 | 状态 |
| --- | --- | --- | --- |
| SDK | `TXW82x_FPV` v2.7.1.7（release `v2.7.1.7-44398`），3893 个文件 | `D:\Projects\txw82x_sdk` | 已克隆（git） |
| C-SKY GCC | Xuantie-800 Tools V3.10.33 Minilibc abiv2 B20250328，GCC **6.3.0** | `txw_tools\csky-elfabiv2` | 已解压并验证可用 |
| **XuanTie CDK** | 安装于 `D:\C-SKY\CDK`，含 `cdk-make.exe` | `D:\C-SKY\CDK` | **已安装**，编译和调试都靠它 |
| XuanTie DebugServer | V5.18.10-20260603 | 随 CDK 装在 `D:\C-SKY\CDKRepo\DebugServer`；`txw_tools\xuantie-debugserver\` 另存了独立安装包 | 已可用 |
| 下载缓存 | — | `txw_tools\dl` | 已保留原始压缩包，可随时删除 |

> SDK 官方 README 要求 Windows + XuanTie CDK，本机已满足。

下载文件的 SHA256 已与厂商 README 公布值**逐字节比对一致**：

```
3eb0fa8681f0996136902171855db974659674ed3d6ebe7ddc6a601ddc0f27f2  csky-toolchain.tgz
588c5919441c9d6d5cfc18cab2db88147acab57abbc06fdd437dbb6b6ac10c8f  debugserver.zip
```

### 2.2 什么入库、什么不入库

`txw_tools/`（工具链等约 412 MB 二进制）**不入库**，忽略规则写在 `.gitignore` 末尾的 `/txw_tools/`。
这条规则会随仓库分发，所以任何人克隆下来都不会误把工具链提交进去。环境脚本和文档都正常入库。

CDK 的构建产物（`Obj/`、`Lst/`、`.cache/`、`*.elf`、`APP.bin` 等）同样不入库，相关规则和原因见第 7 节限制 4。

克隆后重建工具链只要一条命令（自动下载并校验 SHA256，哈希值见上一节）：

```powershell
.\setup_tools.ps1
```

注意：**不要在这个仓库里执行 `git clean -xdf`** —— 它会删掉未跟踪文件，包括整个 `txw_tools\` 工具链。
重新跑 `setup_tools.ps1` 可以恢复，但需要重下约 98 MB。

### 2.3 路径长度已实测

把工具链套进项目会加长约 11 个字符，所以搬之前实测过：

- 工具链内最长路径 **152 字符**，搬入后约 163，远低于 260 的上限；
- 本机已启用长路径支持（注册表 `LongPathsEnabled = 0x1`）。

---

## 3. 快速开始

**如果是从远程仓库刚克隆下来**，先重建工具链（已下载过会自动跳过）：

```powershell
.\setup_tools.ps1
```

然后激活环境（脚本只影响当前会话，可重复执行）：

```powershell
cd D:\Projects\txw82x_sdk
. .\env.ps1        # PowerShell
```

```cmd
cd D:\Projects\txw82x_sdk
env.cmd            :: cmd.exe
```

验证工具链：

```powershell
csky-elfabiv2-gcc.exe --version
```

工具链的 `bin` 目录已追加到**用户级 PATH**（不是系统 PATH）。新开的终端可直接调用 `csky-elfabiv2-*`。

还可以跑一次完整的自检脚本，它会从 CDK 工程文件里读出真实编译参数并试编译两个核的 `main.c`：

```powershell
python txw_tools\check_env.py
```

---

## 4. 芯片与双核工程结构

TXW828 是双核 SoC，SDK 用两个 CDK 工程分别对应两个核，工作区文件是 `project/txw82x.cdkws`：

| 工程 | 核 | CPU 参数 | 浮点 | 编译参数 | 头文件目录 |
| --- | --- | --- | --- | --- | --- |
| `project/txw82xCore` | CPU1 | `e804d` | 软浮点 | `-O3 -g3` | 75 个（30 个不存在） |
| `project/txw82xApp` | CPU0 | `e804df` | 硬浮点 | `-O3 -g3` | 392 个（105 个不存在） |

两个工程的公共宏定义：

```
__NO_BOARD_INIT  TXW4302804  ARCH_CSKY  TXW82X  MPOOL_ALLOC
CONFIG_UMAC4  FW_INFO  CPU_CK804DF  CONFIG_SLEEP
```

> **编译顺序不能颠倒：必须先 `txw82xCore` 再 `txw82xApp`。**
> App 的链接和打包依赖 Core 镜像的大小、BSS 边界和 CRC 结果。只编 App 会把**旧的 Core** 打进固件。

---

## 5. 编译（需要 XuanTie CDK）

SDK 的编译**必须通过 XuanTie CDK**（`cdk-make.exe`），官方 README 明确写了本版本仅支持 Windows + CDK，
CDS/Linux 构建环境「尚未准备和验证」。**CDK 是本次唯一需要手动完成的步骤。**

### 5.1 CDK（本机已安装）

**本机已装好**：`D:\C-SKY\CDK\cdk-make.exe` 存在。`env.ps1`、`env.cmd`、`build.ps1` 都会自动探测它，不用手动设
`CDK_ROOT`（想显式指定时才需要）。

换一台机器才需要手动安装：

1. 打开 <https://www.xrvm.cn/soft-tools/tools/CDK>（或资源中心 <https://www.xrvm.cn/community/download?id=4119141468164132864>）。
2. 下载 Windows 版：当前最新为 `cdk-windows-V2.24.19-20260427-1707.zip`（约 1.66 GB）。
   厂商文档里写的最低版本是 `cdk-windows-2.24.14.zip`，两者都可以。
3. 解压后运行 `setup.exe`，按向导完成安装（建议装在 D 盘默认路径）。
4. 若装在非默认路径：`setx CDK_ROOT "<你的 CDK 路径>"`。

> CDK 的安装目录还顺带补上了 GDB 缺的那个 DLL，见第 7 节。

### 5.2 命令行编译

```powershell
. .\env.ps1
.\build.ps1                          # 自动按 Core -> App 顺序编译
.\build.ps1 -Clean                   # 清理
.\build.ps1 -CdkRoot D:\C-SKY\CDK    # 显式指定 CDK 路径
```

`build.ps1` 内部执行的就是厂商 SDK 文档给出的命令形式：

```powershell
cdk-make.exe -p .\project\txw82xCore\txw82xCore.cdkproj -d build -c FLASH
cdk-make.exe -p .\project\txw82xApp\txw82xApp.cdkproj   -d build -c FLASH
```

### 5.3 图形界面编译

用 CDK 打开 `project\txw82x.cdkws`，选择 `Debug` 工作区配置（它把两个工程都映射到 `FLASH` 配置），
然后 `Project > Build All`。

编译产物通过 `project/txw82xApp/BuildBIN.sh` 后处理，生成最终整机镜像（`APP.bin` 等）。
后处理用到的工具 `sdktools.exe`、`makecode.exe`、`crc.exe`、`BinScript.exe`、`pin_bin.exe`
都已经在仓库里，**不需要额外下载**。

---

## 6. 烧录与调试

1. 运行 DebugServer 安装程序（安装包已解压好，需要交互式安装）：

   ```powershell
   cd D:\Projects\txw82x_sdk\txw_tools\xuantie-debugserver\XuanTie-DebugServer-windows-V5.18.10-20260603-2008
   .\setup.exe
   ```

   如果你的 CDK 已经装了 DebugServer，这一步可以跳过。
2. 把开发板接到 CKLink 调试器，调试器用 USB Type-C 线连到电脑。
3. 在 CDK 里 `Flash > Download` 烧录；烧完 LED 开始闪烁即表示 Blinky 示例跑起来了。

串口终端（PuTTY 本机已装）用于看启动日志。量产/串口下载工具需按开发板和 Flash 型号另行获取。

---

## 7. 已验证项与已知限制

**已验证（可复现）**

- 两个下载包的 SHA256 与厂商公布值完全一致。
- 编译器可正常启动：`csky-elfabiv2-gcc.exe (Xuantie-800 Tools V3.10.33 Minilibc abiv2 B20250328) 6.3.0`。
- 用 CDK 工程文件里的真实参数，成功编译了两个核的 `main.c`：
  - `txw82xApp`：`-mcpu=e804df -mhard-float -O3 -g3` → 通过
  - `txw82xCore`：`-mcpu=e804d -O3 -g3` → 通过
- 工具链的合法 `-mcpu` 名称是 `e804d / e804df / e804dt / e804dft` 等；CDK 工程里写的
  `CPU_CK804DF` 是宏名，**不是** `-mcpu` 的取值（`-mcpu=ck804df` 会被拒绝）。
- **GDB 可用**：`GNU gdb (Xuantie-800 Tools V3.10.33 Minilibc abiv2) 7.12`，目标架构自动识别为 `csky`。
  修复方式见下面限制 1。
- **完整固件已成功编译**（CDK，`txw82xCore` → `txw82xApp`）：产出 `project/txw82xApp/APP.bin` 和
  `project.elf`（ELF32 / Machine: CSKY / 入口 `0x10068f20`），以及打包后的
  `txw82xApp_v2.7.1.7-44398_app-0_..._720P_Demo.bin`（1,357,328 字节）。

**已知限制**

1. **独立工具链的 GDB 原本不可用，现已修好。** `csky-elfabiv2-gdb.exe` 是 32 位程序，依赖
   `libexpat-1.dll`，而该压缩包里**没有**这个 DLL，所以直接运行会无输出地失败（Windows 退出码
   `0xC000007B` = `STATUS_INVALID_IMAGE_FORMAT`；Git Bash 里显示为 127）。
   好消息是 **CDK 安装目录里带了一份 32 位同版本 DLL**：
   `D:\C-SKY\CDK\CSKY\MinGW\bin\libexpat-1.dll`。`env.ps1` / `env.cmd` 现在会把该目录
   **追加**到 PATH 末尾（不是前置），gdb 即可正常加载，同时不会让 CDK 的 `make.exe` 遮蔽你已有的 make。
   若哪台机器没装 CDK，gdb 仍然不可用。
2. **105 个头文件目录在公开仓库中不存在**（如 `sdk/driver/isp`、`sdk/lib/VFS`、`sdk/app/AI_alarm_clock` 等）。
   这是**预期行为**，不是克隆不完整：这些模块（ISP、H.264、USB、SD、Audio、Wi-Fi 等）以 `libs/` 里的
   预编译静态库形式提供，SDK 本身不是全源码交付。CDK 能容忍不存在的 include 目录，实际编译已验证通过。
3. 仓库里有一处历史遗留路径：`project/txw82xApp/txw82xApp.cdkproj` 的 include 列表里仍写着
   `../../SDK_2.7.0/sdk/driver/sha`（旧版本目录名）。不影响编译（固件已成功编译），如需严格清理可以改掉。
4. **厂商 `.gitignore` 漏掉了双核工程的构建产物。** 它的规则锚定在 `/project/`，而 CDK 实际把产物写在
   `project/txw82xCore/` 和 `project/txw82xApp/` 子目录下，所以全部匹配不上——`git add -A` 会试图暂存约
   **580 MB** 的 `Obj/`、`Lst/`、`.cache/` 以及生成的固件。已在本仓库 `.gitignore` 末尾补齐镜像规则
   （`/project/*/Obj/` 等），正常提交不会再误带构建产物。

---

## 8. 顺带发现：用户 PATH 有历史损坏项

追加工具链路径时读取到你当前**用户级 PATH 中存在损坏条目**，例如：

```
d:\app;ications\Git\cmd
C:\Program Files (x86)\Windows Kits\10\Wi
```

这看起来是以前用 `setx` 设置 PATH 时被 1024 字符上限截断造成的（本次操作**没有**造成、也没有改动这些条目，
新追加的工具链路径位于 PATH 末尾且完整）。建议之后用「系统属性 > 环境变量」图形界面清理一次，
避免 `setx` 再截断。

---

## 9. Git 远程仓库

| remote | 地址 | 用途 |
| --- | --- | --- |
| `origin` | `git@github.com:xeecos/txw82x-sdk.git` | 自己的仓库，日常推送目标 |
| `upstream` | `https://github.com/Taixin-Semiconductor/TXW82x_FPV.git` | 厂商上游，只读，用于跟进新版本 |

`main` 分支由两条历史合并而成：你仓库原有的 `Initial commit`（`e51737d`）和厂商的 SDK 导入提交
（`14c126c` / `b7e8cc8`）。**两条线都保留**，没有强推覆盖，所以既能沿用自己的仓库历史，
也能直接把厂商新版本 merge 进来。

合并时 `LICENSE` 和 `README.md` 有冲突，按厂商版本保留了 —— SDK 本身是 **Apache-2.0**，
而仓库初始提交里 GitHub 生成的 MIT 模板对这个 SDK 并不适用，`README.md` 也以厂商的 SDK 说明为准。
本环境自己的说明集中在 `ENVIRONMENT.md`。

跟进厂商新版本：

```powershell
git fetch upstream
git merge upstream/v2.7.1.7      # 或换成新的分支 / 标签
.\setup_tools.ps1                # 若工具链版本也变了，同步更新脚本里的 URL 和 SHA256
```
