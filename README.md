# moonsim

**MoonBit 的通用确定性事件模拟与模型测试框架。**

`moonsim` 用同一套虚拟时间、固定 seed、可控变异、invariant、稳定 trace digest 和失败重放能力，测试消息、队列、任务编排、定时器、状态机与外部调用。它适合把偶发的延迟、丢失、重复、乱序和失败变成可复制的模型测试，并将修复策略固化为回归用例。

从单条消息到完整任务链，`moonsim` 都能生成有序、可校验、可重放的事件证据。模型既可独立运行，也可接收适配器记录的外部行为，让同一套 invariant 同时服务于设计验证、故障复现和 CI 回归。

## 为什么需要 moonsim

分布式业务里最难复现的错误，往往不是某个函数算错，而是多个正确操作以意外顺序组合：确认包延迟导致重复投递、超时与成功同时发生、任务依赖尚未完成却被调度，或终态在重试后发生回退。真实时间测试通常运行慢且容易抖动；普通 mock 能替换依赖，却很难系统表达时间、因果关系和故障组合。

`moonsim` 的特殊价值是把这些条件压缩成一个可保存、可比较的确定性实验：

- **虚拟时间**：无需等待真实秒数，就能验证 timeout、backoff、deadline 和定时任务。
- **统一事件语言**：消息、任务、定时器、状态转移和外部调用共享 tick、因果关系、correlation ID 与 trace。
- **seed 驱动的故障空间**：延迟、丢弃、重复、同 tick 乱序和失败注入可以稳定复现，而不是依赖偶发竞态。
- **失败即证据**：失败结果携带 seed、触发的 invariant、事件证据与 digest，可直接 replay，也能固化为修复后的回归用例。
- **模型与基础设施解耦**：同一业务规则可以先在纯模型中快速探索，再由适配器接入记录下来的外部行为；核心不绑定 HTTP、数据库或 MQ 客户端。
- **MoonBit 原生公共 API**：模型、示例、测试与报告均可直接参与 MoonBit 项目的 `moon check`、`moon test` 和 CI，不需要跨语言测试进程。

它把“事件何时发生、以什么顺序发生、失败后系统是否仍满足规则”变成可编程、可重复执行的测试对象。

## 与其他语言工具的关系

`moonsim` 吸收了多个成熟工具方向中适合软件可靠性测试的能力，并在 MoonBit 中组合成统一闭环：确定性离散事件、故障变异、业务 invariant、稳定摘要、失败重放和 CI 集成。

| 工具或方向 | moonsim 已实现的同类能力 | moonsim 的组合增强 |
| --- | --- | --- |
| Akka TestKit | 消息探测、时序断言和失败路径验证 | 同一事件流还能表达任务、定时器、状态转移与外部调用，并保留跨组件因果关系 |
| Python `SimPy` | 虚拟时间、事件调度和确定性执行 | 面向软件可靠性直接提供 seed 变异、invariant、trace digest 与失败重放，无需自行拼装测试闭环 |
| Java `DESMO-J`、`CloudSim` | 离散事件排序、调度和容量场景运行 | 以轻量 MoonBit API 聚焦消息、工作流和状态机，可直接进入 `moon test` 与现有 CI |
| Haskell `QuickCheck`、Python `Hypothesis` | 用属性或 invariant 判断大量执行结果 | 失败证据同时保存 seed、策略、关键事件和 digest，可按原始时序精确 replay |
| Jepsen 风格模型验证 | 通过历史事件检查系统规则是否成立 | 在纯模型中快速枚举延迟、丢弃、重复、乱序和失败组合，适合在提交阶段高频回归 |
| 手写 mock、fake clock | 替换依赖、控制时间和构造异常返回 | 把时间、五类事件、因果关系、变异、证据与 replay 做成公共框架，减少重复测试基础设施 |

这些能力在其他生态中通常分散于模拟器、属性测试、消息测试工具和故障验证系统；`moonsim` 的优势是用一套类型化事件 API 把它们连起来。一次失败可以从变异策略进入 invariant，再生成 digest 与事件证据，最后按同一 seed 重放并固化为回归测试。这正是 MoonBit 项目此前需要自行搭建、而本包已经提供的完整能力。

## 安装与最小示例

下面的步骤从空目录创建独立项目，并使用 mooncakes.io 上的 `0.3.0`，不依赖本仓库源码：

```powershell
moon new moonsim-consumer
Set-Location moonsim-consumer
moon add zlhahaha/moonsim@0.3.0
```

在 `src/main/moon.pkg` 中声明根包依赖：

```moonbit
import {
  "zlhahaha/moonsim",
}
```

将 `src/main/main.mbt` 替换为：

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

运行：

```powershell
moon check --deny-warn
moon run src/main
```

输出中的 digest 是稳定整数；关键结果应为：

```text
failed_rule=order_completed_once
same_seed=true
```

业务 invariant 可以根据 `EventReplayResult.events` 检查最终分类次数、确认前是否丢失、重试上限、依赖顺序与终态保护。框架同时提供事件结构自身的因果与时间检查。

## 稳定事件类型

- `Message`：发送、投递、确认、重试、死信等消息事实。
- `Task`：任务就绪、开始、完成、失败、取消与依赖阻塞。
- `Timer`：超时、定时触发、退避和 deadline。
- `StateTransition`：状态机接受或拒绝的转移。
- `ExternalCall`：记录 HTTP、数据库或其他外部交互，并与内部事件共同排序和重放。

Queue、数据库和 MQ 可以通过适配器或上层模型映射到这五类稳定事件，因此新增基础设施不会破坏核心排序、digest 与 replay 语义。

## 能力与证据

| 能力 | 可运行证据 | 测试或文档证据 |
| --- | --- | --- |
| 五类事件、稳定排序与因果关系 | `moon run cmd/main` | [API 文档](docs/api.md)、`core/event_stream_test.mbt` |
| seed 变异、digest 与失败重放 | `moon run examples/queue` | `core/event_stream_test.mbt`、`models/event_stream_test.mbt` |
| 消息重复投递、确认、重试与死信 | `moon run examples/queue` | `models/event_stream_test.mbt` |
| 任务依赖、取消与终态保护 | `moon run examples/workflow` | `models/event_stream_test.mbt` |
| HTTP 记录重放兼容适配 | `moon run examples/service_resilience` | `models/event_stream_test.mbt`、[教程](docs/tutorial.md) |
| 10k smoke 与 1k/10k/100k 容量观测 | `moon run cmd/benchmark` | `core/event_stream_test.mbt` |

## 与 MoonBit 常规测试的关系

`moonsim` 不替代 `moon test`，而是作为测试代码中的模型层运行。普通单元测试适合验证一次函数调用；`moonsim` 补足跨虚拟时间、跨组件、带因果关系和故障注入的行为验证。模型发现的 seed 可以写回普通测试，让同一故障持续进入 CI。

典型场景包括消息可靠性、重试与超时、任务依赖、状态机、定时器、限流熔断以及外部调用记录重放。它专注模型测试；真实网络压测和生产基础设施运行由对应工具负责。

## 旗舰场景

```bash
moon run examples/queue
moon run examples/workflow
moon run cmd/main
```

`examples/queue` 展示生产、投递、确认超时、重试、重复投递故障、失败 seed 重放与修复策略。`examples/workflow` 展示依赖任务、故障注入、终态 invariant 和同 seed 重放。展示中的 `FAIL (expected finding)` 表示模型按预期发现业务规则被违反，命令仍正常退出。

## 外部调用适配

现有 `RecordedHttpTransport` 和 HTTP reliability API 保持兼容。它展示了如何把请求、响应、延迟和错误记录为 `ExternalCall`，再与消息、任务和定时器共享确定性排序、故障证据、digest 与 replay；同一模式也可扩展到数据库和 MQ 适配器。

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
- 许可证：[Apache-2.0](LICENSE)
- 兼容策略：0.3.x 保持根包 facade 和既有 examples 可用；API 收敛优先采用兼容新增与迁移说明。

Gitlink 镜像地址将在核验默认分支和提交历史一致后补入；在此之前不提供未经验证的链接。
