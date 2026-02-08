import sqlite3

# Basic Database Queries Challenge
# This script demonstrates basic SQL queries using SQLite for two databases: db1 and db2

# Connect to db1 (users database)
conn1 = sqlite3.connect('db1.db')
cursor1 = conn1.cursor()

# Create users table in db1
cursor1.execute('''
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER
)
''')

# Insert sample data into users
cursor1.execute("INSERT OR IGNORE INTO users (name, age) VALUES ('Alice', 25)")
cursor1.execute("INSERT OR IGNORE INTO users (name, age) VALUES ('Bob', 30)")
cursor1.execute("INSERT OR IGNORE INTO users (name, age) VALUES ('Charlie', 35)")
conn1.commit()

# Basic queries on db1
print("=== DB1 (Users) Queries ===")

# SELECT all users
cursor1.execute("SELECT * FROM users")
users = cursor1.fetchall()
print("All users:")
for user in users:
    print(f"ID: {user[0]}, Name: {user[1]}, Age: {user[2]}")

# SELECT with WHERE
cursor1.execute("SELECT name, age FROM users WHERE age > 25")
older_users = cursor1.fetchall()
print("\nUsers older than 25:")
for user in older_users:
    print(f"Name: {user[0]}, Age: {user[1]}")

# UPDATE query
cursor1.execute("UPDATE users SET age = 26 WHERE name = 'Alice'")
conn1.commit()
print("\nUpdated Alice's age to 26")

# Verify update
cursor1.execute("SELECT * FROM users WHERE name = 'Alice'")
alice = cursor1.fetchone()
print(f"Alice after update: ID: {alice[0]}, Name: {alice[1]}, Age: {alice[2]}")

# DELETE query
cursor1.execute("DELETE FROM users WHERE name = 'Charlie'")
conn1.commit()
print("\nDeleted Charlie from users")

# Final SELECT
cursor1.execute("SELECT * FROM users")
remaining_users = cursor1.fetchall()
print("Remaining users:")
for user in remaining_users:
    print(f"ID: {user[0]}, Name: {user[1]}, Age: {user[2]}")

conn1.close()

# Connect to db2 (products database)
conn2 = sqlite3.connect('db2.db')
cursor2 = conn2.cursor()

# Create products table in db2
cursor2.execute('''
CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    price REAL
)
''')

# Insert sample data into products
cursor2.execute("INSERT OR IGNORE INTO products (name, price) VALUES ('Apple', 1.50)")
cursor2.execute("INSERT OR IGNORE INTO products (name, price) VALUES ('Banana', 0.75)")
cursor2.execute("INSERT OR IGNORE INTO products (name, price) VALUES ('Orange', 2.00)")
conn2.commit()

# Basic queries on db2
print("\n=== DB2 (Products) Queries ===")

# SELECT all products
cursor2.execute("SELECT * FROM products")
products = cursor2.fetchall()
print("All products:")
for product in products:
    print(f"ID: {product[0]}, Name: {product[1]}, Price: ${product[2]:.2f}")

# SELECT with WHERE
cursor2.execute("SELECT name, price FROM products WHERE price < 2.00")
cheap_products = cursor2.fetchall()
print("\nProducts cheaper than $2.00:")
for product in cheap_products:
    print(f"Name: {product[0]}, Price: ${product[1]:.2f}")

# UPDATE query
cursor2.execute("UPDATE products SET price = 1.25 WHERE name = 'Apple'")
conn2.commit()
print("\nUpdated Apple's price to $1.25")

# Verify update
cursor2.execute("SELECT * FROM products WHERE name = 'Apple'")
apple = cursor2.fetchone()
print(f"Apple after update: ID: {apple[0]}, Name: {apple[1]}, Price: ${apple[2]:.2f}")

# DELETE query
cursor2.execute("DELETE FROM products WHERE name = 'Banana'")
conn2.commit()
print("\nDeleted Banana from products")

# Final SELECT
cursor2.execute("SELECT * FROM products")
remaining_products = cursor2.fetchall()
print("Remaining products:")
for product in remaining_products:
    print(f"ID: {product[0]}, Name: {product[1]}, Price: ${product[2]:.2f}")

conn2.close()

# Connect to db3 (appointments database)
conn3 = sqlite3.connect('db3.db')
cursor3 = conn3.cursor()

# Drop tables if they exist to recreate with new schema
cursor3.execute('DROP TABLE IF EXISTS appointments')
cursor3.execute('DROP TABLE IF EXISTS applicants')

# Create applicants table in db3
cursor3.execute('''
CREATE TABLE applicants (
    id INTEGER PRIMARY KEY,
    email TEXT NOT NULL
)
''')

# Create appointments table in db3
cursor3.execute('''
CREATE TABLE appointments (
    applicant_id INTEGER,
    dt TEXT NOT NULL,
    FOREIGN KEY (applicant_id) REFERENCES applicants (id)
)
''')

# Insert sample data into applicants
cursor3.execute("INSERT OR IGNORE INTO applicants (id, email) VALUES (1, 'rastlattO@instagram.com')")
cursor3.execute("INSERT OR IGNORE INTO applicants (id, email) VALUES (2, 'gcarmodyl@stanford.edu')")
cursor3.execute("INSERT OR IGNORE INTO applicants (id, email) VALUES (3, 'mgreenset2@state.tx.us')")

# Insert sample data into appointments
cursor3.execute("INSERT OR IGNORE INTO appointments (applicant_id, dt) VALUES (1, '2024-05-26 01:36:43')")
cursor3.execute("INSERT OR IGNORE INTO appointments (applicant_id, dt) VALUES (2, '2024-05-26 16:30:28')")
cursor3.execute("INSERT OR IGNORE INTO appointments (applicant_id, dt) VALUES (3, '2024-05-18 19:28:52')")
conn3.commit()

# Query for weekend appointments
print("\n=== DB3 (Appointments) Queries ===")

# SELECT weekend appointments sorted by email
cursor3.execute("""
SELECT a.email, 
CASE strftime('%w', ap.dt)
    WHEN '0' THEN 'Sunday'
    WHEN '1' THEN 'Monday'
    WHEN '2' THEN 'Tuesday'
    WHEN '3' THEN 'Wednesday'
    WHEN '4' THEN 'Thursday'
    WHEN '5' THEN 'Friday'
    WHEN '6' THEN 'Saturday'
END AS scheduled_appointment
FROM applicants a
JOIN appointments ap ON a.id = ap.applicant_id
WHERE strftime('%w', ap.dt) IN ('0', '6')
ORDER BY a.email ASC
""")
weekend_appointments = cursor3.fetchall()
print("Weekend appointments (Saturday or Sunday), sorted by email:")
for appointment in weekend_appointments:
    print(f"Email: {appointment[0]}, Day: {appointment[1]}")

conn3.close()

print("\nDatabase operations completed successfully!")