# 测试与质量检查

在提交代码前，从仓库根目录运行以下命令：

```bash
moon fmt
moon check --deny-warn
moon build
moon info
moon test --deny-warn
moon run cmd/main
moon run examples/service_resilience
moon run examples/workflow
moon run examples/seed_matrix
moon run cmd/benchmark
git diff --check
```

`moon fmt` 和 `moon info` 会把格式化结果和 `pkg.generated.mbti` 写入工作区。确认这些预期变更已经提交后，再执行：

```bash
git diff --exit-code
```

这一步验证格式和接口信息生成后仓库保持一致。

## CI

GitHub Actions 在 Ubuntu、macOS、Windows 三个平台执行以下流程：

1. `moon version --all`
2. `moon fmt`
3. `moon check --deny-warn`
4. `moon build`
5. `moon info` 与 `git diff --exit-code`
6. `moon test --deny-warn`
7. `moon run cmd/main` 与代表性示例 smoke
8. Linux coverage summary

CI 中 `moon fmt` 与 `moon info` 后的 diff 检查意味着格式或生成接口文件没有提交时会直接失败。

## 覆盖重点

测试覆盖核心路径，包括：

- 固定 seed 与配置得到相同 trace digest；
- retry 上限、timeout、取消、限流、熔断和业务 deadline；
- 迟到成功不被错误接受、请求只被最终分类一次；
- HTTP 记录 JSON 的转义与稳定重放；
- 原失败 seed 在修复策略下的回归；
- 同 tick 事件、取消事件、snapshot/restore 的稳定顺序；
- 至少 10,000 个事件的调度压力 smoke。

`cmd/benchmark` 是本机可复现测量工具，不在 CI 中设置耗时阈值。性能受机器、MoonBit 工具链和运行环境影响，应比较相同环境下的多次结果，而不是将不同机器的数值作为排名依据。

## 如何解释失败

`cmd/main` 中的 `invariant=fail（预期的故障演示）` 表示模型成功找到了教学场景的业务规则违规，命令仍会正常完成。以下情况才属于需要修复的质量问题：

- 相同记录、策略和 seed 的 replay digest 不一致；
- `moon check`、`moon build`、`moon test` 或 CI 失败；
- `moon info` 或 `moon fmt` 后存在未提交的生成/格式差异；
- 预期通过的修复策略在原失败 seed 上仍然失败。
