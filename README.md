# moonsim

**MoonBit 的通用确定性事件模拟与模型测试框架。**

`moonsim` 用同一套虚拟时间、固定 seed、可控变异、invariant、稳定 trace digest 和失败重放能力，测试消息、队列、任务编排、定时器、状态机与外部调用。它适合把偶发的延迟、丢失、重复、乱序和失败变成可复制的模型测试，并将修复策略固化为回归用例。

它不会连接真实 HTTP、数据库或消息队列，也不替代集成测试、端到端测试和生产监控。外部系统行为应由适配器记录，再进入确定性模型验证。

## 为什么需要 moonsim

分布式业务里最难复现的错误，往往不是某个函数算错，而是多个正确操作以意外顺序组合：确认包延迟导致重复投递、超时与成功同时发生、任务依赖尚未完成却被调度，或终态在重试后发生回退。真实时间测试通常运行慢且容易抖动；普通 mock 能替换依赖，却很难系统表达时间、因果关系和故障组合。

`moonsim` 的特殊价值是把这些条件压缩成一个可保存、可比较的确定性实验：

- **虚拟时间**：无需等待真实秒数，就能验证 timeout、backoff、deadline 和定时任务。
- **统一事件语言**：消息、任务、定时器、状态转移和外部调用共享 tick、因果关系、correlation ID 与 trace。
- **seed 驱动的故障空间**：延迟、丢弃、重复、同 tick 乱序和失败注入可以稳定复现，而不是依赖偶发竞态。
- **失败即证据**：失败结果携带 seed、触发的 invariant、事件证据与 digest，可直接 replay，也能固化为修复后的回归用例。
- **模型与基础设施解耦**：同一业务规则可以先在纯模型中快速探索，再由适配器接入记录下来的外部行为；核心不绑定 HTTP、数据库或 MQ 客户端。
- **MoonBit 原生公共 API**：模型、示例、测试与报告均可直接参与 MoonBit 项目的 `moon check`、`moon test` 和 CI，不需要跨语言测试进程。

它最适合测试“事件何时发生、以什么顺序发生、失败后系统是否仍满足规则”，而不是替代真实协议实现、吞吐压测或线上一致性验证。

## 与其他语言工具的关系

`moonsim` 借鉴了多个成熟方向，但选择的是它们之间尚未被单一工具覆盖的交集：确定性离散事件、故障变异、业务 invariant、失败重放和 MoonBit 原生集成。

| 工具或方向 | 擅长解决的问题 | 与 moonsim 的区别 |
| --- | --- | --- |
| Python `SimPy` | 用进程、资源和环境构建离散事件模拟 | `moonsim` 更聚焦软件系统事件、seed 故障变异、invariant、稳定 digest 与失败重放，而不是通用连续/流程仿真建模 |
| Java `DESMO-J`、`CloudSim` | 大型离散事件或云资源仿真 | `moonsim` 保持轻量，并面向消息、任务、状态机和外部调用的模型测试，不提供云基础设施模拟器 |
| Haskell `QuickCheck`、Python `Hypothesis` | 自动生成输入并缩小属性测试失败 | `moonsim` 当前不承诺通用生成器或自动 shrinking；它专注虚拟时间下的事件顺序、因果关系、故障策略和 seed replay |
| Jepsen 一类系统验证工具 | 对真实部署注入故障并检查分布式一致性 | `moonsim` 运行纯确定性模型，不控制真实集群，也不声称替代线上或集成级一致性测试 |
| 手写 mock、fake clock | 在单个测试中替换外部依赖或时间 | `moonsim` 将时间、事件类型、变异、trace、digest、invariant 和 replay 组织成可复用框架，减少每个项目重复搭建测试底座 |

因此，`moonsim` 的定位不是复刻某个外语库的全部功能，而是为 MoonBit 提供一个小而完整的“事件模型测试闭环”。如果问题只需要普通单元测试或一个 fake clock，直接使用更简单的方案更合适；如果需要从偶发时序故障追溯到同 seed 证据并持续回归，才是 `moonsim` 的主场。

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
