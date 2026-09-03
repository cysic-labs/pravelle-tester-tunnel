# Pravelle 测试隧道

这是一个体积小、便于审计的 SSH 客户端，用于让已获授权的 Pravelle
测试参与者建立两个仅绑定本机回环地址的端口转发。

本项目只包含客户端隧道工具，不包含 Pravelle 合约、证明器或撮合器源码、
部署地址、凭据、服务器配置或生产运维内容。

## 建立的转发

| 本地端点 | 远端端点 | 用途 |
| --- | --- | --- |
| `127.0.0.1:8798` | `127.0.0.1:8798` | Matcher API |
| `127.0.0.1:8799` | `127.0.0.1:8805` | Prover API（可用 `PRAVELLE_PROVER_PORT` 覆盖） |

两个本地端口都只监听 `127.0.0.1`，不会暴露给测试者所在的局域网。

## 使用条件

- macOS 或 Linux
- Bash
- OpenSSH 客户端
- 测试者本人生成并保存在本机的专用 SSH 私钥
- 运营方通过批准的私密渠道提供的受限 SSH 主机别名和 SHA256 主机指纹

远端账户必须由运营方在服务器端限制：禁止 shell、Agent/X11/TTY 转发，
并通过 `PermitOpen` 只允许访问上表中的两个回环服务。客户端脚本无法替代
这些服务器端限制。

## 一次性测试者接入

为本次测试生成新的、带口令的 Ed25519 密钥。不得复用钱包、Safe 签名者、
部署者、运营方或个人服务器密钥：

```bash
ssh-keygen -t ed25519 -a 64 -f ~/.ssh/pravelle-tester -C "pravelle-bsc-testnet"
chmod 600 ~/.ssh/pravelle-tester
```

只把 `~/.ssh/pravelle-tester.pub` 发给运营方。没有 `.pub` 后缀的文件是私钥，
必须始终留在测试者本机。运营方安装公钥后，应通过私密渠道返回：

1. 受限 SSH 别名及准确的 `HostName`、`User` 和可选 `Port`；
2. 预期的 SHA256 主机指纹，例如 `SHA256:REPLACE_WITH_OPERATOR_VALUE`；
3. 密钥启用和吊销时间。

首次连接前，先取得服务器公开的主机密钥，并与运营方通过独立渠道提供的指纹
逐字比较：

```bash
ssh-keyscan -t ed25519 PASTE_RESTRICTED_HOSTNAME > /tmp/pravelle-host-key
ssh-keygen -lf /tmp/pravelle-host-key
```

如果端口不是 22，在 `ssh-keyscan` 后添加 `-p PASTE_PORT`。只有显示的 SHA256
指纹完全一致时，才能安装主机密钥：

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -H -f /tmp/pravelle-host-key
grep -v '^#' /tmp/pravelle-host-key >> ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts
```

完成后删除 `/tmp/pravelle-host-key`。如果别名使用跳板机，必须分别核对跳板机和
最终主机的指纹。不得为了继续测试而接受未知或发生变化的主机密钥。

## 使用方法

```bash
chmod 600 ~/.ssh/pravelle-tester
./bin/pravelle-tester-tunnel restricted-test-host ~/.ssh/pravelle-tester
```

在已获授权的测试窗口内保持终端运行。需要停止时按 `Ctrl-C`。

该客户端会：

- 强制要求显式提供独立的测试者私钥；
- 拒绝权限不是 `0400` 或 `0600` 的私钥文件；
- 拒绝未知或发生变化的 SSH 主机密钥；
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
    IdentityFile ~/.ssh/pravelle-tester
    IdentitiesOnly yes
```

不要在该别名中添加 `LocalForward`、`RemoteForward` 或 `DynamicForward`。
所有允许的转发都由客户端脚本显式定义。`example.invalid` 只是占位符，不能用于
真实连接；运营方必须私下提供真实值。

启动隧道前确认端口未被占用：

```bash
# macOS
lsof -nP -iTCP:8798 -sTCP:LISTEN
lsof -nP -iTCP:8799 -sTCP:LISTEN

# Linux
ss -ltn '( sport = :8798 or sport = :8799 )'
```

没有输出表示端口空闲。不要结束不认识的进程；端口被占用时应停止并联系运营方。

## 验证发布包

当前版本为
[`v1.0.1`](https://github.com/cysic-labs/pravelle-tester-tunnel/releases/tag/v1.0.1)。
请同时下载源码压缩包和 `SHA256SUMS`，解压前先验证压缩包：

```bash
shasum -a 256 -c SHA256SUMS
tar -xzf pravelle-tester-tunnel-v1.0.1.tar.gz
cd pravelle-tester-tunnel-v1.0.1
```

进入解压后的目录，再验证所有受版本控制的文件并运行离线测试：

```bash
shasum -a 256 -c SHA256SUMS
./tests/test.sh
```

Linux 用户也可以使用 `sha256sum -c SHA256SUMS`。

## 安全边界

本工具本身不会授予任何访问权限。测试者生成密钥后，运营方只授权其公钥在限定
窗口内使用，并正确配置服务器端受限账户。

严禁：

- 使用 owner、deployer、operator 或 Safe 签名者私钥；
- 通过聊天、邮件、Issue 或截图发送私钥；
- 接受与运营方交接值不完全一致的 SSH 指纹；
- 将真实私钥或 SSH 主机配置提交到仓库；
- 在 SSH 账户意外打开远程 shell 后继续操作。

如果意外获得远程 shell，请立即断开并私下向运营方报告配置问题。

## 开发与测试

测试套件只使用本地模拟程序，不会建立网络连接：

```bash
./tests/test.sh
```

## 许可证

MIT。详见 [LICENSE](LICENSE)。
