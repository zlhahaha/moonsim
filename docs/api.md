# API 概览

大多数用户只需导入根包：

```moonbit
import { "zlhahaha/moonsim" }
```

根包提供稳定 facade；内部的 `core`、`models` 和 `reports` 包用于按领域组织实现，不要求普通用户直接依赖。

## core：确定性执行内核

- `Sim`：虚拟时间模拟器，负责事件安排、执行、trace 与 digest。
- 事件顺序：严格按 `(tick, priority, id)` 排序；同 tick 的结果稳定可解释。
- snapshot/restore：保存待执行事件和取消状态，恢复后相同后续输入应得到相同 digest。
- `InvariantReport`：收集业务规则，通过 `passed()` 判断是否全部满足。

调度器使用私有稳定最小堆。其实现细节不属于用户 API，但取消事件、同 tick 优先级和恢复后的顺序均有测试覆盖。

## models：HTTP 可靠性记录与重放

### 基本类型

- `HttpRequest`：`id`、`http_method`、`path`、`attempt`。
- `HttpResponse`：HTTP `status` 与 `body_summary`。
- `HttpOutcome`：`Response`、`ConnectionFailure` 或 `Cancelled`。
- `RecordedHttpExchange`：一次请求的开始 tick、延迟和结果。

使用构造函数创建这些值：`http_request`、`http_response`、`recorded_http_exchange`。

### 传输记录与策略

`RecordedHttpTransport` 表示一个命名场景及其交换记录：

```moonbit
let transport = @moonsim.recorded_http_transport(
  "checkout-timeout",
  exchanges,
  options=@moonsim.http_replay_options(latency_jitter=1),
)
```

`HttpReliabilityPolicy` 由 `http_reliability_policy` 创建，配置 `seed`、timeout、retry limit、backoff、每 tick 限流、熔断阈值/恢复时间、业务 deadline 和 `accept_late_success`。`HttpReplayOptions` 可以用固定 seed 对延迟、连接失败百分比和同 tick 顺序进行确定性变异。

调用 `transport.replay(policy=...)` 返回 `HttpReplayResult`，其中包括：

- `http_successes`、`on_time_successes`、`late_successes`；
- `timed_out`、`connection_failures`、`cancelled`、`deadline_misses`；
- `duplicate_processed`、`retry_limit_violations`、`rate_limited`、`circuit_rejected`；
- `invariants`、`trace` 与 `digest`。

`transport.to_json(policy=...)` 输出稳定的 JSON 证据。它仅序列化模型记录，不进行真实网络 I/O。

### 失败证据与回归

`transport.failure_case(policy=...)` 在有不变量失败时返回 `HttpFailureCase`。该对象保存场景、原策略、seed、失败规则、digest、交换记录和重放选项：

- `evidence.replay()`：用原配置稳定重放。
- `evidence.verify_fixed_policy(policy)`：用修复策略和原失败 seed 回归。

`retry_timeout_recording()`、`retry_timeout_fault_policy()` 和 `retry_timeout_fixed_policy()` 是可运行的教学 fixture，也可作为自定义记录的参照。

## reports：实验结果

报告层提供 experiment、seed matrix、feature matrix、timeline 和文本渲染能力。它们用于将一批确定性运行汇总为可读结果；具体用法可见 [示例索引](examples.md)。

## 设计边界

这些 API 描述逻辑模型而非真实客户端。请在真实 HTTP、数据库或端到端测试之外使用它们，作为可复现故障、策略验证和回归测试的补充。
