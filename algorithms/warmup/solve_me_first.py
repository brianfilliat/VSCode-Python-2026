"""
Problem: Solve Me First
URL: https://www.hackerrank.com/challenges/solve-me-first/problem

Description:
Complete the function solveMeFirst to compute the sum of two integers.

Example:
a = 7
b = 3
Return 10.

Function Description:
Complete the solveMeFirst function in the editor below.

solveMeFirst has the following parameters:
- int a: the first value
- int b: the second value

Returns:
- int: the sum of a and b

Constraints:
1 ≤ a, b ≤ 1000
"""


def solveMeFirst(a, b):
    """
    Returns the sum of two integers.
    
    Args:
        a (int): First integer
        b (int): Second integer
    
    Returns:
        int: Sum of a and b
    """
    return a + b


if __name__ == '__main__':
    # Test cases
    print(solveMeFirst(2, 3))  # Expected: 5
    print(solveMeFirst(100, 200))  # Expected: 300
    
    # HackerRank input format (uncomment to use)
    # num1 = int(input())
    # num2 = int(input())
    # res = solveMeFirst(num1, num2)
    # print(res)
