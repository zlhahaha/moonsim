# 参与贡献

感谢你改进 moonsim。请使用当前稳定版 MoonBit，并从小而清晰的改动开始。

## 本地门禁

提交前依次运行：

```powershell
moon fmt
git diff --exit-code
moon check --deny-warn
moon build
moon info
git diff --exit-code
moon test --deny-warn
```

涉及展示或模型时，还应运行对应 example。涉及容量路径时运行 `moon run cmd/benchmark`；性能结果只作观测，不设置与机器绑定的耗时阈值。

## 新增模型的要求

新模型必须复用五类稳定事件，不为某项基础设施扩张 `EventKind`。每个模型至少提供一个明确的 invariant、一个可运行示例和覆盖核心失败路径的回归测试。外部系统应通过适配器映射为事件；核心包不得连接真实 HTTP、数据库或 MQ。

保持 0.3.x 公共 API 兼容。需要收敛旧入口时，先增加推荐入口、文档和迁移说明，不直接删除 facade。提交信息应描述一个功能、修复或文档主题；不要提交构建产物、本地工具配置或申报材料。

## 问题报告

确定性故障报告请附 seed、mutation policy、digest、失败 invariant、最小事件证据、MoonBit 版本和可复制命令。请勿附带凭据、生产数据或无法公开的日志。
