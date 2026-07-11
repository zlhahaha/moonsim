# 示例索引

所有命令均从仓库根目录运行。示例会打印模型结果或报告，正常退出表示程序已完成；业务不变量的失败是否预期，以输出说明和对应测试为准。

| 命令 | 用途 | 预期重点 |
| --- | --- | --- |
| `moon run cmd/main` | HTTP retry/timeout showcase | 故障演示为 `invariant=fail（预期的故障演示）`，同 seed replay 为 `same_digest=yes`，修复后为 `invariant=pass`。 |
| `moon run examples/service_resilience` | 服务可靠性场景 | 观察 retry、timeout、熔断和不变量汇总。 |
| `moon run examples/workflow` | 工作流状态变化 | 观察虚拟时间下的事件顺序和状态转移。 |
| `moon run examples/seed_matrix` | 多 seed 探索 | 查看一批 seed 的通过/失败统计与可重放样本。 |
| `moon run cmd/benchmark` | 调度压力测量 | 输出 1k、10k、100k 事件的本机耗时、吞吐和 digest。 |

## 自定义 HTTP 记录

1. 用 `http_request`、`http_response` 和 `recorded_http_exchange` 表示真实测试采集的交换记录。
2. 用 `recorded_http_transport` 赋予记录一个场景名和可选的确定性变异选项。
3. 用 `http_reliability_policy` 定义 timeout、retry、deadline、限流和熔断策略。
4. 调用 `replay` 检查结果和 `invariants`；失败时调用 `failure_case` 保存证据。
5. 调整策略或业务模型后，用 `verify_fixed_policy` 和原 seed 验证回归。

完整代码与输出解释见 [HTTP 教程](tutorial.md)。
