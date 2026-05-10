# Local-Stream-Adapter 开发成果汇报

## 项目概述

**项目名称**: Local-Stream-Adapter（本地测试流媒体协议适配网关）
**项目路径**: `d:\Test\trae-unlock\local-stream-adapter\`
**语言/运行时**: Go 1.21+（实际编译环境 Go 1.26.2）
**当前状态**: 三个核心模块全部实现完毕，server 模式已验证可启动

---

## 模块交付清单

### 模块 1：本地 LevelDB 状态读取器 — `reader.go`

| 导出函数 | 签名 | 说明 |
|----------|------|------|
| `CopyDir` | `(src, dst string) error` | 递归复制目录，用于绕过 LevelDB 文件锁 |
| `ExtractKeys` | `(dbPath string, prefixes []string, useTemp bool) ([]KV, error)` | 核心读取函数，按前缀遍历 LevelDB |
| `PrintResults` | `(results []KV)` | 格式化输出 Key-Value |

**关键设计决策**:
- 文件锁处理策略：`useTemp=true` 时先 `CopyDir` 到系统临时目录，读取完毕后 `RemoveAll` 清理，避免与正在运行的进程冲突
- 前缀遍历使用 `util.Range{Start: prefix, Limit: prefix+"\xff"}`，精确匹配前缀边界
- 默认路径 `~/.config/MyApp/Local Storage/leveldb`，默认前缀 `auth_,session_`
- 配置通过环境变量注入：`LEVELDB_PATH`、`LEVELDB_PREFIX`、`LEVELDB_USE_TEMP`

**数据结构**:
```go
type KV struct {
    Key   string
    Value string
}
```

---

### 模块 2：企业级自适应 HTTP 客户端 — `client.go`

| 导出函数 | 签名 | 说明 |
|----------|------|------|
| `NewChromeClient` | `() *http.Client` | 返回配置了 Chrome TLS 指纹的 HTTP Client |
| `DoRequest` | `(client *http.Client, url string, headers map[string]string) (string, error)` | GET 请求 + 自定义 Header |
| `DoPostRequest` | `(client *http.Client, url string, headers map[string]string, body io.Reader) (*http.Response, error)` | POST 请求，供 SSE 模块使用 |

**关键设计决策**:
- TLS 指纹：使用 `utls.HelloChrome_Auto` 模拟最新版 Chrome 的 ClientHello，确保通过内网 WAF
- 自定义 `DialTLSContext`：替换标准库的 `tls.Dial`，底层用 `utls.UClient` 完成握手
- 禁用 HTTP/2（`ForceAttemptHTTP2: false`），避免 ALPN 协商导致指纹不一致
- SNI 从目标地址自动提取，`InsecureSkipVerify: false` 保持安全验证
- `DoPostRequest` 返回原始 `*http.Response`（不读 body），支持流式读取场景

---

### 模块 3：SSE 协议转换引擎 — `server.go`

| 端点 | 方法 | 说明 |
|------|------|------|
| `127.0.0.1:8317/v1/adapter` | POST | SSE 协议适配器（核心） |
| `127.0.0.1:8317/health` | GET | 健康检查 |

**请求格式**（`/v1/adapter`）:
```json
{
  "headers": {
    "Authorization": "Bearer xxx",
    "X-Custom": "value"
  },
  "body": "request payload"
}
```

**SSE 转换逻辑**:
1. 接收客户端 POST 请求，解析 JSON body
2. 使用模块 2 的 `NewChromeClient()` 向上游发起 POST 请求
3. 逐行扫描上游 SSE 流（`event:` / `data:` / 空行分隔）
4. 将每个 SSE 事件封装为 JSON 格式输出：

```json
{
  "id": "1",
  "event": "message",
  "data": <原始 data，若为合法 JSON 则解析为对象，否则保留字符串>
}
```

5. 通过 `http.Flusher` 实时推送，客户端可逐事件接收

**关键设计决策**:
- `WriteTimeout: 0`：SSE 长连接场景不能设写超时
- `Scanner` 缓冲区 1MB：支持上游单行数据较大的场景
- `parseDataField`：智能判断 data 字段是否为 JSON，是则解析为结构化对象，否则保留原始字符串
- 上游地址通过 `UPSTREAM_URL` 环境变量配置，默认 `https://api.internal.com/v1/stream`
- 监听地址通过 `LISTEN_ADDR` 环境变量配置，默认 `127.0.0.1:8317`

---

## 统一入口 — `main.go`

```bash
local-stream-adapter module1   # 运行 LevelDB 读取器
local-stream-adapter module2   # 运行 Chrome TLS Client 演示
local-stream-adapter server    # 启动 SSE 适配网关服务器
```

---

## 依赖清单

| 依赖 | 版本 | 用途 |
|------|------|------|
| `github.com/syndtr/goleveldb` | v1.0.0 | LevelDB 读取（模块1） |
| `github.com/refraction-networking/utls` | v1.6.7 | TLS 指纹模拟（模块2） |

间接依赖：`cloudflare/circl`、`golang/snappy`、`klauspost/compress`、`andybalholm/brotli`、`golang.org/x/crypto`、`golang.org/x/sys`

---

## 验证结果

| 验证项 | 结果 |
|--------|------|
| `go mod tidy` | ✅ 依赖下载成功，无冲突 |
| 编译 | ✅ 通过 |
| `server` 模式启动 | ✅ 监听 `127.0.0.1:8317` |
| `/health` 端点 | ✅ 返回 `{"status":"ok","timestamp":"2026-04-28T07:43:49+08:00"}` |
| `/v1/adapter` 端点 | ⚠️ 功能完整，但上游 `api.internal.com` 为内网地址，无法端到端验证 |

---

## 环境说明

- Go 通过 `winget install GoLang.Go` 安装，版本 1.26.2
- Trae IDE 的 `go` PowerShell 函数会遮蔽真正的 Go 命令，需使用完整路径 `"C:\Program Files\Go\bin\go.exe"` 调用
- 运行命令示例：
  ```powershell
  & "C:\Program Files\Go\bin\go.exe" run -C d:\Test\trae-unlock\local-stream-adapter . server
  ```

---

## 后续可扩展方向

1. **模块 1 增强**：支持 LevelDB 写入/删除操作，支持 batch 操作
2. **模块 2 增强**：支持更多 TLS 指纹（Firefox/Safari），支持代理链，支持连接池复用
3. **模块 3 增强**：添加请求限流、认证中间件、Prometheus 指标、优雅关机（graceful shutdown）
4. **集成测试**：搭建 mock 上游 SSE 服务器，编写端到端测试
5. **配置管理**：从 YAML/TOML 配置文件读取参数，替代纯环境变量
