import psycopg2
from psycopg2 import sql
import time

def connect_to_db():
    print("Attempting to connect to PostgreSQL...")
    # Add a slight delay to ensure the database container is fully initialized before python tries to connect
    time.sleep(2)
    
    try:
        # Connect to your postgres DB
        conn = psycopg2.connect(
            host="localhost",
            database="sample_db",
            user="myuser",
            password="mypassword",
            port="5432"
        )
        
        # Open a cursor to perform database operations
        cur = conn.cursor()
        
        print("Successfully connected to the database!")
        
        # --- 1. Create a Table ---
        print("\nCreating 'employees' table...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS employees (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                department VARCHAR(50) NOT NULL,
                salary INTEGER
            );
        """)
        
        # Clear out any old data if the script is run multiple times
        cur.execute("TRUNCATE TABLE employees RESTART IDENTITY;")
        
        # --- 2. Insert Data ---
        print("Inserting sample data...")
        insert_query = """
            INSERT INTO employees (name, department, salary) 
            VALUES (%s, %s, %s);
        """
        employees_to_insert = [
            ("Alice Smith", "Engineering", 120000),
            ("Bob Jones", "Sales", 85000),
            ("Charlie Brown", "Marketing", 90000),
            ("Diana Prince", "Engineering", 145000)
        ]
        
        for emp in employees_to_insert:
            cur.execute(insert_query, emp)
            
        # Commit the transaction so the data is saved
        conn.commit()
        
        # --- 3. Query Data ---
        print("\nQuerying Engineering department employees:")
        cur.execute("""
            SELECT name, salary 
            FROM employees 
            WHERE department = 'Engineering'
            ORDER BY salary DESC;
        """)
        
        # Fetch all results from the query
        records = cur.fetchall()
        for row in records:
            print(f"Name: {row[0]}, Salary: ${row[1]:,}")
            
    except Exception as e:
        print(f"An error occurred: {e}")
        
    finally:
        # Close communication with the database
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn is not None:
            conn.close()
            print("\nDatabase connection closed.")

if __name__ == "__main__":
    connect_to_db()