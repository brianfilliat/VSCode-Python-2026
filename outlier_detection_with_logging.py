"""
FMCG Sales Data - Outlier Detection with Logging
=================================================

Full-featured script with comprehensive execution logging.
Creates timestamped log files for audit trail.

Usage:
    python outlier_detection_with_logging.py

Output:
    - submission.csv (cleaned data)
    - execution_log_YYYYMMDD_HHMMSS.txt (detailed log)
"""

import pandas as pd
import numpy as np
from datetime import datetime
import time


def main():
    """Execute outlier detection with comprehensive logging."""
    
    # Start execution timer
    start_time = time.time()
    execution_log = []
    
    # Initialize log
    log_entry = f"{'='*70}\nEXECUTION LOG - Outlier Detection and Replacement\n{'='*70}\n"
    log_entry += f"Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
    log_entry += f"Task: Detect and replace outliers in sales revenue data\n\n"
    execution_log.append(log_entry)
    print(log_entry)
    
    # Step 1: Read the dataset
    step_start = time.time()
    data = pd.read_csv('dataset/data.csv')
    step_time = time.time() - step_start
    
    log_entry = f"STEP 1: Load Dataset\n"
    log_entry += f"  - File: dataset/data.csv\n"
    log_entry += f"  - Shape: {data.shape[0]} rows x {data.shape[1]} columns\n"
    log_entry += f"  - Columns: {', '.join(data.columns.tolist())}\n"
    log_entry += f"  - Time: {step_time:.4f} seconds\n"
    log_entry += f"  - Status: [SUCCESS]\n\n"
    execution_log.append(log_entry)
    print(log_entry)
    
    # Step 2: Calculate 1st and 99th percentiles (outlier bounds)
    step_start = time.time()
    lower_bound = data['revenue'].quantile(0.01)
    upper_bound = data['revenue'].quantile(0.99)
    step_time = time.time() - step_start
    
    log_entry = f"STEP 2: Calculate Percentile Bounds\n"
    log_entry += f"  - 1st Percentile (Lower Bound): ${lower_bound:.2f}\n"
    log_entry += f"  - 99th Percentile (Upper Bound): ${upper_bound:.2f}\n"
    log_entry += f"  - Time: {step_time:.4f} seconds\n"
    log_entry += f"  - Status: [SUCCESS]\n\n"
    execution_log.append(log_entry)
    print(log_entry)
    
    # Step 3: Identify outliers
    step_start = time.time()
    outliers_below = (data['revenue'] < lower_bound).sum()
    outliers_above = (data['revenue'] > upper_bound).sum()
    total_outliers = outliers_below + outliers_above
    step_time = time.time() - step_start
    
    log_entry = f"STEP 3: Identify Outliers\n"
    log_entry += f"  - Outliers below lower bound: {outliers_below}\n"
    log_entry += f"  - Outliers above upper bound: {outliers_above}\n"
    log_entry += f"  - Total outliers: {total_outliers}\n"
    log_entry += f"  - Outlier percentage: {(total_outliers/len(data)*100):.2f}%\n"
    log_entry += f"  - Time: {step_time:.4f} seconds\n"
    log_entry += f"  - Status: [SUCCESS]\n\n"
    execution_log.append(log_entry)
    print(log_entry)
    
    # Step 4: Find min and max values excluding outliers
    step_start = time.time()
    non_outlier_values = data['revenue'][(data['revenue'] >= lower_bound) & (data['revenue'] <= upper_bound)]
    min_value = non_outlier_values.min()
    max_value = non_outlier_values.max()
    step_time = time.time() - step_start
    
    log_entry = f"STEP 4: Calculate Replacement Values\n"
    log_entry += f"  - Non-outlier count: {len(non_outlier_values)}\n"
    log_entry += f"  - Min value (excluding outliers): ${min_value:.2f}\n"
    log_entry += f"  - Max value (excluding outliers): ${max_value:.2f}\n"
    log_entry += f"  - Time: {step_time:.4f} seconds\n"
    log_entry += f"  - Status: [SUCCESS]\n\n"
    execution_log.append(log_entry)
    print(log_entry)
    
    # Step 5: Replace outliers
    step_start = time.time()
    submission = data.copy()
    outliers_replaced_low = (submission['revenue'] < lower_bound).sum()
    outliers_replaced_high = (submission['revenue'] > upper_bound).sum()
    
    submission.loc[submission['revenue'] < lower_bound, 'revenue'] = min_value
    submission.loc[submission['revenue'] > upper_bound, 'revenue'] = max_value
    step_time = time.time() - step_start
    
    # Verify no outliers remain
    remaining_outliers = ((submission['revenue'] < lower_bound) | (submission['revenue'] > upper_bound)).sum()
    
    log_entry = f"STEP 5: Replace Outliers\n"
    log_entry += f"  - Outliers replaced (below): {outliers_replaced_low}\n"
    log_entry += f"  - Outliers replaced (above): {outliers_replaced_high}\n"
    log_entry += f"  - Total replacements: {outliers_replaced_low + outliers_replaced_high}\n"
    log_entry += f"  - Remaining outliers: {remaining_outliers}\n"
    log_entry += f"  - Time: {step_time:.4f} seconds\n"
    log_entry += f"  - Status: [SUCCESS]\n\n"
    execution_log.append(log_entry)
    print(log_entry)
    
    # Step 6: Save to submission.csv
    step_start = time.time()
    submission.to_csv('submission.csv', index=False)
    step_time = time.time() - step_start
    
    log_entry = f"STEP 6: Save Submission File\n"
    log_entry += f"  - Output file: submission.csv\n"
    log_entry += f"  - File shape: {submission.shape[0]} rows x {submission.shape[1]} columns\n"
    log_entry += f"  - Time: {step_time:.4f} seconds\n"
    log_entry += f"  - Status: [SUCCESS]\n\n"
    execution_log.append(log_entry)
    print(log_entry)
    
    # Calculate statistics
    total_time = time.time() - start_time
    original_mean = data['revenue'].mean()
    cleaned_mean = submission['revenue'].mean()
    original_std = data['revenue'].std()
    cleaned_std = submission['revenue'].std()
    
    # Final summary
    log_entry = f"{'='*70}\nEXECUTION SUMMARY\n{'='*70}\n"
    log_entry += f"End Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
    log_entry += f"Total Execution Time: {total_time:.4f} seconds\n\n"
    log_entry += f"STATISTICS:\n"
    log_entry += f"  Original Data:\n"
    log_entry += f"    - Mean Revenue: ${original_mean:.2f}\n"
    log_entry += f"    - Std Deviation: ${original_std:.2f}\n"
    log_entry += f"    - Min Revenue: ${data['revenue'].min():.2f}\n"
    log_entry += f"    - Max Revenue: ${data['revenue'].max():.2f}\n\n"
    log_entry += f"  Cleaned Data:\n"
    log_entry += f"    - Mean Revenue: ${cleaned_mean:.2f}\n"
    log_entry += f"    - Std Deviation: ${cleaned_std:.2f}\n"
    log_entry += f"    - Min Revenue: ${submission['revenue'].min():.2f}\n"
    log_entry += f"    - Max Revenue: ${submission['revenue'].max():.2f}\n\n"
    log_entry += f"EXPECTED SCORE:\n"
    log_entry += f"  Score = 100 x (1 - {remaining_outliers}/{total_outliers}) = {100 * (1 - remaining_outliers/total_outliers):.0f}%\n\n"
    log_entry += f"{'='*70}\n"
    log_entry += f"STATUS: [COMPLETE] - All outliers replaced successfully!\n"
    log_entry += f"{'='*70}\n"
    execution_log.append(log_entry)
    print(log_entry)
    
    # Save execution log to file with UTF-8 encoding
    log_filename = f"execution_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
    with open(log_filename, 'w', encoding='utf-8') as f:
        f.write(''.join(execution_log))
    
    print(f"\nExecution log saved to: {log_filename}")
    print(f"Submission file saved to: submission.csv")
    print(f"\n✓ Complete! Outliers replaced and saved to submission.csv")


if __name__ == "__main__":
    main()
