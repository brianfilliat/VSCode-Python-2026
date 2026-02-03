"""
Problem: CamelCase
URL: https://www.hackerrank.com/challenges/camelcase/problem

Description:
There is a sequence of words in CamelCase as a string of letters, s, having the 
following properties:
- It is a concatenation of one or more words consisting of English letters.
- All letters in the first word are lowercase.
- For each of the subsequent words, the first letter is uppercase and rest of 
  the letters are lowercase.

Given s, determine the number of words in s.

Example:
s = 'saveChangesInTheEditor'
There are 5 words in the string: 'save', 'Changes', 'In', 'The', 'Editor'.

Function Description:
Complete the camelcase function in the editor below.

camelcase has the following parameter(s):
- string s: the string to analyze

Returns:
- int: the number of words in s

Constraints:
1 ≤ |s| ≤ 10^5
"""


def camelcase(s):
    """
    Count the number of words in a CamelCase string.
    
    Args:
        s (str): CamelCase string
    
    Returns:
        int: Number of words in the string
    """
    # Count uppercase letters and add 1 for the first word
    return sum(1 for c in s if c.isupper()) + 1


if __name__ == '__main__':
    # Test cases
    print(camelcase('saveChangesInTheEditor'))  # Expected: 5
    print(camelcase('oneTwoThree'))  # Expected: 3
    print(camelcase('hello'))  # Expected: 1
    
    # HackerRank input format (uncomment to use)
    # s = input()
    # result = camelcase(s)
    # print(result)
