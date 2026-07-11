# moonsim

**MoonBit 的确定性模拟与模型测试工具。**

`moonsim` 用虚拟时间、固定 seed、事件轨迹和业务不变量，把 retry、timeout、迟到成功、限流和熔断等偶发可靠性问题变成可重复运行的模型案例。它适合在真实集成测试之前或之后，稳定地复现一个已经观察到的故障，并把修复过程沉淀为回归测试。

> Deterministic simulation and model testing for MoonBit.

## 它解决什么问题

一个常见的 HTTP 可靠性问题如下：请求超时后系统发起 retry，而第一次请求的迟到成功随后到达。如果只统计最终成功数，重复处理或截止时间后的成功可能被掩盖。wall-clock 测试通常难以稳定重现这类时序。

`moonsim` 让同一份记录在相同策略和 seed 下得到相同的事件顺序与 trace digest；当不变量失败时，可以保存失败 seed 和 HTTP 交换记录，调整策略后再用原 seed 回归验证。

它与其他生态的工具有相通之处：SimPy 强调离散事件模拟，属性测试和 fuzzing 用随机输入探索状态空间，FoundationDB 展示了确定性模拟对复杂系统测试的工程价值。`moonsim` 不重复实现这些生态，而是将虚拟时间、seed、trace、digest、invariant、replay 和可靠性模型组合为 MoonBit 可直接使用的工作流。

## 安装与最小示例

安装已发布的包：

```bash
moon add zlhahaha/moonsim
```

创建一个 MoonBit 包后，使用根包入口即可，不需要了解内部目录结构：

```moonbit
import { "zlhahaha/moonsim" }

fn main {
  let recording = @moonsim.retry_timeout_recording()
  let fault = @moonsim.retry_timeout_fault_policy()
  let result = recording.replay(policy=fault)

  println(
    "fault_invariant=" +
    (if result.invariants.passed() { "pass" } else { "fail" }),
  )
  println("trace_digest=" + result.digest.to_string())

  match recording.failure_case(policy=fault) {
    Some(evidence) => {
      let fixed = evidence.verify_fixed_policy(
        @moonsim.retry_timeout_fixed_policy(),
      )
      println(
        "fixed_invariant=" +
        (if fixed.invariants.passed() { "pass" } else { "fail" }),
      )
    }
    None => println("fault case was not reproduced"),
  }
}
```

该故障 fixture 有意允许迟到成功被接受，因此 `fault_invariant=fail` 是**预期的检测结果**，不是工具崩溃。修复策略会拒绝迟到成功，`fixed_invariant=pass`。同一 seed 的两次 replay digest 必须一致；不一致才表示确定性语义出现问题。

## HTTP 记录与重放

`moonsim` 不在库内发起真实 HTTP 请求。真实集成测试、日志采集或外部适配器负责取得请求和结果，再将它们表示为 `RecordedHttpExchange`。`RecordedHttpTransport` 在虚拟时间中回放记录，并可通过固定 seed 注入延迟、连接失败或同 tick 顺序变异。

可靠性策略包含 timeout、retry/backoff、业务 deadline、限流和熔断参数。结果明确区分 HTTP 成功、截止时间内成功、迟到成功、重复处理、超时和取消。`to_json()` 会输出稳定的 JSON 证据，便于保存场景名、seed、请求/响应摘要、失败规则与 digest。

详细的故障复现流程见 [教程](docs/tutorial.md)，公开 API 见 [API 文档](docs/api.md)。

## 运行展示与示例

```bash
moon run cmd/main
moon run examples/service_resilience
moon run examples/workflow
moon run examples/seed_matrix
moon run cmd/benchmark
```

`cmd/main` 依次展示问题、故障记录重放、预期的不变量失败、同 seed digest 对比、修复后的回归结果和 seed matrix。基准命令输出 1k、10k、100k 事件的本机测量数据及 digest；不同机器的耗时不应直接比较。

更多示例及其预期输出见 [示例索引](docs/examples.md)。

## 包结构

- 根包 `zlhahaha/moonsim`：稳定 facade，适合大多数应用和教程。
- `core/`：虚拟时间、稳定事件调度、随机数、trace、snapshot 和 invariant。
- `models/`：服务可靠性、HTTP 记录重放、queue、retry、network 和状态机模型。
- `reports/`：实验、seed matrix、timeline 和文本报告。

调度器使用稳定最小堆，事件排序语义固定为 `(tick, priority, id)`。取消、snapshot/restore 和同 tick 事件顺序都有回归测试，以保证 replay 的结果可解释。

## 验证

在仓库根目录执行：

```bash
moon fmt
moon check --deny-warn
moon build
moon info
git diff --exit-code
moon test --deny-warn
moon run cmd/main
```

`moon fmt` 与 `moon info` 会检查并可能刷新格式或 `pkg.generated.mbti`；在这些变更提交后，`git diff --exit-code` 应保持通过。GitHub Actions 在 Ubuntu、macOS 和 Windows 上执行格式化、检查、构建、接口信息、测试、展示程序和代表性示例。

## 适用边界

`moonsim` 用于验证逻辑模型、故障流程和策略语义。它不驱动真实 HTTP 服务、数据库或部署环境，也不应被当作端到端测试的替代品。模型测试通过说明指定模型和不变量通过；真实系统仍应保留集成测试、端到端测试和运行时监控。

## 许可证

本项目采用 [Apache License 2.0](LICENSE)。
