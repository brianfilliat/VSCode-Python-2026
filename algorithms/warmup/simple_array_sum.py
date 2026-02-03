"""
Problem: Simple Array Sum
URL: https://www.hackerrank.com/challenges/simple-array-sum/problem

Description:
Given an array of integers, find the sum of its elements.

Example:
ar = [1, 2, 3]
Return 6.

Function Description:
Complete the simpleArraySum function in the editor below. It must return the sum 
of the array elements as an integer.

simpleArraySum has the following parameter(s):
- ar: an array of integers

Returns:
- int: the sum of the array's elements

Constraints:
0 < n ≤ 10^4
0 < ar[i] ≤ 10^4
"""


def simpleArraySum(ar):
    """
    Calculate the sum of array elements.
    
    Args:
        ar (list): Array of integers
    
    Returns:
        int: Sum of all elements in the array
    """
    return sum(ar)


if __name__ == '__main__':
    # Test cases
    print(simpleArraySum([1, 2, 3, 4, 10, 11]))  # Expected: 31
    print(simpleArraySum([5, 5, 5, 5]))  # Expected: 20
    
    # HackerRank input format (uncomment to use)
    # ar_count = int(input().strip())
    # ar = list(map(int, input().rstrip().split()))
    # result = simpleArraySum(ar)
    # print(result)
