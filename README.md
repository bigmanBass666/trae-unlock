# Trae Mod - 魔改 Trae IDE 项目

## 项目目标

探索和修改 Trae IDE 源码，解锁被限制的功能，实现更强大的自动化能力。

**参考 Issue**: [GUI mode lacks permission configuration equivalent to CLI's bypass_permissions mode](https://github.com/Trae-AI/TRAE/issues/2485)

## 为什么做这个？

Trae 是一个强大的 AI IDE，但某些功能在 GUI 模式下受到不必要的限制：

- ❌ 终端命令需要手动确认（即使开启了所有自动运行设置）
- ❌ 无法像 CLI 一样使用 `bypass_permissions` 模式
- ❌ 长时间 Agent 任务会被确认弹窗打断

本项目通过修改源码来解除这些限制。

## 探索成果

### 已完成

| # | 功能 | 文档 | 状态 |
|---|------|------|------|
| 1 | [绕过高风险命令确认](docs/bypass-security.md) | [bypass-security.md](docs/bypass-security.md) | ✅ 完成 |

### 待探索

- 自定义主题/光标样式
- 解除其他 UI 限制
- 插件系统扩展
- 性能优化
- 更多...

## 📚 文档索引

| 文档 | 内容 | 目标读者 |
|------|------|---------|
| [source-architecture.md](docs/source-architecture.md) | 完整源码架构、关键位置、搜索技巧 | **所有 AI（必读）** |
| [bypass-security.md](docs/bypass-security.md) | 安全模式绕过的具体方案和原理 | 想复现此功能的 AI |
| [progress.txt](progress.txt) | 项目进度简要记录 | 想了解当前状态的 AI |
| [agent.md](agent.md) | AI 协作规则和提交规范 | 参与本项目的 AI |

## 开发指南

### 修改源码步骤

1. **读源码架构**: 先看 `docs/source-architecture.md` 了解结构
2. **找到文件**: 使用搜索定位关键代码
3. **备份**: `[System.IO.File]::Copy(原文件, 备份路径, $true)`
4. **修改**: 直接编辑 JS 文件
5. **重启**: 关闭并重新打开 Trae 窗口
6. **测试**: 验证效果
7. **回滚**: 从备份恢复

### 注意事项

- Trae 安装在 `D:\apps\Trae CN\resources\app\`
- 应用是解包状态（没有 app.asar），直接编辑即可
- 由于沙箱限制，文件操作需用 `[System.IO.File]::Copy()` 而非 `Copy-Item`
- 修改后需重启窗口才能生效
- **每次有新发现必须更新 progress.txt 并 commit**

## 目录结构

```
trae-unlock/
├── docs/                           # 详细文档
│   ├── source-architecture.md      # ⭐ 源码架构探索记录（必读！）
│   └── bypass-security.md          # 安全模式绕过文档
├── progress.txt                    # 简要进度记录
├── agent.md                        # AI 协作规则
├── *.backup                        # 备份文件
└── README.md                       # 本文件
```

## 相关链接

- [Issue #2485](https://github.com/Trae-AI/TRAE/issues/2485) - GUI mode lacks permission configuration
- [Trae 官方文档](https://www.volcengine.com/docs/86677/2227872) - CLI bypass_permissions 说明
