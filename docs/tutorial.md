# 教程：从重复投递到可重放回归

本教程以消息队列重复投递为主线。目标不是连接真实 MQ，而是把已经观察到的业务事实记录为确定性事件，并验证“每条消息最终分类一次”。

1. 创建 `EventStream`，用同一个 `correlation_id` 记录 `message.produce`、`message.deliver`、`ack.timeout`、`message.retry` 与 `message.ack`。
2. 用 `parent_id` 保留生产、投递、超时和重试的因果关系；tick 使用虚拟时间。
3. 创建固定 seed 的 `EventMutationPolicy`，注入延迟、丢弃、重复、同 tick 乱序或失败。
4. 从 `EventReplayResult.events` 统计每个 correlation 的确认、死信和重试次数，检查：最终分类恰好一次、确认前不丢失、重试不超过上限。
5. 发现失败后保存 `EventFailureCase`。其 `seed`、`rule`、`digest`、事件证据和策略可用于 `replay()`。
6. 调整策略或业务模型，再使用原 seed 回归；同 seed、同输入、同策略必须得到同 digest。

完整可运行代码见 `examples/queue`。任务超时与依赖保护采用相同流程，见 `examples/workflow`。

运行故障版本时，`FAIL (expected finding)` 表示 invariant 按预期抓到了模型缺陷，进程会正常退出；修复策略必须用同一 seed 回归并得到稳定 digest。真实回归失败应由 `moon test` 捕获，而不能伪装成展示结果。

## HTTP 扩展案例

真实集成测试或日志采集可以把请求/响应转换为 `RecordedHttpExchange`。`RecordedHttpTransport` 在虚拟时间中重放记录，并映射为 `ExternalCall` 事件。它是兼容适配器，不会发起真实 HTTP 请求，参见 `examples/service_resilience` 与 `cmd/main` 的最后一节。
