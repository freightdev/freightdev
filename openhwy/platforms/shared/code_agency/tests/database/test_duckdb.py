import duckdb

# Connect to the same database file your backend uses
con = duckdb.connect('../data/test_duckdb.duckdb')

# List tables
tables = con.execute("SHOW TABLES").fetchall()
print("Tables:", tables)

# Run a test query
result = con.execute("SELECT 1 AS test").fetchall()
print(result)
