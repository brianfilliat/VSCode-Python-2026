# Python String Manipulation Challenge
# This script demonstrates basic string operations in Python

# 1. String Concatenation
str1 = "Hello"
str2 = "World"
greeting = str1 + " " + str2
print("Concatenation:", greeting)

# 2. String Slicing
text = "Python Programming"
print("Original text:", text)
print("First 6 characters:", text[0:6])
print("Last 11 characters:", text[-11:])

# 3. Case Conversion
print("Uppercase:", text.upper())
print("Lowercase:", text.lower())
print("Title case:", text.title())

# 4. String Replacement
print("Replace 'Python' with 'Java':", text.replace("Python", "Java"))

# 5. Splitting and Joining
words = text.split()
print("Split into words:", words)
joined_back = " ".join(words)
print("Joined back:", joined_back)

# 6. Counting Characters
print("Count of 'm':", text.count("m"))
print("Count of 'P':", text.count("P"))

# 7. Finding Substrings
print("Find 'Prog':", text.find("Prog"))
print("Index of 'P':", text.index("P"))

# 8. Stripping Whitespace
messy_string = "   Hello World   "
print("Original messy string:", repr(messy_string))
print("Stripped:", repr(messy_string.strip()))
print("Left strip:", repr(messy_string.lstrip()))
print("Right strip:", repr(messy_string.rstrip()))

# 9. String Formatting
name = "Alice"
age = 25
print("Formatted string:", f"My name is {name} and I am {age} years old.")
print("Old style formatting:", "My name is %s and I am %d years old." % (name, age))

# 10. Checking String Properties
sample = "Hello123"
print("Is alphanumeric:", sample.isalnum())
print("Is alphabetic:", sample.isalpha())
print("Is digit:", sample.isdigit())
print("Is lowercase:", sample.islower())
print("Is uppercase:", sample.isupper())

# Challenge: Write a function that reverses a string without using slicing
def reverse_string(s):
    reversed_str = ""
    for char in s:
        reversed_str = char + reversed_str
    return reversed_str

test_string = "Python"
print("Reversed 'Python':", reverse_string(test_string))

# Challenge: Count vowels in a string
def count_vowels(s):
    vowels = "aeiouAEIOU"
    count = 0
    for char in s:
        if char in vowels:
            count += 1
    return count

print("Vowels in 'Python Programming':", count_vowels(text))


# string_challenges.py

import re
from collections import Counter

# 1) Reverse a string
def reverse_string(s: str) -> str:
    return s[::-1]

# 2) Count vowels and consonants
def count_vowels_consonants(s: str) -> tuple:
    vowels = set("aeiouAEIOU")
    v_count = c_count = 0
    for ch in s:
        if ch.isalpha():
            if ch in vowels:
                v_count += 1
            else:
                c_count += 1
    return v_count, c_count

# 3) Palindrome check (letters only)
def is_palindrome(s: str) -> bool:
    cleaned = "".join(ch.lower() for ch in s if ch.isalpha())
    return cleaned == cleaned[::-1]

# 4) Most frequent character (letters only, case-insensitive)
def most_frequent_char(s: str) -> str | None:
    letters = [ch.lower() for ch in s if ch.isalpha()]
    if not letters:
        return None
    freq = Counter(letters)
    # Return the character with highest count (ties arbitrary)
    return max(freq, key=lambda k: freq[k])

# 5) camelCase/PascalCase -> snake_case
def to_snake_case(s: str) -> str:
    # Insert underscore before capital letters and lower everything
    s_with_underscores = re.sub(r'(?<!^)(?=[A-Z])', '_', s)
    return s_with_underscores.lower()

# 6) Acronym from phrase
def acronym(phrase: str) -> str:
    words = re.findall(r"[A-Za-z0-9]+", phrase)
    return "".join(word[0].upper() for word in words if word)

# 7) Run-length encoding (simple)
def run_length_encode(s: str) -> str:
    if not s:
        return ""
    parts = []
    prev = s[0]
    count = 1
    for ch in s[1:]:
        if ch == prev:
            count += 1
        else:
            parts.append(f"{prev}{count}")
            prev = ch
            count = 1
    parts.append(f"{prev}{count}")
    return "".join(parts)

# 8) Anagram check (ignore spaces and case)
def are_anagrams(a: str, b: str) -> bool:
    a_clean = "".join(ch.lower() for ch in a if ch.isalnum())
    b_clean = "".join(ch.lower() for ch in b if ch.isalnum())
    return Counter(a_clean) == Counter(b_clean)

# 9) Longest word in a sentence (strip punctuation)
def longest_word(sentence: str) -> str | None:
    words = re.findall(r"[A-Za-z']+", sentence)
    if not words:
        return None
    return max(words, key=len)

# 10) Caesar cipher (shift by n)
def caesar_cipher(s: str, shift: int) -> str:
    def shift_char(ch):
        if 'a' <= ch <= 'z':
            base = ord('a')
            return chr((ord(ch) - base + shift) % 26 + base)
        if 'A' <= ch <= 'Z':
            base = ord('A')
            return chr((ord(ch) - base + shift) % 26 + base)
        return ch
    return "".join(shift_char(ch) for ch in s)


# Quick demonstration / tests
if __name__ == "__main__":
    print("1) Reverse:", reverse_string("hello"))
    print("2) Vowels/Consonants:", count_vowels_consonants("Hello, World!"))
    print("3) Palindrome:", is_palindrome("A man, a plan, a canal: Panama"))
    print("4) Most frequent char:", most_frequent_char("banana"))
    print("5) to_snake_case:", to_snake_case("thisIsATest"), to_snake_case("ThisIsATest"))
    print("6) Acronym:", acronym("As Soon As Possible"))
    print("7) RLE:", run_length_encode("aaabbc"))
    print("8) Anagram:", are_anagrams("Dormitory", "Dirty room"))
    print("9) Longest word:", longest_word("The quick brown fox jumped over the lazy dog."))
    print("10) Caesar:", caesar_cipher("Hello, World!", 3))


# Python List/Array Operations Challenge
# This section demonstrates basic list operations in Python

# 1. Creating Lists
my_list = [1, 2, 3, 4, 5]
print("\nOriginal list:", my_list)

# 2. Appending Elements
my_list.append(6)
print("After append 6:", my_list)

# 3. Inserting Elements
my_list.insert(0, 0)
print("After insert 0 at index 0:", my_list)

# 4. Removing Elements
my_list.remove(3)
print("After remove 3:", my_list)

# 5. Popping Elements
popped = my_list.pop()
print("Popped:", popped, "List:", my_list)

# 6. Sorting Lists
my_list.sort()
print("Sorted:", my_list)

# 7. Reversing Lists
my_list.reverse()
print("Reversed:", my_list)

# 8. List Slicing
print("First 3 elements:", my_list[:3])
print("Last 2 elements:", my_list[-2:])

# 9. List Comprehension
squares = [x**2 for x in my_list]
print("Squares of elements:", squares)

even_squares = [x**2 for x in my_list if x % 2 == 0]
print("Squares of even elements:", even_squares)

# 10. List Methods
numbers = [1, 2, 2, 3, 4, 4, 5]
print("Count of 2:", numbers.count(2))
print("Index of 4:", numbers.index(4))

# Challenge: Sum of list elements
def sum_list(lst):
    total = 0
    for num in lst:
        total += num
    return total

print("Sum of [1,2,3,4,5]:", sum_list([1, 2, 3, 4, 5]))

# Challenge: Find maximum in list
def max_in_list(lst):
    if not lst:
        return None
    max_val = lst[0]
    for num in lst[1:]:
        if num > max_val:
            max_val = num
    return max_val

print("Max in [1,5,3,9,2]:", max_in_list([1, 5, 3, 9, 2]))

# Challenge: Reverse a list without using reverse()
def reverse_list(lst):
    reversed_lst = []
    for i in range(len(lst) - 1, -1, -1):
        reversed_lst.append(lst[i])
    return reversed_lst

print("Reversed [1,2,3,4,5]:", reverse_list([1, 2, 3, 4, 5]))

# Challenge: Remove duplicates from list
def remove_duplicates(lst):
    seen = set()
    result = []
    for item in lst:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result

print("Remove duplicates [1,2,2,3,4,4,5]:", remove_duplicates([1, 2, 2, 3, 4, 4, 5]))