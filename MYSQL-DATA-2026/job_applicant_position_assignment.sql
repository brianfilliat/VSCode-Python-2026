/*
====================================================================================
SQL CHALLENGE: Job Applicant Position Assignment
Database: MySQL
Date: February 7, 2026
====================================================================================

PROBLEM STATEMENT:
-----------------
Given a table named 'applicant' containing job candidates and qualifications.

Task: 
  • Return each applicant's ID with the most suitable position level they qualify for
  • Position levels must be assigned in order of seniority: Senior > Intermediate > Junior
  • Each applicant gets only ONE level - specifically the HIGHEST one they qualify for
  • Applicants not meeting any criteria should NOT be included in output

====================================================================================
POSITION LEVEL REQUIREMENTS
====================================================================================

SENIOR LEVEL:
-------------
  ✓ 10 or more years of coding experience
  ✓ Master's degree or higher (Masters, PhD, Doctorate)
  ✓ Open-source experience (yes)
  ✓ Uses Linux as operating system

INTERMEDIATE LEVEL:
------------------
  ✓ Fewer than 10 years of coding experience
  ✓ At least Bachelor's degree (Bachelors, Masters, PhD, Doctorate)
  ✓ Working knowledge of Linux (operating system = Linux)

JUNIOR LEVEL:
------------
  ✓ Must be a student (student = yes)
  ✓ Less than 5 years of coding experience
  ✓ Some open-source experience (opensource = yes)

DISQUALIFIED:
------------
If an applicant doesn't meet ANY of the above criteria, they are excluded from output.

====================================================================================
TABLE STRUCTURE
====================================================================================

Table: applicant
----------------
Column Name         | Data Type  | Description
id                  | Int        | Applicant's unique ID
opensource          | Varchar    | Has open-source experience (yes/no)
student             | Varchar    | Is a student (yes/no)
highest_education   | Varchar    | Highest degree (No Degree, Bachelors, Masters, PhD, Doctorate)
years_coding        | Int        | Years in professional coding environment
operating_system    | Varchar    | Primary operating system (Linux, Windows, MacOS)

====================================================================================
SAMPLE DATA
====================================================================================

┌────┬────────────┬─────────┬───────────────────┬──────────────┬──────────────────┐
│ id │ opensource │ student │ highest_education │ years_coding │ operating_system │
├────┼────────────┼─────────┼───────────────────┼──────────────┼──────────────────┤
│ 1  │    no      │   no    │    Bachelors      │      6       │      Linux       │
│ 2  │    yes     │   yes   │    Bachelors      │      1       │     Windows      │
│ 3  │    yes     │   no    │    Masters        │     13       │      Linux       │
│ 4  │    no      │   no    │    Bachelors      │      5       │      MacOS       │
│ 5  │    yes     │   yes   │    No Degree      │      1       │     Windows      │
└────┴────────────┴─────────┴───────────────────┴──────────────┴──────────────────┘

Analysis:
  • ID 1: Bachelors, 6 years, Linux → INTERMEDIATE
  • ID 2: Student, 1 year, opensource but Windows → NOT QUALIFIED (needs opensource for Junior)
  • ID 3: Masters, 13 years, opensource, Linux → SENIOR
  • ID 4: Bachelors, 5 years, MacOS → NOT QUALIFIED (needs Linux)
  • ID 5: Student, 1 year, opensource → JUNIOR

====================================================================================
EXPECTED OUTPUT
====================================================================================

┌────┬────────────────┐
│ id │ position_level │
├────┼────────────────┤
│ 1  │ Intermediate   │
│ 3  │ Senior         │
│ 5  │ Junior         │
└────┴────────────────┘

Note: IDs 2 and 4 are excluded as they don't meet any level requirements

====================================================================================
SOLUTION
====================================================================================
*/

SELECT 
    id,
    CASE
        -- SENIOR LEVEL: Highest priority check
        WHEN years_coding >= 10 
             AND highest_education IN ('Masters', 'PhD', 'Doctorate')
             AND opensource = 'yes'
             AND operating_system = 'Linux'
        THEN 'Senior'
        
        -- INTERMEDIATE LEVEL: Second priority check
        WHEN years_coding < 10
             AND highest_education IN ('Bachelors', 'Masters', 'PhD', 'Doctorate')
             AND operating_system = 'Linux'
        THEN 'Intermediate'
        
        -- JUNIOR LEVEL: Third priority check
        WHEN student = 'yes'
             AND years_coding < 5
             AND opensource = 'yes'
        THEN 'Junior'
        
        -- DISQUALIFIED: Doesn't meet any criteria
        ELSE NULL
    END AS position_level
FROM applicant
HAVING position_level IS NOT NULL;

/*
====================================================================================
SOLUTION BREAKDOWN
====================================================================================

1. CASE STATEMENT - Hierarchical Evaluation
   • Purpose:    Evaluates conditions in order from highest to lowest priority
   • Order:      Senior → Intermediate → Junior → NULL
   • Behavior:   Stops at first TRUE condition (short-circuit evaluation)
   • Result:     Assigns the highest level the applicant qualifies for

2. SENIOR LEVEL CONDITIONS (All must be TRUE)
   • years_coding >= 10:                         10+ years experience
   • highest_education IN (...):                 Master's degree or higher
   • opensource = 'yes':                         Has open-source experience
   • operating_system = 'Linux':                 Uses Linux

3. INTERMEDIATE LEVEL CONDITIONS (All must be TRUE)
   • years_coding < 10:                          Less than 10 years
   • highest_education IN (...):                 At least Bachelor's degree
   • operating_system = 'Linux':                 Working knowledge of Linux
   • Note: No opensource or student requirements

4. JUNIOR LEVEL CONDITIONS (All must be TRUE)
   • student = 'yes':                            Must be a student
   • years_coding < 5:                           Less than 5 years
   • opensource = 'yes':                         Has open-source experience
   • Note: No operating system requirement

5. ELSE NULL
   • Purpose:    Marks applicants who don't meet any criteria
   • Result:     These rows will be filtered out

6. HAVING position_level IS NOT NULL
   • Purpose:    Filters out disqualified applicants
   • Operation:  Removes rows where position_level = NULL
   • Result:     Only qualified applicants in output
   • Note:       HAVING is used because we're filtering on a computed column

====================================================================================
KEY CONCEPTS
====================================================================================

✓ CASE statement for conditional logic
✓ IN operator for multiple value matching
✓ Logical AND for combining multiple conditions
✓ HAVING clause for filtering computed columns
✓ Priority-based evaluation (order matters!)
✓ NULL handling for exclusion logic

IMPORTANT NOTES:
---------------
• Order of WHEN clauses is CRITICAL
• First matching condition wins
• All conditions within a WHEN must be TRUE (AND logic)
• HAVING is used instead of WHERE because position_level is computed

====================================================================================
COMMON PITFALLS & SOLUTIONS
====================================================================================

PITFALL 1: Wrong order of CASE conditions
  • Problem:  Intermediate checked before Senior
  • Result:   Senior-qualified applicants assigned Intermediate
  • Solution: Always check highest levels first

PITFALL 2: Using WHERE instead of HAVING
  • Problem:  WHERE position_level IS NOT NULL
  • Error:    Column 'position_level' doesn't exist yet
  • Solution: Use HAVING for computed columns

PITFALL 3: Incorrect IN list for education
  • Problem:  Missing 'PhD' or 'Doctorate' in education list
  • Result:   PhD holders not qualifying for Senior
  • Solution: Include all valid degree levels

PITFALL 4: Case sensitivity in string comparisons
  • Problem:  'Yes' vs 'yes' or 'linux' vs 'Linux'
  • Result:   Conditions fail due to case mismatch
  • Solution: Ensure consistent case in data and queries

====================================================================================
TEST CASES
====================================================================================

Test Case 1: Senior qualified applicant
  • Input:  Masters, 15 years, opensource=yes, Linux
  • Output: Senior

Test Case 2: Applicant qualifies for multiple levels
  • Input:  Masters, 7 years, student=yes, opensource=yes, Linux
  • Output: Intermediate (higher priority than Junior)

Test Case 3: Near-miss for Senior
  • Input:  Masters, 9 years, opensource=yes, Linux
  • Output: Intermediate (fails years_coding >= 10)

Test Case 4: Junior with advanced degree
  • Input:  Masters, student=yes, 2 years, opensource=yes, Windows
  • Output: Junior (student qualifies despite advanced degree)

Test Case 5: No qualifications
  • Input:  No Degree, 1 year, student=no, opensource=no, Windows
  • Output: Not in result set (filtered by HAVING)

====================================================================================
PERFORMANCE OPTIMIZATION
====================================================================================

Current Implementation:
  • Time Complexity:  O(n) - Single pass through all rows
  • Space Complexity: O(n) - Stores all qualified applicants

Optimization Suggestions:
  • Index on years_coding for range queries
  • Index on operating_system for frequent filtering
  • Consider materialized view if query runs frequently

====================================================================================
ALTERNATIVE APPROACHES
====================================================================================

Alternative 1: Separate queries with UNION
  • Pros: Easier to read and debug
  • Cons: Multiple scans of table, more verbose

Alternative 2: Scoring system
  • Assign points for each criterion
  • Use threshold scores for levels
  • Pros: More flexible for future changes
  • Cons: Less explicit business rules

Alternative 3: Stored procedure
  • Calculate levels in procedural code
  • Pros: Complex logic easier to implement
  • Cons: Less portable, harder to maintain

====================================================================================
END OF SOLUTION
====================================================================================
*/
