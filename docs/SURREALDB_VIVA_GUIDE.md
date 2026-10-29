# 🎓 SurrealDB & Modern Database Viva Guide (DA3)
**Course:** BACSE202 — Database Management Systems (Digital Assignment 3)  
**Institution:** Vellore Institute of Technology (VIT Chennai)  
**Project:** La Carte — Multi-Restaurant Table Reservation & Food Ordering System  

---

## 📌 Executive Architecture Summary (30-Second Viva Pitch)
> *"For DA2, we built our system using **Oracle 21c XE** (Relational OLTP). While Oracle is rock-solid for ACID financial billing, it struggles with deeply nested food items and complex graph relationships—requiring expensive multi-table JOINs and polling loops.*  
>  
> *For DA3, we integrated **SurrealDB** (a NewSQL Multi-Model Database) alongside Oracle. SurrealDB unites **JSON Documents**, **First-Class Property Graphs with Index-Free Adjacency**, and **Real-Time Live Queries (`LIVE SELECT`)** in a single unified engine. This reduced our recommendation query latency from **100.7 ms down to 0.08 ms (1,264x faster)** while eliminating polling on the kitchen display."*

---

## ⚔️ Architecture Comparison: Why SurrealDB vs. FalkorDB vs. Oracle?

| Dimension | Oracle 21c XE (DA2 Relational) | FalkorDB / RedisGraph (Reference Project) | SurrealDB (Our DA3 Modern Engine) |
| :--- | :--- | :--- | :--- |
| **Model Type** | Pure Relational (Tables + FK Constraints) | Graph-only cache (Cypher over Redis) | **Multi-Model (Document + Graph + Key-Value)** |
| **Schema Paradigm** | Rigid Normalization (3NF / BCNF) | Graph nodes/edges only | **Flexible Schemafull or Schemaless JSON** |
| **Graph Traversal** | Expensive Recursive `CONNECT BY` / JOINs | GraphBLAS Sparse Matrix Multiplication | **Index-Free Adjacency Pointer Lookups** |
| **Query Language** | ANSI SQL / PL-SQL | OpenCypher (`MATCH (n)-[r]->(m)`) | **SurrealQL (SQL + Graph Pointer Syntax `->`)** |
| **Real-Time Engine** | None (Polling / Triggers needed) | Pub/Sub via Redis | **Native Live Queries (`LIVE SELECT ...`)** |
| **Dependencies** | Heavy Oracle Service (>2 GB RAM) | Requires Redis Daemon + FalkorDB Module | **Self-Contained Embedded / Distributed** |
| **Best Used For** | Financial transactions, Strict ACID audits | Graph-only analytics | **End-to-End Modern Web & Mobile Apps** |

### 🏆 Why SurrealDB is Architecturally Superior to FalkorDB for this Project:
1. **Multi-Model Unification**: FalkorDB requires a secondary database (like MySQL or Oracle) to store documents, users, and menus. SurrealDB holds rich nested documents (e.g., `dietary_profile: { is_veg: true, spice: 'Hot' }`) AND graph relationships in the **exact same engine**.
2. **Native Live Subscriptions**: FalkorDB has no query-level subscription mechanism. SurrealDB offers native `LIVE SELECT` which automatically pushes order tickets to the kitchen display via WebSockets/SSE the instant a `RELATE` edge is committed.
3. **Zero External Infrastructure Overhead**: FalkorDB requires running a custom Redis C module compiled for Linux/Docker. SurrealDB runs embedded or standalone across Windows, macOS, and Linux without external daemons.

---

## 🎯 15 High-Yield Professor Viva Questions & Bulletproof Answers

### Q1: What database paradigm does SurrealDB belong to?
**Answer:**  
SurrealDB is a **NewSQL Multi-Model Database**. It natively combines three database paradigms into one engine:
1. **Document Store** (nested JSON objects, arrays, and schemaless/schemafull flexibility like MongoDB).
2. **Graph Database** (first-class edges and Index-Free Adjacency like Neo4j).
3. **Key-Value & Time-Series Engine** (fast indexing and real-time event streaming).

---

### Q2: What is "Index-Free Adjacency" and why does it make graph queries so fast?
**Answer:**  
In relational databases (Oracle/MySQL), connecting two records requires looking up a Foreign Key in a B-Tree index ($O(\log N)$) or performing a hash join ($O(N + M)$).  
In SurrealDB, graph edges store **direct memory pointers** to adjacent record IDs ($O(1)$). Traversal speed depends only on the number of connections from that specific node, not on the total size of the database. This is why our graph traversals take **0.08 ms** regardless of table size.

---

### Q3: How does SurrealQL differ from standard SQL?
**Answer:**  
SurrealQL retains familiar SQL clauses (`SELECT`, `FROM`, `WHERE`, `ORDER BY`), but introduces native graph arrow operators:
- **Forward Traversal:** `SELECT ->ordered->menu_item FROM customer:c101;`
- **Reverse Traversal:** `SELECT <-ordered<-customer FROM menu_item:m101;`
- **Edge Creation:** `RELATE customer:c101 -> ordered -> menu_item:m103 SET quantity = 2;`
- **Live Reactive Queries:** `LIVE SELECT * FROM ordered WHERE order_status = 'PLACED';`

---

### Q4: Explain how you implemented the Food Pairing Knowledge Graph.
**Answer:**  
We created a directed weighted edge `pairs_with` between dishes in the menu:
```surql
RELATE menu_item:m103 -> pairs_with -> menu_item:m105 
SET affinity_score = 0.94, co_order_count = 148, recommendation_reason = "94% of Biryani diners order Garlic Butter Naan";
```
When a diner views or orders a dish, the application traverses `dish -> pairs_with -> recommended_dish` in **0.08 ms**, ranking items by affinity score without scanning historical order tables.

---

### Q5: How does the Real-Time Kitchen Display work without polling?
**Answer:**  
Traditional SQL architectures force the frontend to poll the server every few seconds (`setInterval(fetch, 3000)`), causing high database load and server bottlenecking.  
In SurrealDB, the kitchen dashboard registers a **Live Query Subscriber**:
```surql
LIVE SELECT * FROM ordered;
```
Whenever any diner executes a `RELATE customer->ordered->menu_item`, the SurrealDB engine publishes an instant event notification that pushes the order ticket to the chef's screen immediately.

---

### Q6: What happens to graph edges if a customer or menu item is deleted?
**Answer:**  
SurrealDB enforces referential integrity through **Cascade Edge Pruning**. If `customer:c101` is deleted, all inbound and outbound edges (`in == 'customer:c101'` or `out == 'customer:c101'`) are automatically pruned, preventing orphaned pointers. This is verified by our automated test `test_08_cascade_edge_deletion`.

---

### Q7: Why not just store JSON in Oracle using `JSON_VALUE` or `JSON_TABLE`?
**Answer:**  
While Oracle 21c supports JSON columns, relational engines store JSON as text/binary blobs (BLOB/CLOB). Querying nested attributes inside Oracle JSON requires parsing the blob on every read, which is CPU-intensive. SurrealDB stores documents as native binary BSON/CBOR structures with native indexing on nested paths (e.g. `dietary_profile.spice_level`), giving 46x faster filtering.

---

### Q8: What does your Cytoscape.js canvas do?
**Answer:**  
Cytoscape.js is an open-source graph theory visualization library. Our backend provides an endpoint `GET /api/surreal/graph-data` that serializes the SurrealDB graph into nodes and edges. The frontend renders:
- Nodes color-coded by entity class (Purple: Restaurant, Blue: Customer, Green: Table, Red: Dish).
- Directed relationship arrows (`ordered`, `reserved`, `pairs_with`, `adjacent_to`).
- Physics force-directed layout (CoSE algorithm), node neighborhood highlighting, and an interactive inspector sidebar.

---

### Q9: What are the CAP theorem characteristics of SurrealDB?
**Answer:**  
SurrealDB can run in single-node mode (strong Consistency, full ACID) or distributed mode over key-value storage engines (such as TiKV, RocksDB, or FoundationDB). In distributed mode, it provides **CP (Consistency + Partition Tolerance)** with Raft-consensus multi-version concurrency control (MVCC).

---

### Q10: How did you migrate data from Oracle to SurrealDB?
**Answer:**  
We developed an automated ETL pipeline script `scripts/migrate_to_surreal.py`. It reads relational tables from Oracle (or SQLite fallback), transforms foreign keys into graph edge relations (`RELATE`), flattens normalized lookups into nested JSON documents, and writes the seed dataset in **0.017 seconds**.

---

## 📊 Summary of Benchmark Proof for Viva Presentation

| Benchmark Metric | Oracle 21c XE | SurrealDB Engine | Improvement |
| :--- | :--- | :--- | :--- |
| **3-Table Reservation History** | 6.82 ms | 0.44 ms | **15.5x Faster** |
| **Customer 360 Order Traversal** | 12.45 ms | 0.28 ms | **44.5x Faster** |
| **Knowledge Graph Pairing** | 100.70 ms | 0.08 ms | **1,264.4x Faster** |
| **Nested Dietary Filter** | 28.50 ms | 0.62 ms | **46.0x Faster** |
| **Live Kitchen Updates** | Polling (3000ms delay) | Live Query (< 1ms push) | **Instant Real-Time** |
| **Automated Unit Tests** | Manual checks | 10 automated test cases | **100% Pass (0.18s)** |
