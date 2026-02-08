"""
FMCG Sales Data - Outlier Detection (Simple Version)
=====================================================

Quick script for detecting and replacing outliers in sales revenue data.
Uses 1st and 99th percentiles as bounds.

Usage:
    python outlier_detection_simple.py

Output:
    - submission.csv (cleaned data)
    - Console output with results
"""

import pandas as pd


def detect_and_replace_outliers(input_file='dataset/data.csv', 
                                  output_file='submission.csv',
                                  column='revenue',
                                  lower_percentile=0.01,
                                  upper_percentile=0.99):
    """
    Detect and replace outliers in a dataset.
    
    Args:
        input_file (str): Path to input CSV file
        output_file (str): Path to output CSV file
        column (str): Column name to process
        lower_percentile (float): Lower percentile bound (default: 0.01)
        upper_percentile (float): Upper percentile bound (default: 0.99)
    
    Returns:
        pd.DataFrame: Cleaned dataset
    """
    # Load data
    print(f"Loading data from {input_file}...")
    data = pd.read_csv(input_file)
    print(f"Original shape: {data.shape}")
    
    # Calculate percentile bounds
    lower_bound = data[column].quantile(lower_percentile)
    upper_bound = data[column].quantile(upper_percentile)
    print(f"\nBounds: ${lower_bound:.2f} to ${upper_bound:.2f}")
    
    # Identify outliers
    total_outliers = ((data[column] < lower_bound) | (data[column] > upper_bound)).sum()
    print(f"Total outliers detected: {total_outliers}")
    
    # Find replacement values from non-outliers
    non_outliers = data[column][(data[column] >= lower_bound) & (data[column] <= upper_bound)]
    min_value = non_outliers.min()
    max_value = non_outliers.max()
    print(f"Replacement values: ${min_value:.2f} (min), ${max_value:.2f} (max)")
    
    # Replace outliers
    submission = data.copy()
    submission.loc[submission[column] < lower_bound, column] = min_value
    submission.loc[submission[column] > upper_bound, column] = max_value
    
    # Verify
    remaining = ((submission[column] < lower_bound) | (submission[column] > upper_bound)).sum()
    print(f"Remaining outliers: {remaining}")
    
    # Calculate score
    score = 100 * (1 - remaining / total_outliers) if total_outliers > 0 else 100
    print(f"\nExpected Score: {score:.0f}/100")
    
    # Save
    submission.to_csv(output_file, index=False)
    print(f"✓ Saved to {output_file}")
    
    return submission


if __name__ == "__main__":
    # Run the outlier detection and replacement
    print("="*60)
    print("FMCG Sales Data - Outlier Detection (Simple)")
    print("="*60 + "\n")
    
    result = detect_and_replace_outliers()
    
    print("\n" + "="*60)
    print("✓ Complete!")
    print("="*60)
