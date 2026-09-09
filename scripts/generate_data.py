"""
Generate synthetic e-commerce data for the SQL portfolio project.

Creates:
    data/customers.csv    -> 10,000 customers
    data/products.csv     -> 500 products
    data/orders.csv       -> 50,000 orders
    data/order_items.csv  -> approximately 150,000 items

Run from the project root:
    python3 scripts/generate_data.py
"""

from __future__ import annotations

import csv
import random
from datetime import date, timedelta
from pathlib import Path

SEED = 42
NUM_CUSTOMERS = 10_000
NUM_PRODUCTS = 500
NUM_ORDERS = 50_000
START_DATE = date(2024, 1, 1)
END_DATE = date(2025, 12, 31)

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data"
random.seed(SEED)

FIRST_NAMES = [
    "Alice", "Emma", "Olivia", "Sophia", "Amelia", "Mia", "Isla", "Emily",
    "Ava", "Grace", "Lily", "Ella", "Chloe", "Sofia", "Freya", "Jack",
    "Noah", "Oliver", "George", "Harry", "Charlie", "Jacob", "Thomas",
    "Oscar", "William", "James", "Leo", "Henry", "Arthur", "Lucas",
    "Mateo", "Daniel", "Michael", "David", "John"
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Taylor", "Davies",
    "Wilson", "Evans", "Thomas", "Roberts", "Walker", "Wright", "Thompson",
    "White", "Hughes", "Edwards", "Green", "Hall", "Lewis", "Silva",
    "Santos", "Martins", "Costa", "Oliveira", "Miller", "Anderson", "Moore",
    "Jackson", "Martin"
]

COUNTRIES = [
    ("Ireland", 0.28), ("United Kingdom", 0.22), ("United States", 0.16),
    ("France", 0.09), ("Germany", 0.08), ("Spain", 0.06),
    ("Italy", 0.04), ("Portugal", 0.03), ("Netherlands", 0.02),
    ("Brazil", 0.02)
]

PRODUCT_TEMPLATES = [
    ("Electronics", "Laptop", 700, 2200),
    ("Electronics", "Smartphone", 300, 1400),
    ("Electronics", "Tablet", 200, 900),
    ("Electronics", "Monitor", 120, 700),
    ("Electronics", "Keyboard", 30, 180),
    ("Electronics", "Mouse", 15, 120),
    ("Electronics", "Smartwatch", 80, 500),
    ("Electronics", "Camera", 250, 1600),
    ("Home & Kitchen", "Coffee Machine", 60, 500),
    ("Home & Kitchen", "Air Fryer", 50, 250),
    ("Home & Kitchen", "Blender", 30, 180),
    ("Home & Kitchen", "Vacuum Cleaner", 80, 500),
    ("Home & Kitchen", "Cookware Set", 50, 300),
    ("Home & Kitchen", "Toaster", 20, 120),
    ("Home & Kitchen", "Electric Kettle", 20, 100),
    ("Fashion", "Sneakers", 40, 220),
    ("Fashion", "Jacket", 50, 300),
    ("Fashion", "Jeans", 35, 160),
    ("Fashion", "T-Shirt", 15, 80),
    ("Fashion", "Dress", 30, 180),
    ("Fashion", "Backpack", 25, 150),
    ("Fashion", "Watch", 50, 400),
    ("Beauty", "Skincare Set", 25, 180),
    ("Beauty", "Perfume", 35, 250),
    ("Beauty", "Hair Dryer", 30, 180),
    ("Beauty", "Makeup Kit", 25, 160),
    ("Beauty", "Face Cream", 15, 90),
    ("Beauty", "Shampoo", 8, 45),
    ("Sports & Outdoors", "Running Shoes", 50, 220),
    ("Sports & Outdoors", "Yoga Mat", 15, 80),
    ("Sports & Outdoors", "Dumbbell Set", 30, 200),
    ("Sports & Outdoors", "Fitness Tracker", 40, 250),
    ("Sports & Outdoors", "Camping Tent", 80, 450),
    ("Sports & Outdoors", "Hiking Backpack", 50, 300),
    ("Sports & Outdoors", "Bicycle", 250, 1500),
    ("Books", "Fiction Book", 8, 30),
    ("Books", "Business Book", 12, 45),
    ("Books", "Technology Book", 15, 60),
    ("Books", "Cookbook", 10, 40),
    ("Books", "Biography", 10, 45),
]

BRANDS = [
    "NovaTech", "UrbanHome", "PrimeStyle", "EverWell", "PeakGear",
    "BrightLife", "CoreMarket", "Vertex", "BlueLine", "NorthStar",
    "Apex", "DailyChoice"
]

STATUSES = [("Completed", 0.86), ("Cancelled", 0.07),
            ("Pending", 0.04), ("Returned", 0.03)]


def weighted_choice(options):
    values = [x[0] for x in options]
    weights = [x[1] for x in options]
    return random.choices(values, weights=weights, k=1)[0]


def random_date(start, end):
    return start + timedelta(days=random.randint(0, (end - start).days))


def generate_customers():
    signup_start = date(2023, 1, 1)
    signup_end = date(2025, 6, 30)
    return [
        {
            "customer_id": i,
            "customer_name": f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}",
            "country": weighted_choice(COUNTRIES),
            "signup_date": random_date(signup_start, signup_end).isoformat(),
        }
        for i in range(1, NUM_CUSTOMERS + 1)
    ]


def generate_products():
    products = []
    for i in range(1, NUM_PRODUCTS + 1):
        category, product_type, low, high = random.choice(PRODUCT_TEMPLATES)
        products.append({
            "product_id": i,
            "product_name": f"{random.choice(BRANDS)} {product_type}",
            "category": category,
            "base_price": round(random.uniform(low, high), 2),
        })
    return products


def generate_orders(customers):
    customer_ids = [c["customer_id"] for c in customers]
    repeat_customers = set(random.sample(customer_ids, 1200))
    orders = []

    for order_id in range(1, NUM_ORDERS + 1):
        customer_id = (
            random.choice(list(repeat_customers))
            if random.random() < 0.72
            else random.choice(customer_ids)
        )
        orders.append({
            "order_id": order_id,
            "customer_id": customer_id,
            "order_date": random_date(START_DATE, END_DATE).isoformat(),
            "status": weighted_choice(STATUSES),
        })

    orders.sort(key=lambda x: x["order_date"])
    for new_id, order in enumerate(orders, 1):
        order["order_id"] = new_id
    return orders


def generate_order_items(orders, products):
    items = []
    product_weights = [random.uniform(0.5, 3.0) for _ in products]

    for order in orders:
        if order["status"] == "Completed":
            count = random.choices(
                [1, 2, 3, 4, 5], [0.10, 0.30, 0.34, 0.20, 0.06])[0]
        else:
            count = random.choices([1, 2, 3], [0.55, 0.35, 0.10])[0]

        selected = random.choices(products, weights=product_weights, k=count)
        unique = {p["product_id"]: p for p in selected}

        for product in unique.values():
            quantity = random.choices(
                [1, 2, 3, 4], [0.64, 0.25, 0.08, 0.03])[0]
            unit_price = round(product["base_price"]
                               * random.uniform(0.90, 1.10), 2)
            items.append({
                "order_id": order["order_id"],
                "product_id": product["product_id"],
                "quantity": quantity,
                "unit_price": unit_price,
            })
    return items


def write_csv(filename, fields, rows):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUTPUT_DIR / filename
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    return path


def validate(customers, products, orders, items):
    customer_ids = {x["customer_id"] for x in customers}
    product_ids = {x["product_id"] for x in products}
    order_ids = {x["order_id"] for x in orders}

    assert len(customers) == NUM_CUSTOMERS
    assert len(products) == NUM_PRODUCTS
    assert len(orders) == NUM_ORDERS
    assert all(o["customer_id"] in customer_ids for o in orders)
    assert all(i["order_id"] in order_ids for i in items)
    assert all(i["product_id"] in product_ids for i in items)
    assert all(i["quantity"] > 0 and i["unit_price"] > 0 for i in items)


def main():
    print("Generating e-commerce data...")
    customers = generate_customers()
    products = generate_products()
    orders = generate_orders(customers)
    items = generate_order_items(orders, products)

    validate(customers, products, orders, items)

    files = [
        write_csv("customers.csv", [
                  "customer_id", "customer_name", "country", "signup_date"], customers),
        write_csv("products.csv", ["product_id", "product_name", "category"],
                  [{k: p[k] for k in ["product_id", "product_name", "category"]} for p in products]),
        write_csv("orders.csv", [
                  "order_id", "customer_id", "order_date", "status"], orders),
        write_csv("order_items.csv", [
                  "order_id", "product_id", "quantity", "unit_price"], items),
    ]

    print("\nDone!")
    print(f"Customers:   {len(customers):,}")
    print(f"Products:    {len(products):,}")
    print(f"Orders:      {len(orders):,}")
    print(f"Order items: {len(items):,}")
    print("\nFiles:")
    for file in files:
        print(f" - {file}")


if __name__ == "__main__":
    main()
