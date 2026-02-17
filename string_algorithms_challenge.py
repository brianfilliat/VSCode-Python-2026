# Python String Algorithms Challenge
# This script demonstrates common algorithms for strings in Python

# 1. String Reversal
def reverse_string(s):
    return s[::-1]

# 2. Check if Palindrome
def is_palindrome(s):
    cleaned = ''.join(c.lower() for c in s if c.isalnum())
    return cleaned == cleaned[::-1]

# 3. Check if Anagram
def is_anagram(s1, s2):
    return sorted(s1.lower()) == sorted(s2.lower())

# 4. Count Vowels and Consonants
def count_vowels_consonants(s):
    vowels = set('aeiouAEIOU')
    v_count = c_count = 0
    for char in s:
        if char.isalpha():
            if char in vowels:
                v_count += 1
            else:
                c_count += 1
    return v_count, c_count

# 5. String Compression (Run-Length Encoding)
def compress_string(s):
    if not s:
        return ""
    compressed = []
    count = 1
    for i in range(1, len(s)):
        if s[i] == s[i-1]:
            count += 1
        else:
            compressed.append(s[i-1] + str(count))
            count = 1
    compressed.append(s[-1] + str(count))
    return ''.join(compressed)

# 6. Longest Common Prefix
def longest_common_prefix(strs):
    if not strs:
        return ""
    prefix = strs[0]
    for s in strs[1:]:
        while s.find(prefix) != 0:
            prefix = prefix[:-1]
            if not prefix:
                return ""
    return prefix

# 7. Check if String Contains Only Unique Characters
def has_unique_chars(s):
    return len(set(s)) == len(s)

# 8. First Non-Repeating Character
def first_non_repeating_char(s):
    char_count = {}
    for char in s:
        char_count[char] = char_count.get(char, 0) + 1
    for char in s:
        if char_count[char] == 1:
            return char
    return None

# 9. String Permutations (using backtracking)
def string_permutations(s):
    def backtrack(start, end):
        if start == end:
            result.append(''.join(chars))
        else:
            for i in range(start, end):
                chars[start], chars[i] = chars[i], chars[start]
                backtrack(start + 1, end)
                chars[start], chars[i] = chars[i], chars[start]  # backtrack

    chars = list(s)
    result = []
    backtrack(0, len(chars))
    return result

# 10. Valid Parentheses
def is_valid_parentheses(s):
    stack = []
    mapping = {')': '(', '}': '{', ']': '['}
    for char in s:
        if char in mapping:
            top_element = stack.pop() if stack else '#'
            if mapping[char] != top_element:
                return False
        else:
            stack.append(char)
    return not stack

# Test the algorithms
if __name__ == "__main__":
    print("=== String Algorithms Tests ===")

    # Test strings
    test_str = "Hello, World!"
    palindrome_str = "A man, a plan, a canal: Panama"
    anagram1 = "listen"
    anagram2 = "silent"
    compress_str = "aaabbbcc"
    strs_list = ["flower", "flow", "flight"]
    unique_str = "abcdef"
    repeat_str = "swiss"
    paren_str = "({[]})"

    # 1. String Reversal
    print("1. Reverse '" + test_str + "':", reverse_string(test_str))

    # 2. Palindrome Check
    print("2. Is '" + palindrome_str + "' a palindrome?", is_palindrome(palindrome_str))
    print("   Is '" + test_str + "' a palindrome?", is_palindrome(test_str))

    # 3. Anagram Check
    print("3. Are '" + anagram1 + "' and '" + anagram2 + "' anagrams?", is_anagram(anagram1, anagram2))

    # 4. Count Vowels and Consonants
    v, c = count_vowels_consonants(test_str)
    print("4. Vowels and consonants in '" + test_str + "':", v, "vowels,", c, "consonants")

    # 5. String Compression
    print("5. Compress '" + compress_str + "':", compress_string(compress_str))

    # 6. Longest Common Prefix
    print("6. Longest common prefix of", strs_list, ":", longest_common_prefix(strs_list))

    # 7. Unique Characters
    print("7. Does '" + unique_str + "' have unique chars?", has_unique_chars(unique_str))
    print("   Does '" + repeat_str + "' have unique chars?", has_unique_chars(repeat_str))

    # 8. First Non-Repeating Character
    print("8. First non-repeating char in '" + repeat_str + "':", first_non_repeating_char(repeat_str))

    # 9. String Permutations (small string to avoid too much output)
    small_str = "abc"
    perms = string_permutations(small_str)
    print("9. Permutations of '" + small_str + "':", perms)

    # 10. Valid Parentheses
    print("10. Is '" + paren_str + "' valid parentheses?", is_valid_parentheses(paren_str))
    print("    Is '([)]' valid parentheses?", is_valid_parentheses("([)]"))