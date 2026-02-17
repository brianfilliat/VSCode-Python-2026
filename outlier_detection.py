"""
FMCG Sales Data - Outlier Detection and Replacement
====================================================

Challenge: Detect and replace outliers in sales revenue data
Method: Percentile-based approach (1st and 99th percentiles)
Output: Cleaned data saved to submission.csv

Score Achieved: 100/100 (Perfect Score!)
Date: February 7, 2026

Author: Brian Filliat
Repository: brianfilliat/VSCode-Python-2026
"""

import pandas as pd
import numpy as np
from datetime import datetime
import time
import os


# Global log storage
_execution_log = []


def log_print(*args, **kwargs):
    """
    Print to console and capture to execution log.
    
    Args:
        *args: Arguments to print
        **kwargs: Keyword arguments for print function
    """
    # Convert args to string
    message = ' '.join(str(arg) for arg in args)
    
    # Print to console
    print(message, **kwargs)
    
    # Add to log (with newline if not suppressed)
    if kwargs.get('end', '\n') == '\n':
        _execution_log.append(message + '\n')
    else:
        _execution_log.append(message)


def save_execution_log(filename=None):
    """
    Save execution log to a timestamped file.
    
    Args:
        filename (str): Optional filename. If None, generates timestamped name.
    
    Returns:
        str: The filename used
    """
    if filename is None:
        filename = f"execution_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(_execution_log)
    
    return filename


def load_data(filepath='dataset/data.csv'):
    """
    Load the sales revenue dataset.
    
    Args:
        filepath (str): Path to the CSV file
        
    Returns:
        pd.DataFrame: Loaded dataset
    """
    log_print(f"Loading data from {filepath}...")
    data = pd.read_csv(filepath)
    log_print(f"✓ Loaded {data.shape[0]} rows × {data.shape[1]} columns")
    return data


def calculate_percentile_bounds(data, column='revenue', lower=0.01, upper=0.99):
    """
    Calculate percentile bounds for outlier detection.
    
    Args:
        data (pd.DataFrame): Input dataset
        column (str): Column name to analyze
        lower (float): Lower percentile (default: 0.01 for 1st percentile)
        upper (float): Upper percentile (default: 0.99 for 99th percentile)
        
    Returns:
        tuple: (lower_bound, upper_bound)
    """
    lower_bound = data[column].quantile(lower)
    upper_bound = data[column].quantile(upper)
    log_print(f"\nPercentile Bounds:")
    log_print(f"  1st Percentile (Lower Bound): ${lower_bound:.2f}")
    log_print(f"  99th Percentile (Upper Bound): ${upper_bound:.2f}")
    return lower_bound, upper_bound


def identify_outliers(data, column='revenue', lower_bound=None, upper_bound=None):
    """
    Identify outliers in the dataset.
    
    Args:
        data (pd.DataFrame): Input dataset
        column (str): Column name to analyze
        lower_bound (float): Lower outlier threshold
        upper_bound (float): Upper outlier threshold
        
    Returns:
        tuple: (outliers_below, outliers_above, total_outliers)
    """
    outliers_below = (data[column] < lower_bound).sum()
    outliers_above = (data[column] > upper_bound).sum()
    total_outliers = outliers_below + outliers_above
    
    log_print(f"\nOutlier Detection:")
    log_print(f"  Outliers below lower bound: {outliers_below}")
    log_print(f"  Outliers above upper bound: {outliers_above}")
    log_print(f"  Total outliers: {total_outliers} ({total_outliers/len(data)*100:.2f}%)")
    
    return outliers_below, outliers_above, total_outliers


def calculate_replacement_values(data, column='revenue', lower_bound=None, upper_bound=None):
    """
    Calculate min/max values from non-outlier data for replacement.
    
    Args:
        data (pd.DataFrame): Input dataset
        column (str): Column name to analyze
        lower_bound (float): Lower outlier threshold
        upper_bound (float): Upper outlier threshold
        
    Returns:
        tuple: (min_value, max_value)
    """
    non_outlier_values = data[column][
        (data[column] >= lower_bound) & (data[column] <= upper_bound)
    ]
    min_value = non_outlier_values.min()
    max_value = non_outlier_values.max()
    
    log_print(f"\nReplacement Values (from non-outliers):")
    log_print(f"  Non-outlier count: {len(non_outlier_values)}")
    log_print(f"  Min value: ${min_value:.2f}")
    log_print(f"  Max value: ${max_value:.2f}")
    
    return min_value, max_value


def replace_outliers(data, column='revenue', lower_bound=None, upper_bound=None, 
                     min_value=None, max_value=None):
    """
    Replace outliers with min/max values from non-outlier data.
    
    Args:
        data (pd.DataFrame): Input dataset
        column (str): Column name to modify
        lower_bound (float): Lower outlier threshold
        upper_bound (float): Upper outlier threshold
        min_value (float): Replacement value for low outliers
        max_value (float): Replacement value for high outliers
        
    Returns:
        pd.DataFrame: Cleaned dataset with outliers replaced
    """
    submission = data.copy()
    
    # Count outliers before replacement
    outliers_replaced_low = (submission[column] < lower_bound).sum()
    outliers_replaced_high = (submission[column] > upper_bound).sum()
    
    # Replace outliers
    submission.loc[submission[column] < lower_bound, column] = min_value
    submission.loc[submission[column] > upper_bound, column] = max_value
    
    # Verify no outliers remain
    remaining_outliers = (
        (submission[column] < lower_bound) | (submission[column] > upper_bound)
    ).sum()
    
    log_print(f"\nOutlier Replacement:")
    log_print(f"  Outliers replaced (below): {outliers_replaced_low}")
    log_print(f"  Outliers replaced (above): {outliers_replaced_high}")
    log_print(f"  Total replacements: {outliers_replaced_low + outliers_replaced_high}")
    log_print(f"  Remaining outliers: {remaining_outliers} ✓")
    
    return submission


def save_submission(data, filepath='submission.csv'):
    """
    Save cleaned dataset to CSV file.
    
    Args:
        data (pd.DataFrame): Cleaned dataset
        filepath (str): Output file path
    """
    data.to_csv(filepath, index=False)
    log_print(f"\n✓ Submission saved to: {filepath}")
    log_print(f"  File shape: {data.shape[0]} rows × {data.shape[1]} columns")


def display_statistics(original_data, cleaned_data, column='revenue'):
    """
    Display before/after statistics comparison.
    
    Args:
        original_data (pd.DataFrame): Original dataset
        cleaned_data (pd.DataFrame): Cleaned dataset
        column (str): Column name to analyze
    """
    log_print("\n" + "="*70)
    log_print("STATISTICS COMPARISON")
    log_print("="*70)
    
    log_print("\nOriginal Data:")
    log_print(f"  Mean Revenue: ${original_data[column].mean():.2f}")
    log_print(f"  Std Deviation: ${original_data[column].std():.2f}")
    log_print(f"  Min Revenue: ${original_data[column].min():.2f}")
    log_print(f"  Max Revenue: ${original_data[column].max():.2f}")
    
    log_print("\nCleaned Data:")
    log_print(f"  Mean Revenue: ${cleaned_data[column].mean():.2f}")
    log_print(f"  Std Deviation: ${cleaned_data[column].std():.2f}")
    log_print(f"  Min Revenue: ${cleaned_data[column].min():.2f}")
    log_print(f"  Max Revenue: ${cleaned_data[column].max():.2f}")


def calculate_score(total_outliers, remaining_outliers):
    """
    Calculate the expected score based on challenge formula.
    
    Args:
        total_outliers (int): Total number of outliers detected
        remaining_outliers (int): Number of outliers remaining after replacement
        
    Returns:
        float: Expected score (0-100)
    """
    if total_outliers == 0:
        return 100.0
    score = 100 * (1 - remaining_outliers / total_outliers)
    return score


def main():
    """
    Main execution function for outlier detection and replacement.
    """
    log_print("="*70)
    log_print("FMCG Sales Data - Outlier Detection and Replacement")
    log_print("="*70)
    log_print(f"Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # Start timer
    start_time = time.time()
    
    # Step 1: Load data
    data = load_data('dataset/data.csv')
    
    # Step 2: Calculate percentile bounds
    lower_bound, upper_bound = calculate_percentile_bounds(data)
    
    # Step 3: Identify outliers
    outliers_below, outliers_above, total_outliers = identify_outliers(
        data, lower_bound=lower_bound, upper_bound=upper_bound
    )
    
    # Step 4: Calculate replacement values
    min_value, max_value = calculate_replacement_values(
        data, lower_bound=lower_bound, upper_bound=upper_bound
    )
    
    # Step 5: Replace outliers
    submission = replace_outliers(
        data, 
        lower_bound=lower_bound, 
        upper_bound=upper_bound,
        min_value=min_value, 
        max_value=max_value
    )
    
    # Step 6: Save submission
    save_submission(submission, 'submission.csv')
    
    # Display statistics
    display_statistics(data, submission)
    
    # Calculate and display score
    remaining_outliers = (
        (submission['revenue'] < lower_bound) | (submission['revenue'] > upper_bound)
    ).sum()
    score = calculate_score(total_outliers, remaining_outliers)
    
    # Final summary
    total_time = time.time() - start_time
    log_print("\n" + "="*70)
    log_print("EXECUTION SUMMARY")
    log_print("="*70)
    log_print(f"End Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    log_print(f"Total Execution Time: {total_time:.4f} seconds")
    log_print(f"\nExpected Score: {score:.0f}/100")
    log_print("="*70)
    log_print("✓ STATUS: COMPLETE - All outliers replaced successfully!")
    log_print("="*70)
    
    # Save execution log
    log_filename = save_execution_log()
    print(f"\n📄 Execution log saved to: {log_filename}")
    print(f"📊 Submission file saved to: submission.csv")


if __name__ == "__main__":
    main()
