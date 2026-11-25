# Assignment 3 — Example answers (theory)

**Do not submit these.** They are training for the exam, and they are useful knowledge in the software industry. Answer the questions in [questions.md](questions.md) **in your own words first**, then open this file and compare.

A few sentences is enough. You will be asked why the flip-flop disappeared — explain the *mechanism*, not only "we added a database".

---

### Question 1: Shared responsibility (Flexible Server)

**See:** Section A, managed vs. DIY table, and [Azure Database for PostgreSQL](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Azure-Database-PostgreSQL.md).

**Azure:** install/patch/upgrade the engine, OS security, automated backups / PITR. **You:** schema and queries, connection strings and firewall rules, and the data (and the bill). PaaS does not mean "no homework".

### Question 2: Two bill components

**See:** Section A cost table and section H.

**Compute** (Burstable B1ms) bills while the server **runs**. **Storage** (32 GB minimum) bills **every month the server exists**, including while stopped. Stopped ≠ free: you still pay storage, and Azure may auto-start the compute after 7 days.

### Question 3: One-month break

**See:** Step 27 table and the 7-day reminder.

**Delete** the Flexible Server (keep the script). Stop would auto-restart after 7 days and bill three of the four weeks. Safe because Exercise 1 / `provision-db.ps1` can recreate server, firewall, and app setting — data is gone unless you dumped it, which is acceptable for this course seed.

### Question 4: Same build, different config

**See:** Section E and [12-factor: backing services](https://12factor.net/backing-services) / [config](https://12factor.net/config).

**Backing services** and **config**: the store is addressed only by a connection string. Locally that is Docker (`appsettings.Development.json`); in Azure it is `ConnectionStrings__DefaultConnection` on App Service. The **code and the build** did not change.

### Question 5: EnsureCreated vs. migrations

**See:** Step 5 (`EnsureCreated` paragraph).

`EnsureCreated()` builds the schema from the current model if the database is empty. It cannot apply a later column change to an existing database. **Migrations** are versioned steps you run on purpose. Fine here because the schema is small and disposable; wrong in production when real rows must survive a model change.

### Question 6: Secrets ladder

**See:** Section E reminder (secrets ladder) and Step 30.

Worst → best: hard-coded in `Program.cs` (in every clone and log) → `appsettings.json` in git (in history forever) → Application Settings (out of git, still readable with Portal RBAC) → Managed Identity (no password). **This assignment is on Application Settings.**

### Question 7: `0.0.0.0`–`0.0.0.0`

**See:** Step 12 (`--public-access`) and the [wiki firewall section](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Azure-Database-PostgreSQL.md).

It allows **Azure services** (your App Service) to reach the server. It does **not** open the internet — your laptop still needs `MyDevMachine`. In production you replace it with a tighter path (private access / VNet), because "any Azure resource in any subscription" is still a wide door.

### Question 8: Why the flip-flop disappeared

**See:** Section F, Steps 19–20.

The POST writes a **row in PostgreSQL**, not a list inside one process. Every instance runs the same query against the same database, so `seatsTaken` is the same number on every request. Compute is stateless; the database is the single source of truth.

### Question 9: Singleton vs. scoped

**See:** Step 5 (Why `AddScoped`).

The in-memory store **was** the data — one object per process, so `AddSingleton`. The Postgres store uses a `DbContext`, which is one-per-request (`AddScoped`). A singleton `DbContext` is not thread-safe: concurrent requests share one context and corrupt tracking or throw.

### Question 10: Health 503

**See:** Step 6 reminder (liveness vs. readiness).

A load balancer or orchestrator can **stop sending traffic** (or an alert can email you) when `/health` is 503. A **liveness** probe should usually *not* include the database: if PostgreSQL is down, killing and restarting the web app does not fix it and can make a cascade worse. Use readiness (or this combined `/health`) for "can I serve?", liveness for "is the process stuck?"

### Question 11: Posters on the web server disk

**See:** Section G opening.

Each instance (or each restart) would have a **different** disk — the flip-flop with JPEGs. Extra problem the in-memory store did not have: files **die with the plan** or a redeploy; they are not a managed file service. App Service `/home` is a quirk, not a design.

### Question 12: App streaming vs. SAS

**See:** Step 24 table and [Blob Storage — SAS](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Blob-Storage.md#p%C3%A4%C3%A4synhallinta-avaimet-sas-ja-entra-id).

**Through the app:** the container stays private; the API can require auth later. **Direct blob URL / SAS:** the browser downloads from storage, which scales and offloads the app. Switch to **SAS** when many large files would saturate App Service — time-limited, read-only links to one blob, container still not public.

### Question 13: Paste the real exception

**See:** Step 29.

`28P01` vs. a timeout are different forks (password vs. firewall). "My app can't reach the database" makes the model guess all causes at once. The risk is a plausible but **wrong** fix (you open the firewall when the password is wrong).
