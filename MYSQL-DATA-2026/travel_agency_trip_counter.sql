/*
====================================================================================
SQL CHALLENGE: Travel Agency Trip Counter
Database: MySQL
Date: February 7, 2026
====================================================================================

PROBLEM STATEMENT:
-----------------
Database for a travel agency with a table named 'travel'.
Task: Write an SQL query that:
  • Counts the number of trips from Destination A to Destination B
  • Returns results alphabetically based on pattern: {start_location} to {end_location}
  • Each output row includes route description and number of trips

====================================================================================
TABLE STRUCTURE
====================================================================================

Table: travel
-------------
Column Name      | Data Type  | Description
Booking_ID       | Int        | Unique booking ID of the trip
Start_Location   | Varchar    | Starting destination of the trip
End_Location     | Varchar    | End destination of the trip

====================================================================================
SAMPLE DATA
====================================================================================

┌────────────┬────────────────┬──────────────┐
│ Booking_ID │ Start_Location │ End_Location │
├────────────┼────────────────┼──────────────┤
│     1      │  Washington    │     Ohio     │
│     2      │     Texas      │     Ohio     │
│     3      │     Ohio       │  California  │
│     4      │   Nebraska     │    Dallas    │
│     5      │     Ohio       │  California  │
└────────────┴────────────────┴──────────────┘

====================================================================================
EXPECTED OUTPUT
====================================================================================

┌────────────────────┬───────┐
│        trip        │ count │
├────────────────────┼───────┤
│ Nebraska to Dallas │   1   │
│ Ohio to California │   2   │
│ Texas to Ohio      │   1   │
│ Washington to Ohio │   1   │
└────────────────────┴───────┘

====================================================================================
SOLUTION
====================================================================================
*/

SELECT 
    CONCAT(Start_Location, ' to ', End_Location) AS trip,
    COUNT(*) AS count
FROM travel
GROUP BY Start_Location, End_Location
ORDER BY trip;

/*
====================================================================================
SOLUTION BREAKDOWN
====================================================================================

1. CONCAT(Start_Location, ' to ', End_Location)
   • Purpose:    Creates formatted route string
   • Example:    "Nebraska" + " to " + "Dallas" = "Nebraska to Dallas"
   • Result:     Human-readable trip description

2. COUNT(*)
   • Purpose:    Counts number of trips for each unique route
   • Operation:  Counts all rows within each group
   • Example:    Ohio to California appears twice, so COUNT = 2

3. GROUP BY Start_Location, End_Location
   • Purpose:    Groups trips by their start and end locations
   • Operation:  Creates separate groups for each unique route combination
   • Result:     Aggregates data for counting

4. ORDER BY trip
   • Purpose:    Sorts results alphabetically by the trip string
   • Operation:  Alphabetical ordering (A-Z)
   • Result:     Nebraska to Dallas, Ohio to California, Texas to Ohio, etc.

====================================================================================
KEY CONCEPTS
====================================================================================

✓ String concatenation using CONCAT()
✓ Aggregate function (COUNT) to summarize data
✓ GROUP BY for creating route-based groups
✓ ORDER BY for alphabetical sorting
✓ Alias (AS trip, AS count) for clean output formatting

TIME COMPLEXITY: O(n log n) for sorting
SPACE COMPLEXITY: O(n) for grouping unique routes

====================================================================================
TEST CASES
====================================================================================

Test Case 1: Multiple trips on same route
  • Input:  3 trips from Ohio to California, 1 from Texas to Ohio
  • Output: Ohio to California (3), Texas to Ohio (1)

Test Case 2: Single trip routes
  • Input:  All unique routes
  • Output: Each route with count of 1

Test Case 3: Empty table
  • Input:  No rows in travel table
  • Output: Empty result set

====================================================================================
END OF SOLUTION
====================================================================================
*/
