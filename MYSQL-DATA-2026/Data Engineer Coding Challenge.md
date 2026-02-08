# Data Engineer Coding Challenge
**Duration:** 1 hour  
**Date:** February 7, 2026

This assessment evaluates your data engineering skills. It reflects how you build robust pipelines, transform data, and support analytics processes.

---

## Table of Contents
1. [SQL Coding Challenges](#sql-coding-challenges)
2. [ETL & Data Engineering Knowledge Questions](#etl-data-engineering-knowledge)

---

## SQL Coding Challenges

### Challenge 1: Travel Agency Trip Counter

**Problem:**
- Database for a travel agency with a `travel` table
- Task: Write an SQL query that counts trips from Destination A to Destination B
- Results must be alphabetically ordered by route pattern: `{start_location} to {end_location}`

**Table Structure:**
```
Table: travel
- Booking_ID (Int) - Booking ID of the trip
- Start_Location (Varchar) - Starting destination
- End_Location (Varchar) - End destination
```

**Sample Input:**
| Booking_ID | Start_Location | End_Location |
|------------|----------------|--------------|
| 1 | Washington | Ohio |
| 2 | Texas | Ohio |
| 3 | Ohio | California |
| 4 | Nebraska | Dallas |
| 5 | Ohio | California |

**Expected Output:**
| trip | count |
|------|-------|
| Nebraska to Dallas | 1 |
| Ohio to California | 2 |
| Texas to Ohio | 1 |
| Washington to Ohio | 1 |

**Solution:**
```sql
SELECT 
    CONCAT(Start_Location, ' to ', End_Location) AS trip,
    COUNT(*) AS count
FROM travel
GROUP BY Start_Location, End_Location
ORDER BY trip;
```

**Explanation:**
- `CONCAT()` creates the formatted route string
- `COUNT(*)` counts trips for each unique route
- `GROUP BY` aggregates by start and end locations
- `ORDER BY trip` sorts alphabetically

---

### Challenge 2: Customer Order Analysis

**Problem:**
- Write an SQL query to list customers with their full name (last name in uppercase)
- Calculate total amount spent by each customer across all orders
- Sort by spent amount (descending), then by customer name (alphabetically)

**Table Structures:**
```
Table: orders
- order_id (Integer) - Unique order ID
- ordered_product (String) - Product name
- ordered_by (Integer) - Customer ID
- price (Integer) - Order price in USD

Table: customers
- customer_id (Integer) - Unique customer ID
- first_name (String) - First name
- last_name (String) - Last name
```

**Sample Data:**

Orders:
| order_id | ordered_product | ordered_by | price |
|----------|----------------|------------|-------|
| 101 | Cadbury celebrations | 3 | 8 |
| 102 | Yonex shuttle corks | 3 | 8 |
| 103 | Reynolds pens pack | 2 | 3 |
| 104 | Axe perfume | 1 | 14 |
| 105 | Godrej refrigerator | 3 | 15 |
| 106 | Apple airdrops | 1 | 12 |
| 107 | Apple Watch | 2 | 11 |
| 108 | Samsung Galaxy K2 | 2 | 14 |

Customers:
| customer_id | first_name | last_name |
|-------------|------------|-----------|
| 1 | Ferauson | Mark |
| 2 | David | Willey |
| 3 | John | Carter |

**Expected Output:**
| customer_name | total_amt_spent |
|--------------|-----------------|
| Mark FERGUSON | 31 |
| John CARTER | 30 |
| David WILLEY | 28 |

**Solution:**
```sql
SELECT 
    CONCAT(c.first_name, ' ', UPPER(c.last_name)) AS customer_name,
    SUM(o.price) AS total_amt_spent
FROM customers c
INNER JOIN orders o ON c.customer_id = o.ordered_by
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_amt_spent DESC, customer_name ASC;
```

**Explanation:**
- `CONCAT()` with `UPPER()` formats name with uppercase last name
- `SUM(o.price)` calculates total spending
- `INNER JOIN` links customers to their orders
- `GROUP BY` aggregates by customer
- Dual `ORDER BY` sorts by amount (desc) then name (asc)

---

### Challenge 3: Job Applicant Position Assignment

**Problem:**
- Table named `applicant` containing job candidates and qualifications
- Assign each applicant the most suitable position level they qualify for
- Position hierarchy: Senior > Intermediate > Junior
- Each applicant gets only their highest qualifying level

**Position Requirements:**

**Senior Level:**
- 10+ years of coding experience
- Master's degree or higher
- Open-source experience
- Uses Linux as operating system

**Intermediate Level:**
- Less than 10 years of coding experience
- At least Bachelor's degree
- Working knowledge of Linux

**Junior Level:**
- Is a student
- Less than 5 years of coding experience
- Some open-source experience

**Table Structure:**
```
Table: applicant
- id (Int) - Applicant ID
- opensource (Varchar) - Has open-source experience (yes/no)
- student (Varchar) - Is a student (yes/no)
- highest_education (Varchar) - Highest degree
- years_coding (Int) - Years of professional coding
- operating_system (Varchar) - Primary OS
```

**Sample Input:**
| id | opensource | student | highest_education | years_coding | operating_system |
|----|-----------|---------|-------------------|--------------|------------------|
| 1 | no | no | Bachelors | 6 | Linux |
| 2 | yes | yes | Bachelors | 1 | Windows |
| 3 | yes | no | Masters | 13 | Linux |
| 4 | no | no | Bachelors | 5 | MacOS |
| 5 | yes | yes | No Degree | 1 | Windows |

**Expected Output:**
| id | position_level |
|----|---------------|
| 1 | Intermediate |
| 3 | Senior |
| 5 | Junior |

**Solution:**
```sql
SELECT 
    id,
    CASE
        WHEN years_coding >= 10 
             AND highest_education IN ('Masters', 'PhD', 'Doctorate')
             AND opensource = 'yes'
             AND operating_system = 'Linux'
        THEN 'Senior'
        
        WHEN years_coding < 10
             AND highest_education IN ('Bachelors', 'Masters', 'PhD', 'Doctorate')
             AND operating_system = 'Linux'
        THEN 'Intermediate'
        
        WHEN student = 'yes'
             AND years_coding < 5
             AND opensource = 'yes'
        THEN 'Junior'
        
        ELSE NULL
    END AS position_level
FROM applicant
HAVING position_level IS NOT NULL;
```

**Explanation:**
- CASE statement evaluates conditions in order (Senior → Intermediate → Junior)
- Each level has specific criteria checked with AND conditions
- `HAVING` clause filters out applicants who don't qualify for any position
- Returns only applicants with assigned positions

---

## ETL & Data Engineering Knowledge

### Question 1: ETL Testing Purposes
**Q:** Which are the main purposes of ETL testing?

**Options:**
- To verify the accuracy and completeness of the data in the target system
- To validate the functionality and performance of the ETL tools and technologies
- To check the quality and consistency of the data throughout the ETL process
- All of the above

**Answer:** All of the above

**Explanation:** ETL testing encompasses all three purposes:
1. **Verify accuracy and completeness** - Ensures data from source to target is correct
2. **Validate functionality and performance** - Tests ETL tools perform efficiently
3. **Check quality and consistency** - Validates data throughout the entire pipeline

---

### Question 2: Common Data Sources for ETL
**Q:** Which is NOT a common data source to feed an ETL?

**Options:**
- Flat files
- Relational databases
- Web pages
- Data warehouses

**Answer:** Data warehouses

**Explanation:** Data warehouses are the **target/destination** of ETL processes, not sources. ETL extracts from sources (files, databases, web pages) and loads **into** data warehouses.

---

### Question 3: Transformation Operations
**Q:** Which of the following is an example of a transformation operation in ETL?

**Options:**
- Joining data from multiple sources
- Filtering data based on certain criteria
- Aggregating data to calculate summary statistics
- None of the above

**Answer:** All three are transformation operations

**Explanation:** Common ETL transformations include:
- **Joining** - Combining data from multiple sources
- **Filtering** - Removing unwanted records
- **Aggregating** - Calculating summaries and statistics
- Also: cleansing, validation, type conversions, deduplication, sorting, etc.

---

### Question 4: Benefits of ETL Tools
**Q:** Which of the following are the benefits of using ETL tools over custom scripts?

**Correct Answers:**
✓ ETL tools enable faster and easier development and maintenance of ETL pipelines  
✓ ETL tools support various data formats and sources and offer built-in data quality and error handling features  
✓ ETL tools provide graphical interfaces and pre-built components for building and managing

**Incorrect Answers:**
✗ ETL tools are always cheaper than custom solutions (licensing can be expensive)  
✗ ETL tools eliminate the need for any data transformation logic (still need to define business rules)

---

### Question 5: Common ETL Tools
**Q:** What are some of the common ETL tools in the market?

**Answer:** Talend, Informatica, and MuleSoft

**Explanation:**
- **Talend** - Open-source and enterprise ETL tool
- **Informatica** - Enterprise-grade ETL platform
- **MuleSoft** - Integration platform with ETL capabilities

Other popular tools: SSIS, Oracle Data Integrator, IBM DataStage, AWS Glue, Azure Data Factory, Pentaho

---

### Question 6: Data Warehouse vs. Data Lake
**Q:** What's the difference between a data warehouse and a data lake?

**Correct Answers:**
✓ A data warehouse follows a schema-on-write approach, while a data lake follows a schema-on-read approach  
✓ A data warehouse is optimized for analytical queries, while a data lake is optimized for exploratory queries

**Key Differences:**
| Feature | Data Warehouse | Data Lake |
|---------|---------------|-----------|
| Data Type | Structured | All types |
| Schema | Schema-on-write | Schema-on-read |
| Users | Business analysts | Data scientists |
| Processing | ETL | ELT |
| Cost | Higher | Lower |
| Purpose | BI & reporting | Exploration & ML |

---

### Question 7: ETL Data Engineer Challenges
**Q:** Which is one of the challenges or difficulties faced by ETL data engineers?

**Answer:** Handling large volumes and varieties of data from diverse sources

**Explanation:** This is a core challenge because it involves:

**Volume Challenges:**
- Processing terabytes/petabytes of data
- Managing performance and scalability
- Resource optimization

**Variety Challenges:**
- Different data formats (CSV, JSON, XML, Parquet)
- Structured, semi-structured, and unstructured data
- Various APIs and protocols

**Diverse Sources:**
- Multiple databases (SQL, NoSQL)
- Cloud and on-premises systems
- Real-time streams and batch data
- Third-party APIs

**Other ETL challenges:**
- Data quality and cleansing
- Error handling and monitoring
- Change data capture (CDC)
- Performance optimization
- Data lineage maintenance

---

## Summary

**SQL Skills Demonstrated:**
- Aggregate functions (COUNT, SUM)
- String manipulation (CONCAT, UPPER)
- JOINs (INNER JOIN)
- GROUP BY and ORDER BY
- CASE statements for conditional logic
- Complex filtering with HAVING clause

**Data Engineering Concepts Covered:**
- ETL pipeline design and testing
- Data sources and targets
- Transformation operations
- Tool selection and benefits
- Data warehouse vs. data lake architecture
- Common challenges in data engineering

---

**Assessment Completed:** February 7, 2026  
**Total Questions:** 3 SQL Challenges + 7 Knowledge Questions




