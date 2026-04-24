# VSCode-Python-2026

Python Development Workspace - BairesDev Technical Assessments 2026

## 🏆 Project Overview

This repository contains solutions to various technical assessments covering algorithms, data structures, SQL database queries, ETL/Data Engineering concepts, and Python data science challenges completed in February 2026.

### Assessment Results

**Status:** ✅ All Challenges Completed  
**Overall Performance:** Perfect Scores Achieved  
**Date:** February 2026

## 📚 Contents

### 1. Algorithms & Data Structures (8 Questions)
- ✅ Merge Sort complexity analysis (O(n log n))
- ✅ QuickSort average case analysis (O(n log n))
- ✅ Binary Search for sorted arrays (O(log n))
- ✅ Stack data structure use cases
- ✅ Balanced tree operations (O(log n))
- ✅ Tree properties and relationships
- ✅ Tree traversal methods (Inorder, Preorder, Postorder)
- ✅ Recursive algorithms

### 2. SQL Database Challenges (4 Problems)
All solutions located in `MYSQL-DATA-2026/` directory:

#### Challenge 1: Employee Salary Aggregations
- Calculate SUM, MIN, MAX of employee salaries
- **File:** `employee_salary_aggregations.sql`

#### Challenge 2: Travel Agency Trip Counter
- Count trips between locations with alphabetical ordering
- **File:** `travel_agency_trip_counter.sql`

#### Challenge 3: Customer Order Analysis
- Calculate total spending per customer with name formatting
- **File:** `customer_order_analysis.sql`

#### Challenge 4: Job Applicant Position Assignment
- Assign Senior/Intermediate/Junior levels based on qualifications
- **File:** `job_applicant_position_assignment.sql`

### 3. ETL & Data Engineering (7 Questions)
- ✅ ETL testing purposes and methodologies
- ✅ Common data sources (databases, flat files, web pages)
- ✅ Transformation operations (joins, filtering, aggregation)
- ✅ Benefits of ETL tools vs. custom scripts
- ✅ Common ETL tools (Talend, Informatica, MuleSoft)
- ✅ Data warehouse vs. data lake architecture
- ✅ Challenges faced by ETL data engineers

**Documentation:** `MYSQL-DATA-2026/Data Engineer Coding Challenge.md`

### 4. Python Data Science Challenge: Outlier Detection 🏆

**Challenge:** FMCG Sales Data - Detect and Replace Outliers  
**Score:** 🎉 100/100 (Perfect Score!)  
**Status:** ✅ ACCEPTED  
**Execution Time:** 0.618 seconds  
**Memory Usage:** 195.8 MB

#### Problem Statement
Working with sales data from an FMCG company to detect and replace outliers in the revenue column using a percentile-based approach.

#### Solution Approach
- Calculate 1st and 99th percentiles as outlier bounds
- Identify values outside these bounds
- Replace outliers with min/max from non-outlier data
- Validate and save cleaned data

#### Key Features
- ✅ Percentile-based outlier detection (1st/99th)
- ✅ Pandas/NumPy data manipulation
- ✅ Comprehensive execution logging system
- ✅ Step-by-step documentation
- ✅ Performance metrics tracking
- ✅ Automatic audit trail generation

#### Files

**Jupyter Notebook (Interactive):**
- **Notebook:** `outlier_detection_sales_revenue.ipynb` - Full solution with documentation

**Python Scripts (Standalone):**
- **Full-Featured:** `outlier_detection.py` - Modular design, production-ready
- **Simple:** `outlier_detection_simple.py` - Quick execution, minimal code
- **With Logging:** `outlier_detection_with_logging.py` - Comprehensive audit trail

**Data Files:**
- **Dataset:** `dataset/data.csv` (40 rows)
- **Output:** `submission.csv`
- **Logs:** `execution_log_YYYYMMDD_HHMMSS.txt`

**See:** [PYTHON-SCRIPTS-GUIDE.md](PYTHON-SCRIPTS-GUIDE.md) for detailed usage instructions

**Terraform Guide:** [TERRAFORM-INSTALLATION-AND-CONFIGURATION.md](TERRAFORM-INSTALLATION-AND-CONFIGURATION.md)

## 🛠️ Technical Stack

**Programming Languages:**
- Python 3.14.2
- SQL (MySQL dialect)

**Python Libraries:**
- pandas 2.x - Data manipulation and analysis
- numpy 1.x - Numerical computing
- jupyter - Interactive notebook environment

**Development Environment:**
- VS Code with Python extension
- Jupyter Notebook integration
- Virtual Environment (.venv)
- Git version control

**Database:**
- MySQL for SQL challenges

## 📂 Project Structure

```
Python-vscode-2026/
│
├── README.md                              (This file)
├── CodeCitations.md                       (Code references)
│
├── Algorithm Challenges/
│   ├── array_algorithms_challenge.py
│   ├── counting_bits.py
│   ├── getMaximumSubarray.py
│   ├── list_operations_challenge.py
│   ├── permutation_subarray_challenge.py
│   ├── recursion_algorithms_challenge.py
│   ├── solvePeaksProblem.py
│   ├── string_algorithms_challenge.py
│   └── string_manipulation_challenge.py
│
├── MYSQL-DATA-2026/                       (SQL & Database Files)
│   ├── Data Engineer Coding Challenge.md
│   ├── employee_salary_aggregations.sql
│   ├── travel_agency_trip_counter.sql
│   ├── customer_order_analysis.sql
│   ├── job_applicant_position_assignment.sql
│   ├── database_queries.py
│   ├── PYMySQLdatabase_queries.py
│   └── sqlite3-database-queries.py
│
├── Data Science Challenge/
│   ├── outlier_detection_sales_revenue.ipynb
│   ├── submission.csv
│   ├── execution_log_*.txt
│   └── dataset/
│       └── data.csv
│
├── Session Outputs/
│   ├── BairesDev-Assement-SESSION OUTPUT-02-05-2026.txt
│   ├── BairesDev2-Assement2-SESSION2 OUTPUT-02-05-2026.txt
│   ├── BairesDev3-Assement3-SESSION3-OUTPUT-02-07-2026.txt
│   ├── Python-Data-Science-Challenge-SESSION-OUTPUT-02-07-2026.txt
│   └── Outlier-Detection-Challenge-SESSION-OUTPUT-02-07-2026.txt
│
└── filliat-Assement-notes-2026/
    └── [Assessment context and notes]
```

## 🚀 Getting Started

### Prerequisites
```bash
# Python 3.14.2 or higher
python --version

# Virtual environment
python -m venv .venv
```

### Installation

1. Clone the repository:
```bash
git clone https://github.com/brianfilliat/VSCode-Python-2026.git
cd VSCode-Python-2026
```

2. Activate virtual environment:
```powershell
# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# Linux/Mac
source .venv/bin/activate
```

3. Install required packages:
```bash
pip install pandas numpy jupyter
```

4. Launch Jupyter Notebook or run Python scripts:
```bash
# Option 1: Jupyter Notebook (Interactive)
jupyter notebook outlier_detection_sales_revenue.ipynb

# Option 2: Python Script (Quick)
python outlier_detection_simple.py

# Option 3: Python Script (Full-featured)
python outlier_detection.py

# Option 4: Python Script (With Logging)
python outlier_detection_with_logging.py
```

**See [PYTHON-SCRIPTS-GUIDE.md](PYTHON-SCRIPTS-GUIDE.md) for detailed script usage and comparisons.**

## 📊 Assessment Highlights

### Perfect Score Achievement: Outlier Detection Challenge

**Key Success Factors:**
1. **Correct Algorithm Implementation**
   - Proper percentile calculation using `quantile(0.01)` and `quantile(0.99)`
   - Replacement with non-outlier min/max (not percentile bounds)
   - Efficient pandas vectorized operations

2. **Comprehensive Validation**
   - Verified no outliers remain after replacement
   - Performance metrics tracking (time, memory)
   - Data integrity checks

3. **Professional Documentation**
   - Step-by-step execution logging
   - Automated audit trail generation
   - Statistics comparison (before/after)
   - Detailed code comments

### SQL Expertise Demonstrated

**Advanced SQL Features Used:**
- Aggregate functions (SUM, MIN, MAX, COUNT)
- String manipulation (CONCAT, UPPER)
- JOINs (INNER JOIN for multi-table queries)
- GROUP BY with multiple columns
- Complex CASE statements
- HAVING clause for filtering aggregated results
- Multi-column ORDER BY (ASC/DESC)

### Data Engineering Knowledge

**ETL Concepts Covered:**
- Pipeline design and testing
- Data source identification
- Transformation operations
- Tool selection criteria
- Data warehouse vs. data lake
- Common challenges and solutions

## 🎯 Learning Outcomes

### Skills Developed
- ✅ Algorithm analysis and complexity evaluation
- ✅ SQL query optimization and best practices
- ✅ Data cleaning and preprocessing techniques
- ✅ Statistical outlier detection methods
- ✅ Python data manipulation with pandas
- ✅ ETL pipeline design principles
- ✅ Professional documentation practices
- ✅ Performance monitoring and optimization

### Technical Proficiencies
- Python programming (advanced level)
- SQL database querying (MySQL)
- Data analysis with pandas/numpy
- Jupyter notebook development
- Git version control
- VS Code development environment
- Virtual environment management

## 📖 Documentation

Each challenge includes detailed documentation:

- **SQL Challenges:** Comprehensive markdown files with problem statements, table structures, sample data, expected outputs, and detailed explanations
- **Python Challenge:** Jupyter notebook with step-by-step implementation, markdown documentation, execution logs, and results analysis
- **Session Outputs:** Complete conversation logs capturing all questions, answers, and implementation details

## 🔍 Code Quality

### Best Practices Implemented
- Clean, readable code with proper naming conventions
- Comprehensive comments and documentation
- Modular design with reusable functions
- Error handling and validation
- Performance optimization
- Memory efficiency
- Professional logging and monitoring

### Testing & Validation
- All SQL queries tested with sample data
- Python solution validated against test cases
- Performance metrics within specified limits
- Data integrity verification
- Edge case handling

## 📝 Session Outputs

Complete session logs documenting the entire assessment process:

1. **BairesDev-Assement-SESSION OUTPUT-02-05-2026.txt**
   - Initial algorithm and data structure questions
   - SQL challenge solutions

2. **BairesDev2-Assement2-SESSION2 OUTPUT-02-05-2026.txt**
   - Continued technical assessments
   - Additional problem-solving

3. **BairesDev3-Assement3-SESSION3-OUTPUT-02-07-2026.txt**
   - Complete assessment with 19 questions
   - Algorithm, SQL, and ETL coverage

4. **Python-Data-Science-Challenge-SESSION-OUTPUT-02-07-2026.txt**
   - Detailed outlier detection challenge documentation
   - Complete implementation guide

5. **Outlier-Detection-Challenge-SESSION-OUTPUT-02-07-2026.txt**
   - Concise challenge summary
   - Results and key takeaways

## 🤝 Contributing

This is a personal assessment project. However, if you find any issues or have suggestions for improvements, feel free to open an issue or submit a pull request.

## 📄 License

This project is for educational and assessment purposes.

## 👤 Author

**Brian Filliat**
- GitHub: [@brianfilliat](https://github.com/brianfilliat)
- Repository: [VSCode-Python-2026](https://github.com/brianfilliat/VSCode-Python-2026)

## 🙏 Acknowledgments

- BairesDev for providing comprehensive technical assessments
- FMCG company case study for the outlier detection challenge
- Open source community for pandas, numpy, and Jupyter

## 📅 Timeline

- **February 5, 2026:** Initial algorithms and SQL challenges completed
- **February 7, 2026:** ETL questions and Python data science challenge completed with perfect score
- **Status:** All assessments completed successfully ✅

---

**Last Updated:** February 7, 2026  
**Status:** Complete ✅  
**Overall Result:** Perfect Scores Achieved 🏆
