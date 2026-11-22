# Write less, enforce more: agent instruction files in late 2026

As of November 2026, the best practice for AGENTS.md and CLAUDE.md is a **short, factual, checkable file that holds only what the agent cannot work out from the repo**. That means exact build and test commands (including how to run a single test), places where the code is misleading, conventions that differ from the defaults (with the reason), operational warnings, and a few boundaries. Multi-step procedures go into skills, area-specific rules go into nested or path-scoped files, and anything that must never fail goes into hooks, permissions, linters or CI. The best controlled evidence shows that context files **reliably change behaviour but barely change success**. In Gloaguen et al.'s 438-task study, agents used a tool about 1.6 times per task when the file named it and almost never when it didn't. Developer-written files added only +2.4 pp of success (not significant), LLM-generated files cost −0.5 to −2 pp, and both raised inference cost by about 20–23%. The large wins come from information the model lacks, such as Vercel's 53% → 100% on post-training Next.js APIs, not from generic advice. The vendors (Anthropic, OpenAI, Cursor, GitHub, OpenCode) now agree on this. Anthropic's current docs explicitly retire 2025-era habits: IMPORTANT/ALL-CAPS emphasis, "think hard", "don't be lazy", architecture tours, and "use subagents to save context". For your global personal file, no single path is read by Claude Code, Codex, pi and OpenCode alike. Keep one plain-Markdown source and symlink or import it into each tool's location, and limit it to about 30–60 lines: communication preferences, when to ask before acting, git safety, environment facts, and three or four distinctive engineering habits. The viral "Boris Cherny CLAUDE.md" is a community reconstruction that Cherny never published. The "Karpathy guidelines" were written by a third party hours after a post in which Karpathy said CLAUDE.md instructions had *not* fixed these problems. Each offers one or two good ideas (concrete verification; small, surgical changes) wrapped in generic or outdated text. Finally, length limits like "under 200 lines" are vendor rules of thumb, not measured cut-offs. Two controlled studies found no effect of file length on success or adherence, so the case for brevity is cost and signal-to-noise.

## Context files steer behaviour far more than they raise success rates

The research base has matured since 2025, and its message is uncomfortable for template collectors. The most rigorous study is Gloaguen et al. (ETH Zurich/LogicStar, ICLR 2026, v3 revised 29 Sep 2026). It tested Claude Code + Sonnet 4.5, Codex + GPT-5.2 and GPT-5.1 mini, and Qwen Code on 300 SWE-bench Lite tasks plus 138 tasks from repos with developer-committed AGENTS.md files. **LLM-generated context files lowered success by 0.5–2 pp on average. Developer-written files raised it by 2.4 pp, not significant against having no file, but significantly better than LLM files (about 7 pp, p = 0.038). Both raised cost by about 20–23% and added steps** ([arXiv 2602.11988v3](https://arxiv.org/html/2602.11988v3)). Secondary coverage of earlier versions quotes "about 4%" for developer files. The v3 table says +2.4 pp, so cite v3. The same paper explains the mechanism. Agents are highly compliant: **`uv` was used 1.6× per instance when mentioned versus under 0.01 when not**, and repo-specific tools 2.5× versus under 0.05. Repository overviews, present in 95–100% of LLM-generated files, did not help agents reach the files a fix needed. And LLM-generated files helped (+2.7 pp) only once the repo's own docs were removed, which means duplicated information is wasted ([arXiv 2602.11988v3](https://arxiv.org/html/2602.11988v3)).

The other controlled studies point the same way and add useful detail. Lulla et al. ran Codex with gpt-5.2-codex on 124 PRs and found that a real AGENTS.md cut median wall-clock time by **28.6% and output tokens by 16.6%**, but they did not measure correctness ([arXiv 2601.20404v2](https://arxiv.org/html/2601.20404v2)). Khatri's 2026 two-agent ablation (Sonnet 4.6 and GPT-5.5, 288 runs) found no change in pass rate. It did find one telling effect: on a repo whose AGENTS.md warned that the full test suite takes over 20 minutes, Claude's blind full-suite runs fell from 3.67 to 1.67 and its time fell by about 24%. That result is exploratory, n = 4 ([arXiv 2607.27250](https://arxiv.org/html/2607.27250)). The largest gains come when the file supplies knowledge the model doesn't have. Vercel's compressed docs index for post-training Next.js 16 APIs took its evals from **53% to 100%**, and shrinking that index from 40 KB to 8 KB lost nothing. These are vendor evals with no model named ([Vercel, Jan 2026](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)). Guidance refined iteratively against probes beat both no guidance and a static knowledge base, 33.0% vs 25.5% vs 28.3%, though only on a small open model ([arXiv 2606.20512](https://arxiv.org/abs/2606.20512)).

On length, the evidence does **not** show adherence falling off a cliff at typical file sizes. McMillan's factorial study ran 1,650 Claude Code sessions on Sonnet 4.6 and Opus 4.6/4.7. It found **no detectable effect of file size, instruction position, file architecture or contradictions in neighbouring files** on adherence to a target rule, and Bayes factors of 0.05–0.10 actively support the nulls for size and conflict. The biggest effect was drift within a session: about 5.6% lower odds of compliance for each additional function generated ([arXiv 2605.10039](https://arxiv.org/abs/2605.10039)). Gloaguen likewise found "no clear correlation" between length and success or cost across files of 24–2,003 words ([arXiv 2602.11988v3](https://arxiv.org/html/2602.11988v3)). IFScale does show degradation, but only at hundreds of simultaneous instructions (top models near-perfect up to 100, 63–69% at 500), and it used mid-2025 models on a non-coding task ([arXiv 2507.11538](https://arxiv.org/html/2507.11538v1)). Widely shared numbers like "92% adherence under 200 lines vs 70% over 400" have no study you can find behind them ([DEV Community](https://dev.to/davekurian/your-claudemd-is-too-long-the-200-line-ceiling-that-actually-works-1fb0)). The practical lesson for your templates: **every line must earn its place by being non-discoverable and actionable**. Brevity matters because each line costs tokens and dilutes the useful ones, not because a 250-line file breaks. Long sessions, more than long files, are what erode compliance, so rules that truly matter need a deterministic backstop.

The evidence has real gaps. No study isolates individual content types such as do/don't lists, code examples or personas. Benchmarks are mostly Python bug fixes, not greenfield, multi-session or team-convention work, which is exactly where practitioners say the files matter most. No adequately powered study covers the newest frontier models. Every corpus study, including those covering about 17,000 real files, is descriptive only ([arXiv 2511.12884](https://arxiv.org/html/2511.12884v1); [arXiv 2512.18925](https://arxiv.org/html/2512.18925)).

## Fourteen pieces worth adopting, with wording and provenance

The table below collects the rules that survive scrutiny. "Evidence" is graded honestly: *measured* means a controlled study supports the mechanism, *vendor* means official documentation, and *practitioner* means converging expert practice with no outcome data. Rules P1–P8 belong in a project AGENTS.md. Rules G1–G6 belong in your global personal file.

| # | Piece | Suggested wording | Source and evidence |
|---|---|---|---|
| P1 | Exact commands, early, including single-test | `Test one file: pnpm vitest run path/to/file.test.ts` · `Typecheck: pnpm tsc --noEmit` | Anthropic calls the check command "the single most useful line" ([best practices](https://code.claude.com/docs/en/best-practices)). Named tools get used 1.6–2.5× vs ~0 (**measured**, [Gloaguen](https://arxiv.org/html/2602.11988v3)). Same advice from Willison ([Mar 2026](https://simonwillison.net/2026/Mar/14/pragmatic-summit/)) and Ghostty ([AGENTS.md](https://raw.githubusercontent.com/ghostty-org/ghostty/main/AGENTS.md)) |
| P2 | Operational cost warnings | `The full suite takes ~20 min. While iterating, run only the affected test file; run the full suite once before finishing.` | Blind full-suite runs dropped 3.67 → 1.67 and time fell ~24% (**measured, exploratory**, [Khatri](https://arxiv.org/html/2607.27250)) |
| P3 | "Done" defined as a command plus evidence | ``Done means `make check` passes and new behaviour has a test. Report the commands you ran and their result.`` | Codex lists "what 'done' means and how to verify work" ([Codex best practices](https://learn.chatgpt.com/docs/learn/best-practices)). Anthropic says to ask for evidence ([best practices](https://code.claude.com/docs/en/best-practices)). Cherny: verification gives "2-3x the quality" ([thread](https://threadreaderapp.com/thread/2007179832300581177.html)) |
| P4 | Misleading code | `src/legacy/ is still live, but don't copy its patterns into new code.` | Anthropic's official example, verbatim (**vendor**, [best practices](https://code.claude.com/docs/en/best-practices)) |
| P5 | Non-default conventions, each with a reason | `Use the error helpers in src/lib/errors.ts, never raw strings — the API layer maps them to HTTP codes.` | Gloaguen recommends files for "non-standard" practices. VS Code: give the reasoning so edge cases go right ([VS Code](https://code.visualstudio.com/docs/agent-customization/custom-instructions)) |
| P6 | Pointer index to information the model lacks | `Next.js 16 caching APIs post-date your training. Read docs/next16/INDEX.md before using 'use cache' or cacheLife.` | 53% → 100% (**measured, vendor eval**, [Vercel](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)). "Prefer pointers to copies" ([HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md)) |
| P7 | Environment gotchas | `Integration tests need DATABASE_URL; see .env.example.` · `Emails are written to log/mail.log, not sent.` | Anthropic example ([best practices](https://code.claude.com/docs/en/best-practices)). Ronacher's one CLAUDE.md line points at the email log ([lucumr, 2025](https://lucumr.pocoo.org/2025/6/12/agentic-coding/)) |
| P8 | Three-tier boundaries, mirrored in tooling | `Ask first: schema migrations, new dependencies. Never: edit vendor/, commit secrets (also blocked by pre-commit).` | Always / ask first / never, and "Never commit secrets" was the most common helpful constraint (**practitioner synthesis**, [GitHub blog](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)) |
| G1 | Answer before acting | `When I ask a question, answer it before making edits or running commands.` | pi-mono AGENTS.md ([Zechner](https://raw.githubusercontent.com/badlogic/pi-mono/main/AGENTS.md)) (**practitioner**) |
| G2 | Communication shape | `Lead with the conclusion, then the reasoning. No canned enthusiasm. When I give feedback, say whether you agree before saying what you changed.` | Steinberger ([agent-scripts](https://raw.githubusercontent.com/steipete/agent-scripts/main/AGENTS.MD)); pi-mono ([Zechner](https://raw.githubusercontent.com/badlogic/pi-mono/main/AGENTS.md)) |
| G3 | Ask thresholds set by reversibility | `Proceed on reversible, in-scope work. Ask before adding production dependencies, removing code that looks intentional, or any destructive git operation.` | Codex's own global example: "ask before adding production dependencies" ([Codex guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md)). pi-mono; Steinberger |
| G4 | Surgical, simple changes | `Make the smallest change that solves the request. Every changed line should trace to it. Mention unrelated problems; don't fix them. Remove only the orphans your change created.` | Karpathy-guidelines repo ([forrestchang](https://github.com/forrestchang/andrej-karpathy-skills/blob/main/CLAUDE.md)). Anthropic: "Only make changes that are directly requested or clearly necessary" ([prompting guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)) |
| G5 | Calibrated engineering check | `For any non-trivial plan, say whether it is over-engineered, under-engineered, or right, and why.` | Cherny's stated favourite line in his own CLAUDE.md (**secondary**, [Light Cone write-up](https://engineeredintelligence.substack.com/p/how-the-claude-code-team-works)) |
| G6 | Git hygiene for multi-agent checkouts | ``Stage explicit paths; never `git add -A` or `git add .`. Only commit files you changed in this session. Never commit, push or force-push unless asked.`` | pi-mono ([Zechner](https://raw.githubusercontent.com/badlogic/pi-mono/main/AGENTS.md)); Steinberger: "Destructive Git ops need explicit user request" ([agent-scripts](https://raw.githubusercontent.com/steipete/agent-scripts/main/AGENTS.MD)) |

Three more pieces are less a rule than a habit of style, and they apply to every line you write. First, **make rules concrete enough to verify**: "Use 2-space indentation" rather than "format properly", and "Run `npm test` before committing" rather than "test your changes" ([memory docs](https://code.claude.com/docs/en/memory)). Second, **name the exact stack and versions** when they aren't obvious ("React 18 with TypeScript, Vite, and Tailwind", not "React project") ([GitHub blog](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)). Third, **add a precedence line** to the global file. Claude Code concatenates user and project rules, and when they conflict "Claude may follow either one" ([memory docs](https://code.claude.com/docs/en/memory)). The pi-mono file handles this with "If the user's instructions conflict with any rule in this document, ask for explicit confirmation before overriding" ([pi-mono](https://raw.githubusercontent.com/badlogic/pi-mono/main/AGENTS.md)).

G4 has one caveat specific to your setup. Claude Code's own system prompt reportedly already contains lines like "Don't add features beyond what the task requires", but that claim comes from a GitHub discussion and is unverified ([discussion #1214](https://github.com/anthropics/claude-code-action/discussions/1214)). Pi deliberately keeps its system prompt plus tool definitions under about 1,000 tokens ([Zechner, Nov 2025](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/)). A tool-agnostic global file therefore has to make up for the *thinnest* harness you use. A few lines of engineering habits that are redundant in Claude Code can do real work in pi, and that is a sound reason to keep G4 despite the overlap.

## What to strip out, and why vendors now say so explicitly

The clearest change since 2025 is that Anthropic now publishes a "What you can stop doing" table, and much of the viral template content appears on it. **ALL-CAPS and IMPORTANT emphasis**: "Current ones follow a plainly worded line, and piling on emphasis mostly makes Claude over-apply the rule. If it's a rule that can't bend, turn it into a hook or a deny rule. If the line is getting lost in a long file, the file needs to be shorter" ([best practices](https://code.claude.com/docs/en/best-practices)). This reverses Anthropic's own April 2025 advice to use "IMPORTANT"/"YOU MUST"; that older post now redirects to the new page. OpenAI found the same with GPT-5: Cursor's "Be THOROUGH when gathering information" made the model overuse tools (archived guide, ~Aug 2025) ([OpenAI GPT-5 guide](https://developers.openai.com/cookbook/examples/gpt-5/gpt-5_prompting_guide)). **"Think hard", "be thorough", "keep going, don't be lazy"**: effort settings are the real control, and anti-laziness lines "are more likely to cause over-work than fix a stall" ([best practices](https://code.claude.com/docs/en/best-practices)). **"Use subagents to protect your context window"**: "Running out of context is rarely the problem anymore", and Opus 5 already "delegates to subagents more readily than prior models" ([best practices](https://code.claude.com/docs/en/best-practices); [prompting guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)).

Content can be dead weight too. **Architecture tours and directory trees** are on Anthropic's stop-doing list ("Claude reads the repo itself"), and Gloaguen measured that overviews did not speed up navigation ([best practices](https://code.claude.com/docs/en/best-practices); [arXiv 2602.11988v3](https://arxiv.org/html/2602.11988v3)). **Linter-enforceable style** belongs to the linter: "Never send an LLM to do a linter's job" ([HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md)), echoed by Cursor, VS Code and Codex ("leave formatting and lint to CI") ([Cursor rules](https://cursor.com/docs/context/rules); [Codex guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md)). **Copied template boilerplate** is everywhere: 28.7% of all Cursor rule lines are exact duplicates across repos, and copied LLM-directive lines are the most duplicated of all ([arXiv 2512.18925](https://arxiv.org/html/2512.18925)). **Unedited `/init` or LLM-written files** carry the measured penalty described above. Use `/init` as a draft and expect that "the work is mostly removing lines" ([memory docs](https://code.claude.com/docs/en/memory)). **Status reports and progress logs** pollute a file that loads every session; Huntley's loop prompt states it bluntly: "DO NOT PLACE STATUS REPORT UPDATES INTO @AGENT.md" ([ghuntley.com, Jul 2025](https://ghuntley.com/ralph/)). **Rare edge cases** and **pasted docs** waste context ([Cursor rules](https://cursor.com/docs/context/rules)). **Contradictions** are the quietest failure: Claude "may pick one arbitrarily", and GPT-5 burns reasoning tokens trying to reconcile them ([memory docs](https://code.claude.com/docs/en/memory); [OpenAI GPT-5 guide](https://developers.openai.com/cookbook/examples/gpt-5/gpt-5_prompting_guide)).

Two items need care because the right answer depends on the model. **Generic "verify before done" exhortations** were essential in 2025. Anthropic now says that "Claude Opus 5 … verifies its own work well without explicit instruction, and verification instructions carried over from prompts tuned for earlier models can cause over-verification … remove these instructions rather than rewriting them" ([prompting guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)). Keep the *command* (P1, P3), which helps every model by naming the tool, and drop the sermon. **Personas** ("You are a senior engineer") have no outcome evidence for instruction files. GitHub's blog favours specialist personas, but that advice is about Copilot custom agents ([GitHub blog](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)). Anthropic endorses roles in *API system prompts* but not in CLAUDE.md ([prompting guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)). Finally, **tool-specific syntax in shared files** breaks portability. `@path` imports work in Claude Code and Gemini CLI but not in Codex or the agents.md standard ([memory docs](https://code.claude.com/docs/en/memory); [agents.md](https://agents.md/)).

## Where the sources genuinely disagree

The sources agree on direction and disagree on details. Most of the disagreements resolve once you see what each source was optimising for.

| Question | Position A | Position B | Resolution for your templates |
|---|---|---|---|
| How long? | Anthropic: under 200 lines per file ([memory](https://code.claude.com/docs/en/memory)); HumanLayer: <300, theirs <60 ([HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md)); GitHub: "two pages" | Cursor: under 500 lines ([Cursor](https://cursor.com/docs/context/rules)); Steinberger's global file and pi-mono run to about 2,000–2,500 words ([agent-scripts](https://raw.githubusercontent.com/steipete/agent-scripts/main/AGENTS.MD); [pi-mono](https://raw.githubusercontent.com/badlogic/pi-mono/main/AGENTS.md)) | No measured cut-off ([McMillan](https://arxiv.org/abs/2605.10039)). The one hard limit is Codex's 32 KiB combined cap ([Codex guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md)). Aim for about 60 lines global and about 150 project |
| Emphasis words | Anthropic: drop IMPORTANT/caps ([best practices](https://code.claude.com/docs/en/best-practices)) | GitHub: use "always" for required steps ([GitHub docs](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions)); superpowers uses all-caps "Iron Laws" ([superpowers](https://github.com/obra/superpowers)) | Plain "always"/"never" is fine. Never stack caps. A rule that keeps getting missed needs a hook, not volume |
| Architecture and layout | Anthropic best-practices and `/doctor`: cut it ([best practices](https://code.claude.com/docs/en/best-practices)) | Anthropic memory page still lists "project layout"; Codex and GitHub include it; Santos et al. favour specifying architecture ([arXiv 2511.09268](https://arxiv.org/abs/2511.09268)) | Measured data sides with cutting ([Gloaguen](https://arxiv.org/html/2602.11988v3)). Keep only the *non-obvious*: misleading dirs, generated code, where new code should go |
| Code examples | "One real code snippet … beats three paragraphs" ([GitHub blog](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)) | "Prefer pointers to copies" ([HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md)); Cursor: reference files, don't copy | Point to a real exemplar file (`see src/api/users.ts`). Inline snippets go stale |
| Ask or proceed? | Karpathy guidelines: "If something is unclear, stop … Ask" ([CLAUDE.md](https://github.com/forrestchang/andrej-karpathy-skills/blob/main/CLAUDE.md)); superpowers: nothing built before design approval | Karpathy's own autoresearch: "NEVER STOP … do NOT pause to ask" ([program.md](https://github.com/karpathy/autoresearch/blob/master/program.md)); Steinberger: plan only when asked, "otherwise proceed directly" | Depends on context. Set the threshold by reversibility and blast radius (G3), not by uncertainty in general |
| When to add a rule | Every correction (Cherny, [Jun 2026](https://howborisusesclaudecode.com/)); Huntley's "signs" | Second occurrence (Anthropic [memory](https://code.claude.com/docs/en/memory); Codex [best practices](https://learn.chatgpt.com/docs/learn/best-practices); Cursor) | Use the second-occurrence rule, plus a scheduled prune at each model generation |
| Who writes it | Anthropic, Codex and OpenCode ship `/init` generators | HumanLayer: "Don't use /init" ([HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md)); LLM files measured worse ([Gloaguen](https://arxiv.org/html/2602.11988v3)) | Generate, then cut by hand. Probe-and-refine beats one-shot generation ([arXiv 2606.20512](https://arxiv.org/abs/2606.20512)) |
| Hard rules in prose? | Codex lists "constraints and do-not rules" as content ([Codex best practices](https://learn.chatgpt.com/docs/learn/best-practices)) | Anthropic: if it must always happen, use a hook, deny rule or managed setting ([best practices](https://code.claude.com/docs/en/best-practices)) | Both. State it in the file (portable, and it explains why), then enforce it in git hooks or CI, which work in every tool |
| Always-on vs skills | Vercel: AGENTS.md index 100% vs default skill 53%; the skill was never invoked in 56% of cases ([Vercel](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)) | Anthropic and Codex: move procedures to skills | Keep an always-on one-line pointer ("for releases, use the release skill / read docs/release.md") and put the detail on demand |
| Net cost | +20–23% cost and more steps ([Gloaguen](https://arxiv.org/html/2602.11988v3)) | −29% runtime, −17% output tokens ([Lulla](https://arxiv.org/html/2601.20404v2)) | Different metrics. Targeted operational hints save time; generic "test/explore more" adds steps |
| Which file wins | Concatenate, nearer file later: Claude Code, Codex, Gemini | Closest wins: agents.md, Copilot; first match per category: OpenCode; earlier source wins: Cursor ([official notes](https://agents.md/); [OpenCode](https://opencode.ai/docs/rules/); [Cursor](https://cursor.com/docs/context/rules)) | Don't rely on precedence. Write global and project files that never conflict, and include an explicit "project overrides personal" line |

One more conflict affects you directly. Cherny's own advice has moved over the year. In January it was "anytime we see Claude do something incorrectly we add it to the CLAUDE.md" ([thread](https://threadreaderapp.com/thread/2007179832300581177.html)). By mid-2026 it was reportedly "delete your CLAUDE.md every 6 months" and re-add instructions one at a time when a new model struggles. That July 2026 report is **secondary** ([lucadidomenico.studio](https://lucadidomenico.studio/en/blog/delete-claude-md-every-6-months)). The often-repeated claim that Anthropic cut over 80% of Claude Code's system prompt for Opus 5 with no eval loss traces to a reported July 24, 2026 post. That post **does not appear in Anthropic's engineering index and is unverified** ([Anthropic engineering](https://www.anthropic.com/engineering)). The underlying idea, that instructions compensate for one model's weaknesses and go stale with the next, fits Anthropic's documented `/doctor prompt-audit`, which flags "instructions written for older models" ([memory docs](https://code.claude.com/docs/en/memory)).

## The viral templates offer two good ideas wrapped in borrowed authority

### The "Boris Cherny CLAUDE.md" is a fan reconstruction, not his file

**Cherny did not write, post or endorse the circulating file.** The earliest copies appear on 21–23 February 2026, framed honestly at first: "Someone turned it into a CLAUDE.md file" ([Hasan Toor on X](https://x.com/hasantoxr/status/2025851900911038603); [Srishti on X](https://x.com/srishticodes/status/2025254119636959701)). The gist titled "Boris Cherny's CLAUDE.md" (hqman, 23 Feb 2026, one revision) cites no primary source and still contains the typos "Plan Node Default", "One tack per subagent" and "Minimat Impact", which suggest hasty retyping rather than an export of a maintained file ([hqman gist](https://gist.github.com/hqman/e29cb6386c539d795767e8c3fd2c959b)). Later reposts dropped the caveat and turned it into lead-gen and paid guides ([leadgenman on Threads](https://www.threads.com/@leadgenman/post/DV8qbyoDQTY/the-founder-of-claude-code-boris-cherny-shared-his-personal-claude-md-file-the); [keshavsuki.com](https://keshavsuki.com/guides/boris-cherny-claude-md-file)). The Miles Deutscher post of 1 November 2026 that apparently revived it **could not be retrieved or verified**. What Cherny actually describes is structurally different. His team keeps **one shared, git-checked CLAUDE.md** that it updates through PRs ([thread, Jan 2026](https://threadreaderapp.com/thread/2007179832300581177.html)). His personal file is reportedly **two lines** (automerge, and posting PRs to a review channel). The team file is reportedly "a couple thousand tokens". Both of those details are **secondary** ([Light Cone write-up](https://engineeredintelligence.substack.com/p/how-the-claude-code-team-works)).

| Viral rule | Verdict | Why |
|---|---|---|
| Plan mode by default for 3+ step tasks; re-plan when off track | **Keep the idea, drop the trigger** | Cherny starts most sessions in plan mode ([thread](https://threadreaderapp.com/thread/2007179832300581177.html)), but "3+ steps" is arbitrary and plan mode is Claude-only (pi has none by design). Anthropic now prefers an interview → SPEC.md → fresh session for unclear work ([best practices](https://code.claude.com/docs/en/best-practices)) |
| Use subagents liberally; one task per subagent | **Drop** | Anthropic lists "subagents to protect your context" as outdated and says subagents can be slower and cost extra. Opus 5 already over-delegates ([best practices](https://code.claude.com/docs/en/best-practices); [prompting guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)) |
| Self-improvement loop: write `tasks/lessons.md` after *any* correction, review it at start | **Replace** | The threshold is "correct twice", not "any" ([best practices](https://code.claude.com/docs/en/best-practices)). Claude Code's auto memory already does this, capped at 200 lines/25 KB ([memory](https://code.claude.com/docs/en/memory)). An uncurated lessons file grows without limit and accumulates contradictions. Cherny's version is human-reviewed via PR |
| Verification before done; "would a staff engineer approve?" | **Keep, in concrete form** | Best-supported idea in the file ([Cherny](https://threadreaderapp.com/thread/2007179832300581177.html)). The prose version "works most of the time, not every time", so pair it with a Stop hook or `/code-review`. It may cause over-verification on Opus 5 ([best practices](https://code.claude.com/docs/en/best-practices); [prompting guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)) |
| Demand elegance (balanced) | **Drop** | Contradicts the file's own Simplicity and Minimal Impact rules and leaves the model to resolve the conflict. Anthropic warns current models already over-engineer ([prompting guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)) |
| Autonomous bug fixing: just fix failing CI, zero hand-holding | **Drop or scope tightly** | Autonomy is already the default (auto mode). "Fix CI" without scope limits invites test-gaming, which Anthropic warns about ("solutions that only work for specific test cases") |
| `tasks/todo.md` task management | **Harness-dependent** | Redundant with Claude Code's built-in task tracking. Useful in pi, whose author recommends a TODO.md/PLAN.md instead of built-ins ([Zechner](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/)). Belongs in a skill or workflow template, not an always-on file |
| Simplicity First / Minimal Impact | **Keep** | Matches Anthropic's anti-over-engineering guidance. "No laziness" is on Anthropic's stop-doing list ([best practices](https://code.claude.com/docs/en/best-practices)) |

The file's biggest failing is what it leaves out: **it contains no project facts at all**, and those are the only content every vendor agrees belongs in the file. At best it is a global-file draft. It is the wrong model for a project AGENTS.md.

### The Karpathy guidelines are better written, but Karpathy wrote none of them

`forrestchang/andrej-karpathy-skills` was **created about 7.5 hours after Karpathy's 26 January 2026 post**. It had **228,538 stars** on 3 November 2026, and its rule text has not changed since January. Commits since mid-April touch only packaging ([GitHub repo](https://github.com/forrestchang/andrej-karpathy-skills); [commits](https://github.com/forrestchang/andrej-karpathy-skills/commits/main)). Its README quotes Karpathy loosely. The decisive irony sits in the source post itself, where Karpathy writes: "**All of this happens despite a few simple attempts to fix it via instructions in CLAUDE.md**" ([Karpathy on X](https://x.com/karpathy/status/2015883857489522876)). Karpathy diagnosed the problems; the repo author wrote the prescriptions. Karpathy's own agent files take a different form. Autoresearch's `program.md` has a single metric, explicit CAN/CANNOT file scopes, a "simplicity criterion", and "NEVER STOP … do NOT pause to ask the human" ([program.md](https://github.com/karpathy/autoresearch/blob/master/program.md)). Nanochat ships a task skill instead of a behaviour file ([nanochat skills](https://github.com/karpathy/nanochat/tree/master/.claude/skills)).

Judged on content, the four principles rank as follows. **Goal-Driven Execution** ("Fix the bug" → "Write a test that reproduces it, then make it pass") is the best supported. It comes straight from Karpathy's "Leverage" paragraph ("Don't tell it what to do, give it success criteria"), matches Cherny's verification advice, and matches Anthropic's "something it can run that comes back pass or fail". One GitHub discussion called it the one principle "genuinely missing from defaults" ([discussion #1214](https://github.com/anthropics/claude-code-action/discussions/1214)). **Surgical Changes** contributes the set's most distinctive and checkable lines: "Every changed line should trace directly to the user's request" and remove only the orphans *your* change created. Superpowers has no equivalent ([superpowers](https://github.com/obra/superpowers)). **Simplicity First** is sound and agrees with Anthropic, but it may duplicate Claude Code's default prompt (unverified). **Think Before Coding** ("If something is unclear, stop … Ask") is the weakest for your workflow. It conflicts with autonomous or long-running use, and the repo itself admits it "bias[es] toward caution over speed". There is **no controlled evaluation** of the file. The only positive data is an n = 1 blog anecdote: a 14-line diff instead of a 200-line refactor ([dev.to](https://dev.to/ji_ai/how-a-markdown-file-hit-16k-stars-skills-in-2026-36hi)). Stars measure attention, not efficacy.

Packaging matters too. The plugin ships these rules as a *skill*, which loads only when its description matches the task. Vercel found a default skill was never invoked in 56% of eval cases ([Vercel](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)). If you value these four or five lines, pasting them into your global file is more reliable than installing the skill, and it also works in Codex, pi and OpenCode.

## Each concern has its own home outside the instruction file

The always-loaded file is your most expensive real estate, so the main design choice is what to keep *out* of it. The heuristic that every source supports: a line belongs in the always-loaded file only if (a) the agent cannot discover it, (b) it applies to most tasks, and (c) no deterministic tool can enforce it ([practitioner synthesis](https://www.humanlayer.dev/blog/writing-a-good-claude-md); [best practices](https://code.claude.com/docs/en/best-practices)). Anthropic states the enforcement boundary directly: "CLAUDE.md is for guidelines, and Claude is allowed to decide a guideline doesn't apply". Its own examples to move out are `Never read .env`, `Always run the formatter after editing` and `Don't touch the migrations folder` ([best practices](https://code.claude.com/docs/en/best-practices)). CLAUDE.md content is delivered as a user message after the system prompt, "not as part of the system prompt itself" ([memory docs](https://code.claude.com/docs/en/memory)).

| Content | Home | Portability note |
|---|---|---|
| Commands, gotchas, non-default conventions, boundaries | Root `AGENTS.md` | Read by Codex, pi, OpenCode, Copilot, Cursor; Claude Code natively since v2.1.277 ([memory](https://code.claude.com/docs/en/memory)) |
| Cross-project personal working style | Global personal file | Different path per tool; see the next section |
| Personal, per-project preferences | `CLAUDE.local.md` (Claude), `AGENTS.override.md` (Codex, pi) | **Creating `CLAUDE.local.md` silently disables AGENTS.md loading** under Claude's default setting; switch to `claude-md-and-agents-md` ([memory](https://code.claude.com/docs/en/memory)) |
| Rules for one area of the code | Nested `AGENTS.md` (portable); `.claude/rules/*.md` with `paths:`; Cursor globs; Copilot `applyTo` | Nested AGENTS.md is the only portable form. Codex reads one file per directory ([Codex guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md)) |
| Multi-step procedures (release, migration, PR review, debugging) | Skills / `SKILL.md`, or `docs/*.md` behind a pointer | Codex treats repeated workflows as skills ([Codex best practices](https://learn.chatgpt.com/docs/learn/best-practices)). Keep a trigger line in AGENTS.md because of skill-invocation misses |
| Must-always / must-never | Claude hooks and deny rules, Codex sandbox config, **git pre-commit hooks and CI** | Git hooks and CI are the tool-agnostic enforcement layer. Harness hooks are per-tool |
| Formatting and style | Linter or formatter, run in pre-commit and CI | Delete the corresponding prose ([HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md)) |
| Architecture, API references, post-training library docs | `docs/` plus a compressed pointer index in AGENTS.md | The index pattern produced Vercel's 100% ([Vercel](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)) |
| Plans, todos, progress | `PLAN.md`/`TODO.md`/specs, or the harness's plan mode | Never in AGENTS.md ([Huntley](https://ghuntley.com/ralph/)) |
| Learned corrections | Human-reviewed PR to AGENTS.md, or Claude auto memory | Cherny's PR-tagging pattern ([howborisusesclaudecode.com](https://howborisusesclaudecode.com/)) |
| Model, sandbox, MCP, permissions | `config.toml`, `settings.json`, `opencode.json` | "overloading the prompt with durable rules" is a listed mistake ([Codex best practices](https://learn.chatgpt.com/docs/learn/best-practices)) |

The tool-agnostic insight in this table is the enforcement row. Claude Code hooks, Codex sandbox settings and pi extensions each guard only their own harness. **A git pre-commit hook and a CI check catch every agent**, so for a portable workflow they are the right home for "never commit secrets", "always format" and "tests must pass". The prose line in AGENTS.md stays as an explanation, not as the guarantee.

## Recommended structures for a global file and a project template

### Wire one global source into four tools

No global personal file is shared across tools, and none of the vendors addresses this ([official notes](https://code.claude.com/docs/en/memory)). The solution is to keep one canonical plain-Markdown file in your dotfiles and point each tool at it.

| Tool | Global path to link | Project file read | Gotchas |
|---|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` containing `@~/dotfiles/agents/AGENTS.md` plus any Claude-only lines (user-scope imports need no approval) | `CLAUDE.md`; or `AGENTS.md` when no CLAUDE.md/CLAUDE.local.md exists | Imports don't reduce context cost. HTML comments are stripped (zero tokens) ([memory](https://code.claude.com/docs/en/memory)) |
| Codex | Symlink `~/.codex/AGENTS.md` | One file per directory, root → cwd, override > AGENTS.md > fallbacks | **32 KiB combined cap**. Check with `codex --ask-for-approval never "Summarize the current instructions."` ([Codex guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md)) |
| pi | Symlink `~/.pi/agent/AGENTS.md` | `AGENTS.md`/`CLAUDE.md` in cwd and parents; `AGENTS.override.md` per directory | `APPEND_SYSTEM.md` appends to the system prompt; no content guidance ([pi docs](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/configuration.md)) |
| OpenCode | Symlink `~/.config/opencode/AGENTS.md` (otherwise it falls back to `~/.claude/CLAUDE.md`) | `AGENTS.md`; `CLAUDE.md` only if no AGENTS.md | First match per category. `instructions` in `opencode.json` adds globs or URLs ([OpenCode](https://opencode.ai/docs/rules/)) |

Symlink OpenCode directly rather than relying on its Claude fallback. Your `~/.claude/CLAUDE.md` would contain an `@import`, and the notes did not confirm that OpenCode expands those. Likewise, whether pi expands `@AGENTS.md` inside a CLAUDE.md shim was not confirmed; pi lists AGENTS.md before CLAUDE.md, which suggests it prefers AGENTS.md in the same directory. Keep the shared file free of `@`, plan-mode and subagent references, and put Claude-specific lines only in the Claude wrapper.

### Global personal file: about 40 lines of working agreements

Every line below maps to a row in the adoption table. Keep the total under about 60 lines so that global plus project stays far below Codex's 32 KiB cap.

```markdown
# Personal working agreements

These are my defaults for every project. A project's AGENTS.md overrides them.
If my request conflicts with a project rule, point out the conflict and ask.

## Communication
- When I ask a question, answer it before making edits or running commands.
- Lead with the conclusion, then the reasoning. No canned enthusiasm or praise.
- When I give feedback, say whether you agree before saying what you changed.

## Scope
- Make the smallest change that solves the request; no speculative abstractions,
  options, or error handling for cases that cannot happen.
- Every changed line should trace to the request. Mention unrelated problems; don't fix them.
- Remove imports/functions your change made unused; leave pre-existing dead code alone.
- For a non-trivial plan, say whether it is over-, under-, or right-engineered, and why.

## Verification
- Turn tasks into checks: reproduce a bug with a failing test before fixing it.
- When you finish, report which check commands you ran and their result.

## Ask first
- Adding a production dependency, removing code that looks intentional,
  changing a public API or schema, anything touching production or credentials.

## Git
- Never commit, push, force-push, or rewrite history unless I ask.
- Stage explicit paths; never `git add -A` or `git add .`.
- Only commit files you changed in this session; unknown changes belong to someone else.

## Environment
- macOS, zsh. Python via `uv`; Node via `pnpm`.   <!-- edit to taste -->
```

Note what is absent: personas, "think hard", subagent policy, emphasis, and project facts. Watch the Verification block on Opus 5-class models. If you see over-verification, delete the second line before rewording it, as Anthropic advises ([prompting guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)). Also note that HTML comments cost nothing in Claude Code but are sent as-is by other tools.

### Project AGENTS.md: facts first, about 50–150 lines when filled in

The skeleton follows the order of the Anthropic example (Commands → Conventions → Gotchas) and GitHub's advice to put commands early. It adds Codex's "done" definition, the three-tier boundaries, and a pointer index ([best practices](https://code.claude.com/docs/en/best-practices); [Codex best practices](https://learn.chatgpt.com/docs/learn/best-practices); [GitHub blog](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)). Delete any section that has nothing non-obvious to say.

```markdown
# AGENTS.md

<One line, only if the README doesn't make it obvious: what this is + exact stack/versions.>

## Commands
- Install: `...`
- Run one test file: `...`
- Run all tests: `...`   (takes ~N min; use the single-file form while iterating)
- Lint / typecheck: `...`
- Full pre-PR check: `...`

## Done means
- `<full check>` passes and new behaviour has a test.

## Conventions (only where this repo differs from common defaults)
- <rule> — <one-clause reason>.
- New <thing> follows `path/to/exemplar.ext`.

## Gotchas
- <misleading code: live legacy dir not to copy; dir that looks unused but isn't>
- <environment: required env vars, services, generated files and how to regenerate>

## Boundaries
- Ask first: <migrations, new dependencies, public API changes>
- Never: <edit vendor/, commit secrets>   (enforced by <pre-commit/CI>)

## Git and PRs
- <branch naming, commit/PR title format, attribution policy>

## Where to look
- Working on <area>: read `docs/<area>.md` first.
- <Post-training or internal APIs>: read `docs/<lib>/INDEX.md` before using them.
```

For Claude-specific additions, use the pattern Anthropic documents instead of a bare symlink, which breaks on Windows and redirects writes. A CLAUDE.md that only *tells* Claude to read AGENTS.md is unreliable ([memory docs](https://code.claude.com/docs/en/memory)):

```markdown
@AGENTS.md

## Claude Code
- Use plan mode for changes under `src/billing/`.
```

For monorepos, add a nested `AGENTS.md` per package that holds only that package's commands and gotchas. Codex reads at most one file per directory, and nearer files come later and override earlier ones ([Codex guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md)).

### Maintenance is part of the template

The files studied grow by accretion. Two-thirds of CLAUDE.md files change in multiple commits, mostly additions with median deletions under 15 words ([arXiv 2511.12884](https://arxiv.org/html/2511.12884v1)). Build pruning into the workflow. Add a line only on the **second** occurrence of a mistake, preferably through a reviewed commit. Run `/doctor prompt-audit` in Claude Code to catch stale, contradictory or dead-reference lines ([memory docs](https://code.claude.com/docs/en/memory)). Use the Codex summary command to see what actually loaded. At each new model generation, try deleting the behavioural lines and re-add only those whose absence causes a visible regression. That is the reported Cherny practice (secondary), and it matches Anthropic's tooling.

## Conclusion

The field moved over 2026 from "write a good onboarding doc" to "write down only what the model can't know, and enforce the rest". The evidence says why. Agents obey these files almost too well, so every generic line buys extra steps and cost, while only non-discoverable facts move outcomes. For your learning repo, this means the reusable asset is not a set of rules but a **skeleton plus a discipline**: a near-empty project template whose sections force you to write commands, gotchas and boundaries; a small global file of working agreements; and git-hook and CI templates that carry the guarantees no prose can. Your global file has the shortest useful life of anything in the repo, because it compensates for model weaknesses that each generation removes. Treat it as dated scaffolding.

The open question is whether these files matter more in the work the benchmarks skip: multi-session, greenfield, team-convention-heavy work where practitioners insist they pay off. Until a well-powered study on current models exists, the defensible design is the one that does no harm if the files turn out to be useless (short, factual, enforced elsewhere) and that captures the upside where it has been measured: named tools, operational warnings, and pointers to knowledge the model lacks.

## Sources, dates and reliability flags

Flags: **OLD** = older than about 6 months (before May 2026) or tested on models now one or two generations behind; **SECONDARY** = reported by a third party, not checked against the person's own words; **UNVERIFIED** = could not be confirmed; **VENDOR** = self-interested eval or blog.

| Source | Date | Type | Flags |
|---|---|---|---|
| [Claude Code docs: memory](https://code.claude.com/docs/en/memory) | live, fetched 2026-11-03 | Official | Current; v2.1.277 release date unconfirmed |
| [Claude Code docs: best practices](https://code.claude.com/docs/en/best-practices) | live, fetched 2026-11-03 | Official | Current; supersedes the Apr 18, 2025 engineering post |
| [Anthropic prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) | live, undated | Official (API prompting) | Current; aimed at system prompts, not CLAUDE.md |
| [Anthropic engineering index](https://www.anthropic.com/engineering) | checked 2026-11-03 | Official | Has no Jul 2026 "context engineering for Claude 5" post |
| "80% of system prompt cut" (Jul 24, 2026, attributed to Thariq Shihipar) | Jul 2026 | Secondary reports | **UNVERIFIED** |
| [Codex AGENTS.md guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md) | undated | Official | No version or date shown |
| [Codex best practices](https://learn.chatgpt.com/docs/learn/best-practices) | undated | Official | No date shown |
| [OpenAI GPT-5 prompting guide](https://developers.openai.com/cookbook/examples/gpt-5/gpt-5_prompting_guide) | ~Aug 2025 | Official, archived | **OLD** |
| [agents.md](https://agents.md/) / [spec repo](https://github.com/agentsmd/agents.md) | undated | Standard | No versioned normative spec |
| [Linux Foundation AAIF announcement](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation) | 2025-12-09 | Press release | **OLD** (factual, still valid) |
| [pi configuration docs](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/configuration.md) | fetched Nov 2026 | Official | Concatenation order and `--no-context-files` unconfirmed |
| [OpenCode rules docs](https://opencode.ai/docs/rules/) | undated | Official | — |
| [Gemini CLI GEMINI.md docs](https://geminicli.com/docs/cli/gemini-md) | 2026-06-18 | Official | Product partly replaced by Antigravity CLI |
| [Cursor rules docs](https://cursor.com/docs/context/rules) | undated | Official | — |
| [GitHub Copilot repository instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) | undated | Official | "4,000-character" review limit **UNVERIFIED** |
| [VS Code custom instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions) | 2026-10-28 | Official | Current |
| [GitHub blog: 2,500+ agents.md files](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/) | 2025-11-19/25 | Vendor synthesis | **OLD**; no methodology or outcome data |
| [Gloaguen et al., Evaluating AGENTS.md](https://arxiv.org/html/2602.11988v3) | v1 2026-02-12, v3 2026-09-29 | Preprint / ICLR 2026 | Models Sonnet 4.5 / GPT-5.2 (one generation back); cite v3 numbers |
| [Lulla et al., AGENTS.md efficiency](https://arxiv.org/html/2601.20404v2) | Jan 2026, rev. Mar 2026 | Preprint | **OLD**; correctness not measured |
| [Khatri, two-agent ablation](https://arxiv.org/html/2607.27250) | Jul 2026 | Preprint | Current models; underpowered (MDE >30 pp) |
| [Shepard & Albrecht, probe-and-refine](https://arxiv.org/abs/2606.20512) | Jun 2026 | Preprint | Small open model only |
| [McMillan, adherence factorial study](https://arxiv.org/abs/2605.10039) | May 2026 | Preprint | Borderline age; single target rule |
| [IFScale](https://arxiv.org/html/2507.11538v1) | Jul 2025 | NeurIPS 2025 | **OLD** models; non-coding task |
| [Vercel, AGENTS.md vs skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals) | 2026-01-27 | Vendor eval | **OLD, VENDOR**; models and task count not stated |
| [Chatlatanagulchai et al., Agent READMEs](https://arxiv.org/html/2511.12884v1) | Nov 2025 | Preprint | **OLD**; descriptive |
| [Jiang & Nam, Cursor rules](https://arxiv.org/html/2512.18925) | Mar 2026 | MSR '26 | **OLD**; descriptive |
| [Santos et al., Claude Code configs](https://arxiv.org/abs/2511.09268) | Nov 2025 | AGENT @ ICSE 2026 | **OLD**; descriptive |
| [Boris Cherny thread (Thread Reader)](https://threadreaderapp.com/thread/2007179832300581177.html) | 2026-01-02 | Primary via mirror | **OLD** |
| [howborisusesclaudecode.com](https://howborisusesclaudecode.com/) | aggregates Jan–Jun 2026 | Aggregator quoting X | **SECONDARY** for exact wording |
| [Light Cone write-up (Engineered Intelligence)](https://engineeredintelligence.substack.com/p/how-the-claude-code-team-works) | 2026-03-02 | Podcast write-up | **OLD, SECONDARY** ("2 lines", "couple thousand tokens") |
| [lucadidomenico.studio, "delete every 6 months"](https://lucadidomenico.studio/en/blog/delete-claude-md-every-6-months) | Jul 2026 | Blog report of talk | **SECONDARY** |
| [hqman "Boris Cherny's CLAUDE.md" gist](https://gist.github.com/hqman/e29cb6386c539d795767e8c3fd2c959b) | 2026-02-23 | Community | **OLD**; misattributed |
| [Srishti on X](https://x.com/srishticodes/status/2025254119636959701) / [Hasan Toor on X](https://x.com/hasantoxr/status/2025851900911038603) | 2026-02-21 / 02-23 | Social | **OLD**; dates decoded from post IDs |
| Miles Deutscher post | 2026-11-01 | Social | **UNVERIFIED** (not retrievable) |
| [Karpathy, "notes from claude coding"](https://x.com/karpathy/status/2015883857489522876) | 2026-01-26 | Primary | **OLD**; describes Dec 2025 models |
| [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | rules Jan 2026; last push 2026-04-20 | Community | **OLD** content; not by Karpathy |
| [karpathy/autoresearch program.md](https://github.com/karpathy/autoresearch/blob/master/program.md) | Mar 2026 | Primary | **OLD** |
| [obra/superpowers](https://github.com/obra/superpowers) | v7.0.1, 2026-10-21 | Community framework | Current |
| [claude-code-action discussion #1214](https://github.com/anthropics/claude-code-action/discussions/1214) | 2026-04-14 | Community | **OLD**; default-prompt quotes **UNVERIFIED** |
| [dev.to Karpathy-skills anecdote](https://dev.to/ji_ai/how-a-markdown-file-hit-16k-stars-skills-in-2026-36hi) | 2026-04-23 | Blog | **OLD**; n = 1 |
| [pi-mono AGENTS.md](https://raw.githubusercontent.com/badlogic/pi-mono/main/AGENTS.md) | live, fetched Nov 2026 | Practitioner file | Current |
| [Zechner, minimal coding agent](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/) | 2025-11-30 | Practitioner | **OLD** |
| [Steinberger global AGENTS.MD](https://raw.githubusercontent.com/steipete/agent-scripts/main/AGENTS.MD) | live, rules dated to Oct 2026 | Practitioner file | Current |
| [Ghostty AGENTS.md](https://raw.githubusercontent.com/ghostty-org/ghostty/main/AGENTS.md) | live, fetched Nov 2026 | Practitioner file | Current |
| [HumanLayer, writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) | 2025-11-25 | Practitioner | **OLD**; "150–200 instructions" figure has no source |
| [Ronacher, agentic coding](https://lucumr.pocoo.org/2025/6/12/agentic-coding/) / [Pi](https://lucumr.pocoo.org/2026/1/31/pi/) | 2025-06-12 / 2026-01-31 | Practitioner | **OLD** |
| [Willison, Pragmatic Summit](https://simonwillison.net/2026/Mar/14/pragmatic-summit/) | 2026-03-14 | Practitioner | **OLD** |
| [Huntley, Ralph](https://ghuntley.com/ralph/) | 2025-07-14 | Practitioner | **OLD** |
| [DEV Community "200-line ceiling"](https://dev.to/davekurian/your-claudemd-is-too-long-the-200-line-ceiling-that-actually-works-1fb0) | 2026 | Blog | Adherence percentages **UNVERIFIED**; no underlying study |
