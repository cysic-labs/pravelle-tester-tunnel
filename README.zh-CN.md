# Pravelle 测试隧道

这是一个体积小、便于审计的 SSH 客户端，用于让已获授权的 Pravelle
测试参与者建立两个仅绑定本机回环地址的端口转发。

本项目只包含客户端隧道工具，不包含 Pravelle 合约、证明器或撮合器源码、
部署地址、凭据、服务器配置或生产运维内容。

## 建立的转发

| 本地端点 | 远端端点 | 用途 |
| --- | --- | --- |
| `127.0.0.1:8798` | `127.0.0.1:8798` | Matcher API |
| `127.0.0.1:8799` | `127.0.0.1:8802` | Prover API |

两个本地端口都只监听 `127.0.0.1`，不会暴露给测试者所在的局域网。

## 使用条件

- macOS 或 Linux
- Bash
- OpenSSH 客户端
- 专门为测试者签发的 SSH 私钥文件
- 运营方提供的受限 SSH 主机别名

远端账户必须由运营方在服务器端限制：禁止 shell、Agent/X11/TTY 转发，
并通过 `PermitOpen` 只允许访问上表中的两个回环服务。客户端脚本无法替代
这些服务器端限制。

## 使用方法

```bash
chmod 600 /你的路径/tester_identity
./bin/pravelle-tester-tunnel restricted-test-host /你的路径/tester_identity
```

在已获授权的测试窗口内保持终端运行。需要停止时按 `Ctrl-C`。

该客户端会：

- 强制要求显式提供独立的测试者私钥；
- 拒绝权限不是 `0400` 或 `0600` 的私钥文件；
- 拒绝已经包含本地、远端或动态转发的 SSH 主机别名；
- 禁止 shell、TTY、Agent/X11 转发、连接复用、密码认证和本地命令；
- 任意一个本地转发建立失败时立即退出。

## SSH 别名示例

请使用运营方提供的真实信息，不要把真实主机名、用户名或私钥路径提交到
公开仓库。

```sshconfig
Host restricted-test-host
    HostName example.invalid
    User restricted-tester
```

不要在该别名中添加 `LocalForward`、`RemoteForward` 或 `DynamicForward`。
所有允许的转发都由客户端脚本显式定义。

## 验证发布包

当前版本为
[`v1.0.0`](https://github.com/cysic-labs/pravelle-tester-tunnel/releases/tag/v1.0.0)。
请同时下载源码压缩包和 `SHA256SUMS`，解压前先验证压缩包：

```bash
shasum -a 256 -c SHA256SUMS
tar -xzf pravelle-tester-tunnel-v1.0.0.tar.gz
cd pravelle-tester-tunnel-v1.0.0
```

进入解压后的目录，再验证所有受版本控制的文件并运行离线测试：

```bash
shasum -a 256 -c SHA256SUMS
./tests/test.sh
```

Linux 用户也可以使用 `sha256sum -c SHA256SUMS`。

## 安全边界

本工具本身不会授予任何访问权限。运营方仍需单独签发有时限的测试者密钥，
并正确配置服务器端受限账户。

严禁：

- 使用 owner、deployer、operator 或 Safe 签名者私钥；
- 通过聊天、邮件、Issue 或截图发送私钥；
- 将真实私钥或 SSH 主机配置提交到仓库；
- 在 SSH 账户意外打开远程 shell 后继续操作。

如果意外获得远程 shell，请立即断开并私下向运营方报告配置问题。

## 开发与测试

测试套件只使用本地模拟程序，不会建立网络连接：

```bash
./tests/test.sh
```

## 许可证

MIT。首次公开发布前，权利人必须确认版权声明和许可证。
