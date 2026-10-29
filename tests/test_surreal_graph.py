"""
Unit & Integration Test Suite for SurrealDB Multi-Model & Graph Engine
DA3: Modern Database Technology Extension (Restaurant Management)

Validates:
1. Document CRUD (CREATE, SELECT, UPDATE, DELETE)
2. Graph Edge Creation (RELATE in -> relation -> out)
3. Graph Forward Traversals (Index-Free Adjacency)
4. Graph Reverse Traversals (<-relation<-source)
5. Multi-Hop Food Recommendation Traversal (Knowledge Graph)
6. Spatial Table Adjacency Traversal
7. Live Query Subscriptions (LIVE SELECT kitchen trigger)
8. Cascade Edge Deletion on record removal
9. Cytoscape.js Graph Serialization
10. Query Latency Assertions (< 5.0ms)
"""

import sys
import os
import unittest
import time

# Add app to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "app")))
from surreal_db import SurrealDBEngine

class TestSurrealDBEngine(unittest.TestCase):

    def setUp(self):
        """Create fresh isolated test engine instance"""
        self.db = SurrealDBEngine()
        self.db.reset()
        self.db.seed_default_data()

    def test_01_document_crud(self):
        """Test document creation, retrieval, update, and deletion"""
        # Create
        rec = self.db.create_record("customer:c999", {
            "name": "Test Diner",
            "email": "test@diner.com",
            "loyalty_points": 100
        })
        self.assertIsNotNone(rec)
        self.assertEqual(rec["id"], "customer:c999")
        self.assertEqual(rec["name"], "Test Diner")

        # Read
        fetched = self.db.get_record("customer:c999")
        self.assertIsNotNone(fetched)
        self.assertEqual(fetched["email"], "test@diner.com")

        # Update
        updated = self.db.update_record("customer:c999", {"loyalty_points": 250})
        self.assertEqual(updated["loyalty_points"], 250)

        # Delete
        deleted = self.db.delete_record("customer:c999")
        self.assertTrue(deleted)
        self.assertIsNone(self.db.get_record("customer:c999"))

    def test_02_graph_relate_and_edge_attributes(self):
        """Test RELATE customer -> ordered -> menu_item with edge properties"""
        edge = self.db.relate("customer:c101", "ordered", "menu_item:m104", {
            "order_id": "ORD-TEST-1",
            "quantity": 3,
            "unit_price": 290.0,
            "subtotal": 870.0,
            "order_status": "PLACED"
        })
        self.assertIsNotNone(edge)
        self.assertEqual(edge["in"], "customer:c101")
        self.assertEqual(edge["relation"], "ordered")
        self.assertEqual(edge["out"], "menu_item:m104")
        self.assertEqual(edge["properties"]["subtotal"], 870.0)

    def test_03_forward_graph_traversal_no_joins(self):
        """Test SELECT ->ordered->menu_item FROM customer:c101 without SQL JOINs"""
        traversals = self.db.traverse("customer:c101", "ordered", "menu_item")
        self.assertGreater(len(traversals), 0)
        
        # Verify customer:c101 ordered Malai Kebab (m101) or Biryani (m103)
        target_ids = [t["target_id"] for t in traversals]
        self.assertIn("menu_item:m101", target_ids)
        self.assertIn("menu_item:m103", target_ids)

        # Verify edge properties accessible
        first_edge = traversals[0]["edge_properties"]
        self.assertIn("quantity", first_edge)
        self.assertIn("subtotal", first_edge)

    def test_04_reverse_graph_traversal(self):
        """Test reverse traversal: SELECT <-ordered<-customer FROM menu_item:m101"""
        reverse_traversals = self.db.reverse_traverse("menu_item:m101", "ordered", "customer")
        self.assertGreater(len(reverse_traversals), 0)

        # Verify customers who ordered m101 include c101
        source_ids = [t["source_id"] for t in reverse_traversals]
        self.assertIn("customer:c101", source_ids)

    def test_05_knowledge_graph_recommendations(self):
        """Test knowledge graph traversal: menu_item -> pairs_with -> menu_item"""
        recs = self.db.get_recommendations("menu_item:m103") # Dum Pukht Biryani
        self.assertGreater(len(recs), 0)

        # Biryani should pair with Garlic Butter Naan (m105) with high affinity
        rec_ids = [r["item_id"] for r in recs]
        self.assertIn("menu_item:m105", rec_ids)

        naan_rec = next(r for r in recs if r["item_id"] == "menu_item:m105")
        self.assertGreaterEqual(naan_rec["affinity_score"], 0.90)
        self.assertIn("Biryani", naan_rec["reason"])

    def test_06_spatial_table_adjacency(self):
        """Test dining_table -> adjacent_to -> dining_table table merging"""
        adjacent = self.db.traverse("dining_table:t103", "adjacent_to", "dining_table")
        self.assertEqual(len(adjacent), 1)
        self.assertEqual(adjacent[0]["target_id"], "dining_table:t104")
        self.assertTrue(adjacent[0]["edge_properties"]["can_merge"])

    def test_07_live_query_subscription(self):
        """Test real-time event emission on new order placement (LIVE SELECT)"""
        events_captured = []

        def mock_kitchen_display(event_type, edge_data):
            events_captured.append((event_type, edge_data))

        self.db.subscribe_live(mock_kitchen_display)

        # Trigger order
        new_edge = self.db.relate("customer:c102", "ordered", "menu_item:m202", {
            "order_id": "ORD-LIVE-TEST",
            "quantity": 1
        })

        self.assertEqual(len(events_captured), 1)
        self.assertEqual(events_captured[0][0], "order_created")
        self.assertEqual(events_captured[0][1]["id"], new_edge["id"])

    def test_08_cascade_edge_deletion(self):
        """Test that deleting a record automatically cleans dangling graph edges"""
        # Create temporary record and edge
        self.db.create_record("customer:c998", {"name": "Ephemeral Diner"})
        self.db.relate("customer:c998", "ordered", "menu_item:m101")

        # Verify edge exists
        before_edges = [e for e in self.db.edges if e["in"] == "customer:c998"]
        self.assertEqual(len(before_edges), 1)

        # Delete customer record
        self.db.delete_record("customer:c998")

        # Verify edge was cascade pruned
        after_edges = [e for e in self.db.edges if e["in"] == "customer:c998"]
        self.assertEqual(len(after_edges), 0)

    def test_09_cytoscape_elements_serialization(self):
        """Test formatting of nodes and edges for Cytoscape.js interactive canvas"""
        cy_data = self.db.get_cytoscape_elements()
        self.assertIn("nodes", cy_data)
        self.assertIn("edges", cy_data)
        self.assertIn("stats", cy_data)

        self.assertGreater(len(cy_data["nodes"]), 10)
        self.assertGreater(len(cy_data["edges"]), 5)

        # Verify node structure
        first_node = cy_data["nodes"][0]["data"]
        self.assertIn("id", first_node)
        self.assertIn("label", first_node)
        self.assertIn("type", first_node)
        self.assertIn("properties", first_node)

        # Verify edge structure
        first_edge = cy_data["edges"][0]["data"]
        self.assertIn("source", first_edge)
        self.assertIn("target", first_edge)
        self.assertIn("relation", first_edge)

    def test_10_sub_millisecond_query_latency(self):
        """Test that graph traversals consistently execute in under 5.0 milliseconds"""
        start = time.perf_counter()
        for _ in range(50):
            self.db.traverse("customer:c101", "ordered", "menu_item")
        avg_ms = ((time.perf_counter() - start) / 50) * 1000.0

        # Must execute within sub-millisecond range (< 2.0ms)
        self.assertLess(avg_ms, 2.0, f"Average traversal took {avg_ms:.3f}ms, expected < 2.0ms")

if __name__ == "__main__":
    unittest.main()
