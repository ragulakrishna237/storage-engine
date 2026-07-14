# Storage Engine Sandbox

This repository is a dedicated workspace for testing and experimenting with various storage engines, databases, and data persistence technologies.

## Current Modules

### 1. PostgreSQL Sample (`/postgres_sample`)
A sandbox for testing relational database concepts, complex queries, and operations using PostgreSQL.
- **Docker Setup:** Includes a `compose.yaml` to easily spin up a local PostgreSQL instance.
- **SQL Scripts:** 
  - `student_db.sql`: Schema and data for a basic student database.
  - `enterprise_ops_db.sql`: Schema and data for a more complex enterprise operations database.
- **Python Scripts:** 
  - `db_queries.py`: Demonstrates basic CRUD operations and queries.
  - `db_joins.py`: Demonstrates various types of SQL JOINs (INNER, LEFT, RIGHT, FULL OUTER, CROSS, SELF).
- **Requirements:** `requirements.txt` containing the necessary Python database adapters (like `psycopg2`).

## Setup Instructions

To run the PostgreSQL sample:
1. Navigate to the `postgres_sample` directory:
   ```bash
   cd postgres_sample
   ```
2. Start the database using Docker Compose:
   ```bash
   docker-compose up -d
   ```
3. Install the Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the Python scripts to interact with the database:
   ```bash
   python db_joins.py
   ```

*More storage engines (e.g., MongoDB, Redis, MySQL) will be added to this repository in the future.*