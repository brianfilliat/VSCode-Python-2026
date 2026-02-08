/*
====================================================================================
BAIRESDEV ASSESSMENT - DATABASE CODING CHALLENGE
Employee Salary Aggregations
Date: February 7, 2026
====================================================================================

ASSESSMENT DETAILS:
-------------------
Challenge Type:  Database Coding Challenge
Time Allocated:  45 minutes
Focus Area:      Query, structure, and manage relational data
Evaluation:      Ability to design, manipulate, and troubleshoot database operations

====================================================================================
PROBLEM STATEMENT
====================================================================================

Write a query to find the sum, minimum, and maximum of the salaries of the 
employees from the given table.

-------------------
TABLE STRUCTURE
-------------------
Table Name: EmployeeDepartment

Columns:
  • employee_id    (Integer) - Primary identifier for employee
  • employee_name  (Text)    - Employee's full name
  • job            (Text)    - Job title/role
  • manager_id     (Integer) - ID of employee's manager
  • salary         (Integer) - Employee's salary amount

-------------------
SAMPLE DATA
-------------------
┌─────────────┬───────────────┬─────────┬────────────┬────────┐
│ employee_id │ employee_name │   job   │ manager_id │ salary │
├─────────────┼───────────────┼─────────┼────────────┼────────┤
│    7369     │    SMITH      │  CLERK  │    7902    │   800  │
│    7566     │    JONES      │ MANAGER │    7839    │  3000  │
│    7782     │    CLARK      │ MANAGER │    7839    │  3000  │
│    7788     │    SCOTT      │ ANALYST │    7566    │  4000  │
└─────────────┴───────────────┴─────────┴────────────┴────────┘

-------------------
EXPECTED OUTPUT
-------------------
┌───────┬─────┬──────┐
│  SUM  │ MIN │ MAX  │
├───────┼─────┼──────┤
│ 10800 │ 800 │ 4000 │
└───────┴─────┴──────┘

====================================================================================
SOLUTION
====================================================================================
*/

SELECT 
    SUM(salary) AS SUM,
    MIN(salary) AS MIN,
    MAX(salary) AS MAX
FROM EmployeeDepartment;

/*
====================================================================================
SOLUTION BREAKDOWN
====================================================================================

AGGREGATE FUNCTIONS USED:
-------------------------
1. SUM(salary)
   • Purpose:    Calculate total of all salary values
   • Operation:  800 + 3000 + 3000 + 4000 = 10,800
   • Result:     10800

2. MIN(salary)
   • Purpose:    Find the lowest salary value
   • Operation:  Scans all rows to find minimum
   • Result:     800 (SMITH's salary)

3. MAX(salary)
   • Purpose:    Find the highest salary value
   • Operation:  Scans all rows to find maximum
   • Result:     4000 (SCOTT's salary)

COLUMN ALIASES:
--------------
• AS SUM  - Labels the sum column
• AS MIN  - Labels the minimum column
• AS MAX  - Labels the maximum column

PERFORMANCE NOTES:
-----------------
• Single table scan - O(n) time complexity
• All three aggregations computed in one pass
• No sorting or indexing required
• Returns single row with three columns
• Memory efficient - stores only running calculations

KEY CONCEPTS:
------------
✓ Aggregate functions operate on multiple rows
✓ Returns a single row when no GROUP BY clause
✓ Ignores NULL values in calculations
✓ Can combine multiple aggregate functions in one query
✓ Column aliases ensure output matches expected format

====================================================================================
END OF SOLUTION
====================================================================================
*/

