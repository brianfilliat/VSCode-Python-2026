"""
Problem: Arrays - DS
URL: https://www.hackerrank.com/challenges/arrays-ds/problem

Description:
An array is a type of data structure that stores elements of the same type in a 
contiguous block of memory. In an array, A, of size N, each memory location has 
some unique index, i (where 0 ≤ i < N), that can be referenced as A[i] or Ai.

Reverse an array of integers.

Example:
A = [1, 4, 3, 2]
Return [2, 3, 4, 1].

Function Description:
Complete the function reverseArray in the editor below.

reverseArray has the following parameter(s):
- int a[n]: the array to reverse

Returns:
- int[n]: the reversed array

Constraints:
1 ≤ n ≤ 10^3
1 ≤ a[i] ≤ 10^4, where a[i] is the ith element of the array
"""


def reverseArray(a):
    """
    Reverse an array.
    
    Args:
        a (list): Array to reverse
    
    Returns:
        list: Reversed array
    """
    return a[::-1]


if __name__ == '__main__':
    # Test cases
    print(reverseArray([1, 4, 3, 2]))  # Expected: [2, 3, 4, 1]
    print(reverseArray([5, 10, 15, 20]))  # Expected: [20, 15, 10, 5]
    
    # HackerRank input format (uncomment to use)
    # arr_count = int(input().strip())
    # arr = list(map(int, input().rstrip().split()))
    # res = reverseArray(arr)
    # print(' '.join(map(str, res)))
