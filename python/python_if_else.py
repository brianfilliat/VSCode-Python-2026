"""
Problem: Python If-Else
URL: https://www.hackerrank.com/challenges/py-if-else/problem

Description:
Given an integer, n, perform the following conditional actions:
- If n is odd, print Weird
- If n is even and in the inclusive range of 2 to 5, print Not Weird
- If n is even and in the inclusive range of 6 to 20, print Weird
- If n is even and greater than 20, print Not Weird

Input Format:
A single line containing a positive integer, n.

Constraints:
1 ≤ n ≤ 100

Output Format:
Print Weird if the number is weird. Otherwise, print Not Weird.
"""


def check_weird(n):
    """
    Determine if a number is weird based on specific conditions.
    
    Args:
        n (int): The number to check
    
    Returns:
        str: 'Weird' or 'Not Weird'
    """
    if n % 2 != 0:
        return "Weird"
    elif 2 <= n <= 5:
        return "Not Weird"
    elif 6 <= n <= 20:
        return "Weird"
    else:
        return "Not Weird"


if __name__ == '__main__':
    # Test cases
    print(check_weird(3))   # Expected: Weird (odd)
    print(check_weird(4))   # Expected: Not Weird (even, 2-5)
    print(check_weird(18))  # Expected: Weird (even, 6-20)
    print(check_weird(24))  # Expected: Not Weird (even, >20)
    
    # HackerRank input format (uncomment to use)
    # n = int(input().strip())
    # result = check_weird(n)
    # print(result)
