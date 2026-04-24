"""
Python 3 Coding Challenge: Sort Code Function

Problem: Create a function that takes a string composed of up to 26 unique 
alphabetic characters and returns a string with those same characters 
arranged alphabetically.

Time Limit: 5.0 sec(s)
Memory Limit: 256 MB
"""


def sort_code(s: str) -> str:
    """
    Sort a string of alphabetic characters alphabetically.
    
    Args:
        s: A string composed of up to 26 unique alphabetic characters
        
    Returns:
        A string with the same characters sorted alphabetically
        
    Examples:
        >>> sort_code("acbdfe")
        'abcdef'
        >>> sort_code("pqksuvy")
        'kpqsuvy'
        >>> sort_code("ona")
        'aon'
    """
    return ''.join(sorted(s))


# Test cases
if __name__ == "__main__":
    # Sample test cases from the problem
    test_cases = [
        ("acbdfe", "abcdef"),
        ("pqksuvy", "kpqsuvy"),
        ("ona", "ano"),
        ("zyxwvutsrqponmlkjihgfedcba", "abcdefghijklmnopqrstuvwxyz"),
    ]
    
    print("Running test cases:")
    print("-" * 50)
    
    all_passed = True
    for input_str, expected_output in test_cases:
        result = sort_code(input_str)
        passed = result == expected_output
        all_passed = all_passed and passed
        
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"{status}")
        print(f"  Input:    '{input_str}'")
        print(f"  Expected: '{expected_output}'")
        print(f"  Got:      '{result}'")
        print()
    
    print("-" * 50)
    if all_passed:
        print("All tests passed!")
    else:
        print("Some tests failed!")
