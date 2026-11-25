# Assignment 3 — What to return and theory

## What to return

**All returns go to the Learn platform.** Submit only the screenshots and live links below. Do not upload code or script files.

Theory questions further down this file are **not submitted**. They are training for the exam, and they are useful knowledge in the software industry. Write your own answers first — you will be asked to explain why the flip-flop disappeared. Example answers are in [example-answers.md](example-answers.md) — use them to check yourself, not as a copy-paste.

- [ ] Screenshot: local restart test (Step 10) — `seatsTaken` survives an app restart
- [ ] Screenshot: `az postgres flexible-server show` output (Step 14)
- [ ] Screenshot: Azure restart test (Step 18)
- [ ] Screenshot: Step 20 — **consistent** `seatsTaken` on every request (two instances if Azure started them). Side by side with your Assignment 2 flip-flop **if you have it**; otherwise the consistent loop plus Step 18 is enough
- [ ] Screenshot: the poster upload (Step 25) — the `curl -F` command and the image rendering in the browser
- [ ] Screenshot: `az storage blob list` output showing the poster blob (Step 25)
- [ ] Screenshot: Cost analysis showing the PostgreSQL charge (Step 28, can be a day late)
- [ ] **Link:** your app's `/api/events` URL on `azurewebsites.net`, now backed by PostgreSQL
- [ ] **Link:** one event's poster URL (`/api/events/<id>/poster`) — served from Blob Storage
- [ ] Screenshot: exercise 1 — your idempotent provisioning script run **twice** (both outputs)

Written work that is not a screenshot (exercise 2 cost lifecycle table) goes in your Learn answers document.

---

# Theory questions

**Do not submit these answers.** They train you for the exam, and they are good knowledge to have in the software industry. Try each question yourself, then compare with [example-answers.md](example-answers.md).

Answer in your own words. Short answers are fine (2–5 sentences), but they must show you understand the *why*, not just the *what*. Everything you need is in this assignment's README (and the wiki / 12-factor / EF Core links under Additional material).

## Managed databases

1. Using the shared responsibility model: name **three things Azure handles** for a Flexible Server that you would have to handle yourself if you installed PostgreSQL on a virtual machine, and **two responsibilities that stay yours** either way.

2. The Flexible Server bill has two components. What are they, and which one keeps running when the server is **stopped**? Why does "stopped" still not equal "free"?

3. A stopped Flexible Server restarts automatically after 7 days. You are leaving for a one-month break between course modules. What do you do with the database, and what makes that choice safe (i.e. how do you get the environment back)?

## Configuration and secrets

4. The exact same application build ran against Docker PostgreSQL locally and Flexible Server in Azure without a code change. Which 12-factor principles does this demonstrate, and what was the *only* thing that differed between the environments?

5. Explain the difference between `Database.EnsureCreated()` and EF Core migrations. Why is `EnsureCreated()` acceptable in this assignment but wrong for a production system whose schema changes over time?

6. Rank these places to keep the production database password, from worst to best, and give one sentence per rung: hard-coded in `Program.cs` / in `appsettings.json` committed to git / in App Service Application Settings / no password at all (Managed Identity). Which rung is this assignment on?

## Networking

7. The firewall rule `0.0.0.0 – 0.0.0.0` sounds like "allow everyone". What does it actually allow, what does it *not* allow, and why is it still a rule you would replace in a production environment?

## Architecture

8. In Assignment 2, reading `seatsTaken` with two instances flip-flopped between values. After this assignment it is consistent. Explain the mechanism of the fix — what exactly changed about *where* a POSTed registration ends up, and why every instance now agrees?

9. The DI registration changed from `AddSingleton` to `AddScoped` when the store moved from memory to PostgreSQL. Explain why each lifetime was correct for its implementation. What would go wrong if you registered the `DbContext`-backed store as a singleton?

10. `/health` now returns 503 when the database is unreachable. Give one concrete example of what a cloud platform (load balancer, orchestrator, or monitoring alert) can do with that signal — and one reason why a *liveness* check should usually **not** include the database.

## Blob Storage

11. Explain why saving uploaded posters to the web server's disk would repeat the Assignment 2 mistake — and name one additional problem it causes that the in-memory store did *not* have (hint: think about what happens to the plan, or a redeploy of the app).

12. The poster is served *through* the app (`GET .../poster` streams the blob) rather than by giving users a direct blob URL. Name one advantage of each approach, and describe the situation where you would switch to **SAS links** (time-limited signed URLs directly to storage).

## AI

13. In Step 29, AI helped debug a connection failure. Why was pasting the **actual exception from the logs** essential to getting a useful answer — and what is the risk of instead describing the symptom in your own words ("my app can't reach the database")?
