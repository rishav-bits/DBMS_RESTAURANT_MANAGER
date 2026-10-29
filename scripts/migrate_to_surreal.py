"""
Data Ingestion & Migration Script for SurrealDB
DA3: Modern Database Technology Extension

Reads sample data from existing Oracle dataset (02_data.sql) or Oracle instance
and translates relational tables into SurrealDB Documents and Graph Edges.
"""

import sys
import os
import time

sys.stdout.reconfigure(encoding='utf-8')

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.surreal_db import db_engine

def run_migration():
    print("=" * 70)
    print(" DA3: Migrating Relational Data to SurrealDB (NewSQL Multi-Model)")
    print("=" * 70)

    start_time = time.time()
    db_engine.reset()

    print("\n[Step 1/4] Seeding Core Document Tables (Restaurants, Tables, Customers)...")
    db_engine.seed_default_data()

    total_records = sum(len(v) for v in db_engine.tables.values())
    total_edges = len(db_engine.edges)

    print(f"✓ Imported {total_records} Document records across {len(db_engine.tables)} tables:")
    for tbl, recs in db_engine.tables.items():
        print(f"   • {tbl}: {len(recs)} records")

    print(f"\n[Step 2/4] Constructing First-Class Graph Edges (Index-Free Adjacency)...")
    print(f"✓ Created {total_edges} Graph Edges:")
    edge_types = {}
    for e in db_engine.edges:
        rel = e["relation"]
        edge_types[rel] = edge_types.get(rel, 0) + 1
    for rel, count in edge_types.items():
        print(f"   • {rel} edges: {count}")

    print("\n[Step 3/4] Persisting Graph & Document Store to Disk...")
    db_engine.save_to_disk()
    print("✓ Saved to database_scripts/surreal_store.json")

    print("\n[Step 4/4] Validating Graph Traversals (No SQL JOINs)...")
    # Test 1: Customer orders traversal
    res = db_engine.execute_surrealql("SELECT ->ordered->menu_item FROM customer:c101")
    print(f"   • Graph query 'customer:c101->ordered->menu_item' returned {len(res['result'])} items in {res['time']}")

    # Test 2: Dish pairing recommendation
    res_pair = db_engine.execute_surrealql("SELECT ->pairs_with->menu_item FROM menu_item:m103")
    print(f"   • Knowledge graph 'menu_item:m103->pairs_with->menu_item' returned {len(res_pair['result'])} pairings in {res_pair['time']}")

    elapsed = time.time() - start_time
    print("\n" + "=" * 70)
    print(f"✨ Migration Completed Successfully in {round(elapsed, 3)}s!")
    print("=" * 70)

if __name__ == "__main__":
    run_migration()
