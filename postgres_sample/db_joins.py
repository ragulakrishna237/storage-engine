import psycopg2
import time

def run_joins():
    print("Connecting to PostgreSQL to run JOIN operations...\n")
    try:
        conn = psycopg2.connect(
            host="localhost",
            database="sample_db",
            user="myuser",
            password="mypassword",
            port="5432"
        )
        cur = conn.cursor()
        
        # ---------------------------------------------------------
        # 1. INNER JOIN: Show each employee with their department name
        # ---------------------------------------------------------
        print("--- 1. INNER JOIN ---")
        print("Description: Show each employee along with their department name.")
        query1 = """
            SELECT e.emp_name, d.dept_name
            FROM employees e
            INNER JOIN departments d ON e.dept_id = d.dept_id
            LIMIT 5;
        """
        cur.execute(query1)
        for row in cur.fetchall():
            print(f"Employee: {row[0]:<20} | Department: {row[1]}")
        print("-" * 50 + "\n")

        # ---------------------------------------------------------
        # 2. LEFT JOIN: All departments and their employees
        # ---------------------------------------------------------
        print("--- 2. LEFT JOIN ---")
        print("Description: Display all departments and their employees (including empty departments).")
        query2 = """
            SELECT d.dept_name, e.emp_name
            FROM departments d
            LEFT JOIN employees e ON d.dept_id = e.dept_id
            ORDER BY d.dept_name
            LIMIT 10;
        """
        cur.execute(query2)
        for row in cur.fetchall():
            emp_name = row[1] if row[1] else "(No Employees)"
            print(f"Department: {row[0]:<25} | Employee: {emp_name}")
        print("-" * 50 + "\n")

        # ---------------------------------------------------------
        # 3. RIGHT JOIN: All projects and assigned employees
        # ---------------------------------------------------------
        print("--- 3. RIGHT JOIN ---")
        print("Description: Display all projects and assigned employees (including projects with no employees).")
        query3 = """
            SELECT p.proj_name, e.emp_name
            FROM employee_projects ep
            INNER JOIN employees e ON ep.emp_id = e.emp_id
            RIGHT JOIN projects p ON ep.proj_id = p.proj_id
            ORDER BY p.proj_name
            LIMIT 10;
        """
        cur.execute(query3)
        for row in cur.fetchall():
            emp_name = row[1] if row[1] else "(Unassigned)"
            print(f"Project: {row[0]:<25} | Assigned To: {emp_name}")
        print("-" * 50 + "\n")

        # ---------------------------------------------------------
        # 4. FULL OUTER JOIN: Match projects with clients
        # ---------------------------------------------------------
        print("--- 4. FULL OUTER JOIN ---")
        print("Description: Show all projects and clients, matching where possible.")
        query4 = """
            SELECT p.proj_name, c.client_name
            FROM projects p
            FULL OUTER JOIN clients c ON p.proj_id = c.proj_id
            ORDER BY p.proj_name
            LIMIT 10;
        """
        cur.execute(query4)
        for row in cur.fetchall():
            proj = row[0] if row[0] else "(No Project)"
            client = row[1] if row[1] else "(No Client)"
            print(f"Project: {proj:<25} | Client: {client}")
        print("-" * 50 + "\n")

        # ---------------------------------------------------------
        # 5. SELF JOIN: Employee and their manager
        # ---------------------------------------------------------
        print("--- 5. SELF JOIN ---")
        print("Description: Show each employee together with their manager's name.")
        query5 = """
            SELECT e.emp_name AS employee, m.emp_name AS manager
            FROM employees e
            LEFT JOIN employees m ON e.manager_id = m.emp_id
            LIMIT 10;
        """
        cur.execute(query5)
        for row in cur.fetchall():
            manager = row[1] if row[1] else "(Is Top Manager)"
            print(f"Employee: {row[0]:<20} | Reports To: {manager}")
        print("-" * 50 + "\n")

        # ---------------------------------------------------------
        # 6. CROSS JOIN: All possible Employee-Department combos
        # ---------------------------------------------------------
        print("--- 6. CROSS JOIN ---")
        print("Description: Generate all possible employee-department combinations.")
        query6 = """
            SELECT e.emp_name, d.dept_name
            FROM employees e
            CROSS JOIN departments d
            LIMIT 5;
        """
        cur.execute(query6)
        for row in cur.fetchall():
            print(f"Employee: {row[0]:<20} | Potential Dept: {row[1]}")
        print(f"... and {17 * 6 - 5} more combinations!") # 17 employees * 6 depts = 102 total
        print("-" * 50 + "\n")

    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn is not None:
            conn.close()

if __name__ == "__main__":
    run_joins()