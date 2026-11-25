# Assignment 2 — Example answers (theory)

**Do not submit these.** They are training for the exam, and they are useful knowledge in the software industry. Answer the questions in [questions.md](questions.md) **in your own words first**, then open this file and compare.

A few sentences is enough. If Azure started only one instance for you, still explain the **two-instance** case — that is the exam question.

---

### Question 1: Monolith is not a dirty word

**See:** Guided section A, paradigm table (Monolith).

A monolith is one deployable: you ship Campus Events as one App Service and one mental model. That is fast for a small team and a 5-credit course. Split when **independent release cycles** or **independent scale** become real problems (several teams blocking each other, or one hot endpoint forcing you to scale the whole app).

### Question 2: Serverless fit

**See:** Paradigm table (Serverless) and [Azure Functions](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Azure-Functions.md).

Example: a course feedback form used heavily for two weeks per semester and idle otherwise. Azure Functions + HTTP trigger (or a queue) costs almost nothing when nobody calls it. An always-on App Service would pay for empty hours. The property that matters is **spiky / rare load**, not "it is an API".

### Question 3: Event-driven decoupling

**See:** Paradigm table (Event-driven) and the reminder that paradigms combine.

The producer puts a message on a **queue** and is done. The consumer reads at its own speed. During a spike the queue **buffers**; registrations are not lost, they wait. A direct HTTP call would fail or time out when the consumer is overloaded — the producer and the consumer are coupled in time.

### Question 4: Explain the flip-flop

**See:** Steps 7–9.

The load balancer sends each request to **one** instance. Each instance has its **own** in-memory list. The POST lands on instance A, so only A's `seatsTaken` becomes 2. The next GET may hit instance B, which still has the seeded 1. Same URL, two stores.

### Question 5: Scale up vs. scale out

**See:** Scale up vs. scale out table in section A.

**Up first:** one request is CPU-heavy (a big report) — more RAM/CPU on the same instance helps. **Out first:** many concurrent users — more instances share the traffic. Scale-out only helps if the app is **stateless** (state outside the process). Otherwise you multiply the bug from Step 8.

### Question 6: Sticky sessions

**See:** Step 5 (ARR affinity) and Exercise 2.

Stickiness pins one **browser** to one instance, so that user may stop seeing the flip-flop. It does not (1) share data across instances, (2) survive an instance dying (that user loses "their" store), or (3) fix `curl` / a second device. Load also piles onto one instance.

### Question 7: Autoscale danger

**See:** Step 9 table (would get worse with autoscale).

Autoscale would start more instances, each with an **empty** (or freshly seeded) in-memory store. Users would see registrations appear and disappear depending on which instance answered. A busy day multiplies inconsistent carts, not capacity.

### Question 8: The meter

**See:** Section E reminder and Step 13.

**Before:** check the price (official table / calculator). **During:** know the meter started at `--sku B1`. **After:** scale in, then `--sku F1`, immediately. **Verify:** Cost analysis (may take 24 h). Skip "after" and B1 keeps billing overnight — student credit disappears on an experiment you already finished.

### Question 9: ADR value

**See:** Step 15 and [ADR](https://adr.github.io/).

An ADR records *why* you chose the managed database, not only *what* you deployed. Six months later a teammate (or you) asks: "Why is there a PostgreSQL bill?" The ADR answers with context, decision, and consequences — so nobody "fixes" it back to in-memory.

### Question 10: AI in architecture work

**See:** Step 14 checks.

"Tell me the best option" gets one confident default (often enterprise-scale). "Argue both sides" forces trade-offs you can judge: cost, complexity, student budget. Models agree with the frame you give them — if you only ask for a winner, you do not see what you are giving up.
