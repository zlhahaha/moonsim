# 教程：复现 retry/timeout 的迟到成功

本教程使用 `moonsim` 自带的 HTTP 记录，演示如何把一个偶发的 retry/timeout 问题变成稳定的回归案例。示例不发起真实网络请求；真实测试采集到的请求和结果同样可以构造成 `RecordedHttpExchange` 后使用这套流程。

## 1. 基线运行

先使用修复后的策略。它拒绝业务 deadline 之后到达的成功，并保证每个请求只会被最终分类一次。

```moonbit
import { "zlhahaha/moonsim" }

fn main {
  let recording = @moonsim.retry_timeout_recording()
  let fixed = @moonsim.retry_timeout_fixed_policy()
  let result = recording.replay(policy=fixed)
  println("seed=" + fixed.seed.to_string())
  println("digest=" + result.digest.to_string())
  println(
    "invariant=" +
    (if result.invariants.passed() { "pass" } else { "fail" }),
  )
}
```

预期结果为 `invariant=pass`。记录中仍可能有 timeout 或迟到响应，但策略不会把它们错误地计入业务成功。

## 2. 复现故障配置

故障策略有意允许迟到成功被接受。第一次请求超时后 retry 被安排，原请求的迟到成功到达后可能与 retry 的结果发生重复归类。

```moonbit
let recording = @moonsim.retry_timeout_recording()
let fault = @moonsim.retry_timeout_fault_policy()
let result = recording.replay(policy=fault)

println("seed=" + fault.seed.to_string())
println("digest=" + result.digest.to_string())
println(
  "invariant=" +
  (if result.invariants.passed() { "pass" } else { "fail" }),
)
println(recording.to_json(policy=fault))
```

这里的 `invariant=fail` 是**预期的故障演示**：模型发现了 `http_request_finalized_once` 规则被违反。命令正常退出不代表规则通过；它表示工具已经将故障变成可检查的证据。JSON 包含场景名、seed、HTTP 请求/响应摘要、事件时间、失败规则和 digest。

## 3. 使用固定 seed 重放

同一个记录、策略和 seed 必须得到相同 digest：

```moonbit
let first = recording.replay(policy=fault)
let second = recording.replay(policy=fault)
println(
  "same_digest=" +
  (if first.digest == second.digest { "yes" } else { "no" }),
)
```

预期 `same_digest=yes`。若相同输入的 digest 不一致，才是确定性模拟实现需要修复的问题。固定 seed 让失败事件顺序可以稳定地进入测试和代码审查，而不是依赖一次偶然的 wall-clock 时机。

## 4. 用原失败 seed 做修复回归

从故障运行提取 `HttpFailureCase`，再用修复策略重放。这个过程不更换 seed，因此它验证的是原始失败样本是否真正被修复。

```moonbit
match recording.failure_case(policy=fault) {
  Some(evidence) => {
    let repaired = evidence.verify_fixed_policy(
      @moonsim.retry_timeout_fixed_policy(),
    )
    println(
      "fixed_invariant=" +
      (if repaired.invariants.passed() { "pass" } else { "fail" }),
    )
  }
  None => println("fault case was not reproduced"),
}
```

预期 `fixed_invariant=pass`。最后应再运行多个 seed 的矩阵，而不是只验证一个样本。仓库中的 `cmd/main` 会展示这个完整流程；`examples/seed_matrix` 展示更一般的 seed 扫描工作流。

## 将真实记录接入模型

外部测试或日志收集器负责将真实调用映射成以下信息：请求 id、method、path、开始 tick、响应或连接失败、延迟 tick。再创建 `RecordedHttpExchange` 和 `RecordedHttpTransport`，以与本教程相同的方式调用 `replay`、`failure_case` 和 `to_json()`。

这层分工保持了模型的可控性：真实系统负责发现和采集行为，`moonsim` 负责确定性重放、变异和不变量验证。
