# Codex-Bridge 日常工作流

## 一句话总结

你写代码，我（CC/Opus）执行和修复，Codex 当 reviewer。别每次保存都 review，留着额度给真正重要的改动。

---

## 什么时候该用

| 场景 | 触发方式 |
|------|----------|
| 写完一个功能，准备提交前 | `review+fix` 或 "让 codex 看看" |
| 写完实现计划，想要 challenge | `/codex-plan-review` |
| 技术方案拿不定主意 | `bash scripts/codex-ask.sh . "你的问题"` |

## 什么时候别用

- 改了个 typo、调了下格式
- 纯配置文件改动（`.env`、`tsconfig` 之类）
- 探索性代码 / prototype
- diff 超大（>2000 行）——先拆小再 review
- 额度快用完了（看 `.codex-bridge/usage.log` 行数）

---

## 核心工作流：Code Review + Fix

这是你 90% 的使用场景。

### 流程

```
写代码 → 告诉我 "review+fix" → 我跑 codex-review → 展示 findings → 修 CRITICAL/WARNING → 再跑一轮验证 → 完事
```

### 具体步骤

1. **你写完代码**，跟我说 "review+fix" 或 "让 codex review 一下"
2. **我自动做这些事**：
   - 收集 git diff（脏文件，10 行上下文）
   - 过滤掉密钥/credentials（自动）
   - 发给 Codex sandbox（只读，120s 超时）
   - 拿回结构化 findings
3. **我展示结果**，你会看到：
   - `CRITICAL` — 必须修，不修不行
   - `WARNING` — 大概率要修，除非你有充分理由
   - `SUGGESTION` — 随你，参考就好
   - `VERDICT` — APPROVE / NEEDS_REVISION / CRITICAL_ISSUES
4. **我修 CRITICAL 和 WARNING**，SUGGESTION 会问你意见
5. **修完自动跑第 2 轮**（带上第 1 轮的完整 findings，让 Codex 验证修复）
6. **停止条件**（满足任一即停）：
   - Codex 给了 `APPROVE`
   - 连续两轮 findings 重叠 ≥50%（收敛了）
   - 跑满 3 轮

### 如果只想看不想自动修

跟我说 "dry run review" 或 "先看看 findings"，我会加 `--dry-run`，只展示不动手。

---

## Plan Review 工作流

写完实现计划后想让 Codex 挑毛病：

1. 你把计划告诉我（或者我帮你写完）
2. 我用固定模板整理：Goal / Constraints / Approach / Files Affected / Tradeoffs
3. 发给 Codex review，最多 5 轮自动迭代
4. 每轮我会把 Codex 的完整反馈附上（不是摘要），让它验证你是否真的改了

---

## 读懂输出

```markdown
## Findings
### [CRITICAL] SQL injection in user input handler
- File: src/db/query.ts
- Line: 42-45
- Issue: 直接拼接用户输入到 SQL
- Fix: 用 parameterized query

## Verdict
NEEDS_REVISION

## Summary
发现1个注入漏洞和2个类型安全问题...
```

**特殊情况**：
- 看到 `⚠️ TRUNCATED` → diff 太大被截断了，有些代码没被 review 到
- 看到 `RAW OUTPUT (unstructured)` → Codex 没按格式输出，当 WARNING 级别参考

---

## 常见坑

1. **别盲目采纳所有建议**
   Codex 有时候会提过度工程的建议。SUGGESTION 级别的你可以直接忽略。

2. **大 diff 先拆**
   超过 2000 行会被截断。先 commit 一部分，分批 review。

3. **Conflict Escalation**
   如果我觉得某个 fix 没必要但 Codex 标了 CRITICAL，我会明确告诉你我的理由，让你决定。不会偷偷跳过。

4. **额度意识**
   每次调用都计入 Codex 配额（ChatGPT Plus/Pro）。`usage.log` 记录了每次调用。一天别超过 ~20 次。

5. **密钥安全**
   脚本会自动过滤 `.env`、credentials、`password=` 之类的，但不会过滤你硬编码在代码里的 production 数据。注意别把真实数据留在 diff 里。

---

## 速查

| 你说 | 我做 |
|------|------|
| "review+fix" | 完整 review+fix 循环，最多 3 轮 |
| "让 codex 看看" | 同上 |
| "dry run review" | 只看 findings，不自动修 |
| "codex plan review" | 计划审查，最多 5 轮 |
| "问 codex ..." | 通用问答，sandbox 只读 |
| "别 review 了" | 停止迭代 |
