# Python Scripts - Outlier Detection

## 📋 Overview

Three Python script versions of the outlier detection solution that achieved a perfect score (100/100) in the FMCG Sales Data challenge.

**Challenge:** Detect and replace outliers in sales revenue data  
**Method:** Percentile-based (1st and 99th percentiles)  
**Result:** Perfect Score 100/100

---

## 📄 Available Scripts

### 1. `outlier_detection_simple.py` ⚡ **(RECOMMENDED FOR QUICK USE)**

**Best for:** Quick execution, minimal output

```bash
# Run with virtual environment
.\.venv\Scripts\python.exe outlier_detection_simple.py

# Or if venv is activated
python outlier_detection_simple.py
```

**Features:**
- 🎯 Single function design (~60 lines)
- ⚡ Fast execution
- 📊 Essential output only
- 💾 Creates submission.csv

**Output:**
```
FMCG Sales Data - Outlier Detection (Simple)
Loading data from dataset/data.csv...
Original shape: (40, 3)
Bounds: $1.07 to $4805.00
Total outliers detected: 2
Expected Score: 100/100
✓ Saved to submission.csv
```

---

### 2. `outlier_detection.py` 🏆 **(RECOMMENDED FOR PRODUCTION)**

**Best for:** Professional use, modular code, readability

```bash
# Run with virtual environment
.\.venv\Scripts\python.exe outlier_detection.py

# Or if venv is activated
python outlier_detection.py
```

**Features:**
- 🎨 Modular design with separate functions
- 📚 Professional docstrings
- 📊 Detailed statistics comparison
- 🔧 Easy to modify and extend
- ✅ Clear step-by-step output
- 📝 **NEW: Automatic execution logging with timestamped log files**

**Output Files:**
- ✅ `submission.csv` - Cleaned dataset
- ✅ `execution_log_YYYYMMDD_HHMMSS.txt` - Complete execution log

**Key Functions:**
- `load_data()` - Load dataset
- `calculate_percentile_bounds()` - Find outlier thresholds
- `identify_outliers()` - Count outliers
- `calculate_replacement_values()` - Get min/max from non-outliers
- `replace_outliers()` - Replace and validate
- `save_submission()` - Export cleaned data
- `display_statistics()` - Show before/after stats
- `calculate_score()` - Compute expected score
- `log_print()` - Print to console and log
- `save_execution_log()` - Save timestamped log file

**Output:**
```
FMCG Sales Data - Outlier Detection and Replacement
Start Time: 2026-02-07 17:10:57

✓ Loaded 40 rows × 3 columns
Percentile Bounds: $1.07 to $4805.00
Outlier Detection: 2 total outliers (5.00%)
Replacement Values: $1.50 (min), $4500.00 (max)
Outlier Replacement: 2 replacements, 0 remaining ✓

STATISTICS COMPARISON
Original: Mean $705.74, Range $0.80-$5000.00
Cleaned: Mean $693.26, Range $1.50-$4500.00

Expected Score: 100/100
✓ STATUS: COMPLETE

📄 Execution log saved to: execution_log_20260207_171613.txt
📊 Submission file saved to: submission.csv
```

---

### 3. `outlier_detection_with_logging.py` 📝 **(RECOMMENDED FOR AUDIT TRAIL)**

**Best for:** Compliance, debugging, detailed tracking

```bash
# Run with virtual environment
.\.venv\Scripts\python.exe outlier_detection_with_logging.py

# Or if venv is activated
python outlier_detection_with_logging.py
```

**Features:**
- 📝 Comprehensive execution logging
- ⏱️ Step-by-step timing
- 📄 Creates timestamped log files
- 🔍 Full audit trail
- 📊 Detailed statistics

**Output Files:**
- `submission.csv` - Cleaned data
- `execution_log_YYYYMMDD_HHMMSS.txt` - Detailed log

**Log File Contents:**
```
======================================================================
EXECUTION LOG - Outlier Detection and Replacement
======================================================================
Start Time: 2026-02-07 17:10:57

STEP 1: Load Dataset
  - File: dataset/data.csv
  - Shape: 40 rows x 3 columns
  - Columns: order_id, date, revenue
  - Time: 0.0611 seconds
  - Status: [SUCCESS]

STEP 2: Calculate Percentile Bounds
  - 1st Percentile: $1.07
  - 99th Percentile: $4805.00
  - Time: 0.0023 seconds
  - Status: [SUCCESS]

[...additional steps...]

EXECUTION SUMMARY
End Time: 2026-02-07 17:10:57
Total Execution Time: 0.1583 seconds
Expected Score: 100%
STATUS: [COMPLETE]
```

---

## 🚀 Quick Start Guide

### Prerequisites

1. **Python Environment Setup**
   ```bash
   # Ensure virtual environment is activated
   .\.venv\Scripts\Activate.ps1  # PowerShell
   # or
   source .venv/bin/activate  # Linux/Mac
   ```

2. **Required Packages**
   ```bash
   pip install pandas numpy
   ```

3. **Data File**
   - Ensure `dataset/data.csv` exists with columns: order_id, date, revenue

### Basic Usage

**Option 1: Quick Run (Simple Version)**
```bash
python outlier_detection_simple.py
```

**Option 2: Production Run (Full Version)**
```bash
python outlier_detection.py
```

**Option 3: With Logging (Audit Trail)**
```bash
python outlier_detection_with_logging.py
```

### Advanced Usage

**Custom Data File:**
```python
# Modify the script or use functions directly
from outlier_detection import detect_and_replace_outliers

result = detect_and_replace_outliers(
    input_file='your_data.csv',
    output_file='cleaned_data.csv',
    column='revenue',
    lower_percentile=0.01,
    upper_percentile=0.99
)
```

---

## 📊 How It Works

### Algorithm Steps

1. **Calculate Percentile Bounds**
   ```python
   lower_bound = data['revenue'].quantile(0.01)  # 1st percentile
   upper_bound = data['revenue'].quantile(0.99)  # 99th percentile
   ```

2. **Identify Outliers**
   ```python
   outliers = (data['revenue'] < lower_bound) | (data['revenue'] > upper_bound)
   ```

3. **Find Replacement Values** (CRITICAL!)
   ```python
   # Use non-outlier min/max, NOT percentile bounds
   non_outliers = data[(data >= lower_bound) & (data <= upper_bound)]
   min_value = non_outliers.min()
   max_value = non_outliers.max()
   ```

4. **Replace Outliers**
   ```python
   data.loc[data['revenue'] < lower_bound, 'revenue'] = min_value
   data.loc[data['revenue'] > upper_bound, 'revenue'] = max_value
   ```

5. **Validate and Save**
   ```python
   # Verify no outliers remain
   remaining = ((data < lower_bound) | (data > upper_bound)).sum()
   data.to_csv('submission.csv', index=False)
   ```

---

## 🎯 Choosing the Right Script

| Need | Use This Script | Why |
|------|----------------|-----|
| Quick result | `outlier_detection_simple.py` | Minimal code, fast |
| Production code | `outlier_detection.py` | Modular, professional, logging |
| Audit trail | `outlier_detection.py` or `outlier_detection_with_logging.py` | Both have detailed logging |
| Import as module | `outlier_detection.py` | Best function design |
| Learning/Teaching | `outlier_detection.py` | Clear structure |
| Debugging | `outlier_detection.py` or `outlier_detection_with_logging.py` | Step-by-step logs |

---
### All Scripts Create:
- ✅ `submission.csv` - Cleaned dataset (same structure as input)

### Scripts with Logging Create:
- ✅ `execution_log_YYYYMMDD_HHMMSS.txt` - Timestamped log file
  - **outlier_detection.py** ✓ (Full-featured with logging)
  - **outlier_detection_with_logging.py** ✓ (Dedicated logging version)t)

Logging script also creates:
- ✅ `execution_log_YYYYMMDD_HHMMSS.txt` - Timestamped log file

---

## ⚙️ Configuration

### Modifying Percentiles

```python
# In any script, change these values:
lower_percentile = 0.01  # 1st percentile
upper_percentile = 0.99  # 99th percentile

# For stricter outlier detection:
lower_percentile = 0.05  # 5th percentile
upper_percentile = 0.95  # 95th percentile
```

### Different Columns

```python
# Change the column name:
column = 'revenue'  # Default
column = 'sales'    # Or any other numeric column
```

### Custom Input/Output

```python
input_file = 'dataset/data.csv'      # Default input
output_file = 'submission.csv'       # Default output
```

---

## 🧪 Testing

### Verify Installation

```bash
# Test imports
python -c "import pandas; import numpy; print('✓ All packages installed')"
```

### Run Tests

```bash
# Test simple version
python outlier_detection_simple.py

# Test full version
python outlier_detection.py

# Test with logging
python outlier_detection_with_logging.py
```

### Expected Results

**For dataset/data.csv:**
- Total outliers: 2 (5.0%)
- Outliers replaced: 2
- Remaining outliers: 0
- Expected score: 100/100

---

## 🐛 Troubleshooting

### Import Error: No module named 'pandas'

**Solution:**
```bash
# Make sure virtual environment is activated
.\.venv\Scripts\Activate.ps1

# Install requirements
pip install pandas numpy
```

### FileNotFoundError: 'dataset/data.csv'

**Solution:**
- Ensure you're running from the project root directory
- Check that `dataset/data.csv` exists
- Use absolute path if needed

### Unicode Encoding Error (Windows)

**Solution:**
- Scripts use UTF-8 encoding by default
- If issues persist, set console encoding:
  ```powershell
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  ```

---

## 📚 Additional Resources

**Related Files:**
- `outlier_detection_sales_revenue.ipynb` - Jupyter notebook version
- `README.md` - Main project documentation
- `ASSESSMENT-COMPLETE-DOCUMENTATION.md` - Full assessment details

**Documentation:**
- pandas: https://pandas.pydata.org/docs/
- numpy: https://numpy.org/doc/

---

## ✨ Features Comparison

| Feature | Simple | Full320 | ~220 |
| Execution Time | Fast | Fast | Medium |
| Modular Functions | ❌ | ✅ | ❌ |
| Docstrings | Minimal | Full | Minimal |
| Console Output | Basic | Detailed | Detailed |
| Log File | ❌ | ✅ | ✅ |
| Statistics | Basic | Detailed | Detailed |
| Timing Info | ❌ | ✅ | ✅ |
| Easy to Modify | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| Audit Trail | ❌ | ✅ | ✅ |
| Best For | Quick runs | Production code | Compliance |
| Easy to Modify | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| Audit Trail | ❌ | ❌ | ✅ |

---

## 🎓 Key Learnings

**Why This Solution Works:**
1. ✅ Correct percentile calculation (1st & 99th)
2. ✅ Use non-outlier min/max for replacement (NOT bounds!)
3. ✅ Verify no outliers remain after replacement
4. ✅ Efficient pandas vectorized operations

**Common Mistakes to Avoid:**
- ❌ Using percentile bounds as replacement values
- ❌ Not verifying outliers are removed
- ❌ Modifying original data in place
- ❌ Forgetting to validate output

---

## 📝 License

Educational purposes - BairesDev Technical Assessment  
**Author:** Brian Filliat  
**Repository:** brianfilliat/VSCode-Python-2026  
**Date:** February 7, 2026

---

## 🎉 Achievement

**Perfect Score: 100/100** 🏆
- Score: 100/100
- Time: 0.618 seconds (< 5 sec limit)
- Memory: 195.8 MB (< 256 MB limit)
- Status: ✅ ACCEPTED

---

*For detailed documentation, see [ASSESSMENT-COMPLETE-DOCUMENTATION.md](ASSESSMENT-COMPLETE-DOCUMENTATION.md)*
