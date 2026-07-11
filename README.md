# moonsim

**MoonBit 的通用确定性事件模拟与模型测试框架。**

`moonsim` 用同一套虚拟时间、固定 seed、可控变异、invariant、稳定 trace digest 和失败重放能力，测试消息、队列、任务编排、定时器、状态机与外部调用。它适合把偶发的延迟、丢失、重复、乱序和失败变成可复制的模型测试，并将修复策略固化为回归用例。

它不会连接真实 HTTP、数据库或消息队列，也不替代集成测试、端到端测试和生产监控。外部系统行为应由适配器记录，再进入确定性模型验证。

## 安装与最小示例

```bash
moon add zlhahaha/moonsim
```

普通用户只需导入根包：

```moonbit
import { "zlhahaha/moonsim" }

fn main {
  let stream = @moonsim.event_stream()
  let sent = stream.record(
    @moonsim.message_event_kind(), 0, "message.send",
    correlation_id="order-42", source="producer", target="worker",
  )
  ignore(stream.record(
    @moonsim.task_event_kind(), 3, "task.complete",
    correlation_id="order-42", parent_id=sent.id,
  ))

  let policy = @moonsim.event_mutation_policy(
    seed=2026UL, duplicate_percent=100,
  )
  let result = stream.replay(policy)
  let failure = @moonsim.event_failure_case(
    "order_completed_once", stream, policy,
  )
  let replay = failure.replay()
  println("failed_rule=" + failure.rule)
  println("digest=" + result.digest.to_string())
  println("same_seed=" + result.matches_digest(replay).to_string())
}
```

业务 invariant 可以根据 `EventReplayResult.events` 检查最终分类次数、确认前是否丢失、重试上限、依赖顺序与终态保护。框架同时提供事件结构自身的因果与时间检查。

## 稳定事件类型

- `Message`：发送、投递、确认、重试、死信等消息事实。
- `Task`：任务就绪、开始、完成、失败、取消与依赖阻塞。
- `Timer`：超时、定时触发、退避和 deadline。
- `StateTransition`：状态机接受或拒绝的转移。
- `ExternalCall`：HTTP 等外部交互的记录；不代表真实网络客户端。

未来的 Queue、数据库和 MQ 能力应作为适配器或上层模型扩展，不进入核心枚举，也不让核心包绑定具体基础设施。

## 旗舰场景

```bash
moon run examples/queue
moon run examples/workflow
moon run cmd/main
```

`examples/queue` 展示生产、投递、确认超时、重试、重复投递故障、失败 seed 重放与修复策略。`examples/workflow` 展示依赖任务、故障注入、终态 invariant 和同 seed 重放。展示中的 `FAIL (expected finding)` 表示模型按预期发现业务规则被违反，命令仍正常退出。

## 外部调用适配

现有 `RecordedHttpTransport` 和 HTTP reliability API 保持兼容，但 HTTP 只是 `ExternalCall` 的适配示例。库内不发起真实请求；适配器负责把调用事实表示为记录，通用事件流负责确定性排序、证据和 digest。

## 包结构与稳定性

- 根包 `zlhahaha/moonsim`：常用稳定 facade。
- `core/`：虚拟时间、类型化事件流、seed、变异、snapshot、invariant 与 replay。
- `models/`：消息、队列、任务、状态机和外部调用模型。
- `reports/`：实验、seed matrix、timeline 与文本报告。

`EventKind` 的五种内置类型和根包入口属于 0.3.x 公共边界；具体模型字段与进阶包可继续演进。详见 [API 文档](docs/api.md) 与 [教程](docs/tutorial.md)。

## 本地验证

```bash
moon fmt
moon check --deny-warn
moon build
moon info
git diff --exit-code
moon test --deny-warn
moon run cmd/main
moon run examples/queue
moon run examples/workflow
moon run examples/service_resilience
moon run cmd/benchmark
```

benchmark 保留 1k、10k、100k 事件测量；不同机器的耗时不可直接比较。项目采用 [Apache License 2.0](LICENSE)。
