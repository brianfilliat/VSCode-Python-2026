# Python Recursion Algorithms Challenge
# This script demonstrates common recursive algorithms in Python

# 1. Factorial
def factorial(n):
    if n == 0 or n == 1:
        return 1
    return n * factorial(n - 1)

# 2. Fibonacci
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

# 3. Sum of Array (Recursive)
def sum_array(arr):
    if not arr:
        return 0
    return arr[0] + sum_array(arr[1:])

# 4. Binary Search (Recursive)
def binary_search_recursive(arr, target, left, right):
    if left > right:
        return -1
    mid = (left + right) // 2
    if arr[mid] == target:
        return mid
    elif arr[mid] < target:
        return binary_search_recursive(arr, target, mid + 1, right)
    else:
        return binary_search_recursive(arr, target, left, mid - 1)

# 5. Tower of Hanoi
def tower_of_hanoi(n, source, target, auxiliary):
    if n == 1:
        print(f"Move disk 1 from {source} to {target}")
        return
    tower_of_hanoi(n - 1, source, auxiliary, target)
    print(f"Move disk {n} from {source} to {target}")
    tower_of_hanoi(n - 1, auxiliary, target, source)

# 6. String Reversal (Recursive)
def reverse_string_recursive(s):
    if len(s) <= 1:
        return s
    return reverse_string_recursive(s[1:]) + s[0]

# 7. Check Palindrome (Recursive)
def is_palindrome_recursive(s, left, right):
    if left >= right:
        return True
    if s[left] != s[right]:
        return False
    return is_palindrome_recursive(s, left + 1, right - 1)

# 8. Power Function (Recursive)
def power(base, exp):
    if exp == 0:
        return 1
    if exp == 1:
        return base
    return base * power(base, exp - 1)

# 9. Greatest Common Divisor (Euclidean Algorithm)
def gcd(a, b):
    if b == 0:
        return a
    return gcd(b, a % b)

# 10. Generate Subsets (Recursive)
def generate_subsets(nums):
    def backtrack(start, path):
        result.append(path[:])
        for i in range(start, len(nums)):
            path.append(nums[i])
            backtrack(i + 1, path)
            path.pop()

    result = []
    backtrack(0, [])
    return result

# Test the algorithms
if __name__ == "__main__":
    print("=== Recursion Algorithms Tests ===")

    # 1. Factorial
    print("1. Factorial of 5:", factorial(5))

    # 2. Fibonacci
    print("2. Fibonacci of 8:", fibonacci(8))

    # 3. Sum of Array
    arr = [1, 2, 3, 4, 5]
    print("3. Sum of", arr, ":", sum_array(arr))

    # 4. Binary Search
    sorted_arr = [1, 3, 5, 7, 9, 11]
    print("4. Binary search for 7 in", sorted_arr, ":", binary_search_recursive(sorted_arr, 7, 0, len(sorted_arr) - 1))
    print("   Binary search for 4 in", sorted_arr, ":", binary_search_recursive(sorted_arr, 4, 0, len(sorted_arr) - 1))

    # 5. Tower of Hanoi
    print("5. Tower of Hanoi for 3 disks:")
    tower_of_hanoi(3, 'A', 'C', 'B')

    # 6. String Reversal
    test_str = "hello"
    print("6. Reverse '" + test_str + "':", reverse_string_recursive(test_str))

    # 7. Palindrome Check
    pal_str = "radar"
    print("7. Is '" + pal_str + "' a palindrome?", is_palindrome_recursive(pal_str, 0, len(pal_str) - 1))
    print("   Is '" + test_str + "' a palindrome?", is_palindrome_recursive(test_str, 0, len(test_str) - 1))

    # 8. Power
    print("8. 2^10:", power(2, 10))

    # 9. GCD
    print("9. GCD of 48 and 18:", gcd(48, 18))

    # 10. Generate Subsets
    nums = [1, 2, 3]
    subsets = generate_subsets(nums)
    print("10. Subsets of", nums, ":", subsets)