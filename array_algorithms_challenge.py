# Python Array Algorithms Challenge
# This script demonstrates common algorithms for arrays (lists) in Python

# 1. Linear Search
def linear_search(arr, target):
    for i in range(len(arr)):
        if arr[i] == target:
            return i
    return -1

# 2. Binary Search (assumes sorted array)
def binary_search(arr, target):
    left, right = 0, len(arr) - 1
    while left <= right:
        mid = (left + right) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1

# 3. Array Reversal (in-place)
def reverse_array(arr):
    left, right = 0, len(arr) - 1
    while left < right:
        arr[left], arr[right] = arr[right], arr[left]
        left += 1
        right -= 1
    return arr

# 4. Find Maximum Element
def find_max(arr):
    if not arr:
        return None
    max_val = arr[0]
    for num in arr[1:]:
        if num > max_val:
            max_val = num
    return max_val

# 5. Find Minimum Element
def find_min(arr):
    if not arr:
        return None
    min_val = arr[0]
    for num in arr[1:]:
        if num < min_val:
            min_val = num
    return min_val

# 6. Array Rotation (left rotate by k positions)
def rotate_left(arr, k):
    n = len(arr)
    k = k % n  # Handle k > n
    return arr[k:] + arr[:k]

# 7. Two Sum (find indices of two numbers that add up to target)
def two_sum(arr, target):
    seen = {}
    for i, num in enumerate(arr):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
    return []

# 8. Remove Duplicates from Sorted Array (in-place, return new length)
def remove_duplicates_sorted(arr):
    if not arr:
        return 0
    write_index = 1
    for i in range(1, len(arr)):
        if arr[i] != arr[i - 1]:
            arr[write_index] = arr[i]
            write_index += 1
    return write_index

# 9. Merge Two Sorted Arrays
def merge_sorted_arrays(arr1, arr2):
    result = []
    i = j = 0
    while i < len(arr1) and j < len(arr2):
        if arr1[i] < arr2[j]:
            result.append(arr1[i])
            i += 1
        else:
            result.append(arr2[j])
            j += 1
    result.extend(arr1[i:])
    result.extend(arr2[j:])
    return result

# 10. Kadane's Algorithm (Maximum Subarray Sum)
def max_subarray_sum(arr):
    if not arr:
        return 0
    max_current = max_global = arr[0]
    for num in arr[1:]:
        max_current = max(num, max_current + num)
        if max_current > max_global:
            max_global = max_current
    return max_global

# 11. Counting Bits
def count_bits(n: int) -> list[int]:
    if n == 0:
        return [0]
    binary = bin(n)[2:]  # Remove '0b' prefix
    count = 0
    positions = []
    for i in range(len(binary)):
        if binary[i] == '1':
            count += 1
            positions.append(i + 1)  # Positions start at 1
    return [count] + positions

# 12. Romanizer
def romanizer(numbers: list[int]) -> list[str]:
    def int_to_roman(num: int) -> str:
        val = [
            1000, 900, 500, 400,
            100, 90, 50, 40,
            10, 9, 5, 4, 1
        ]
        syms = [
            "M", "CM", "D", "CD",
            "C", "XC", "L", "XL",
            "X", "IX", "V", "IV", "I"
        ]
        roman_num = ''
        i = 0
        while num > 0:
            for _ in range(num // val[i]):
                roman_num += syms[i]
                num -= val[i]
            i += 1
        return roman_num
    
    return [int_to_roman(num) for num in numbers]

# 13. Largest Distance Between Peaks
def largest_peak_distance(arr: list[int]) -> int:
    if len(arr) < 3:
        return 0
    
    peaks = []
    for i in range(1, len(arr) - 1):
        if arr[i] > arr[i-1] and arr[i] > arr[i+1]:
            peaks.append(i)
    
    if len(peaks) < 2:
        return 0
    
    max_distance = 0
    for i in range(1, len(peaks)):
        distance = peaks[i] - peaks[i-1]
        if distance > max_distance:
            max_distance = distance
    
    return max_distance

# Test the algorithms
if __name__ == "__main__":
    # Test data
    arr1 = [1, 2, 3, 4, 5]
    arr2 = [6, 7, 8, 9, 10]
    sorted_arr = [1, 3, 5, 7, 9, 11]
    unsorted_arr = [4, 2, 8, 1, 9, 3]

    print("=== Array Algorithms Tests ===")

    # Linear Search
    print("1. Linear Search for 3 in", arr1, ":", linear_search(arr1, 3))
    print("   Linear Search for 10 in", arr1, ":", linear_search(arr1, 10))

    # Binary Search
    print("2. Binary Search for 7 in", sorted_arr, ":", binary_search(sorted_arr, 7))
    print("   Binary Search for 4 in", sorted_arr, ":", binary_search(sorted_arr, 4))

    # Array Reversal
    arr_copy = arr1.copy()
    print("3. Reverse", arr_copy, ":", reverse_array(arr_copy))

    # Find Max/Min
    print("4. Max in", unsorted_arr, ":", find_max(unsorted_arr))
    print("5. Min in", unsorted_arr, ":", find_min(unsorted_arr))

    # Array Rotation
    print("6. Rotate", arr1, "left by 2:", rotate_left(arr1, 2))

    # Two Sum
    two_sum_arr = [2, 7, 11, 15]
    print("7. Two Sum in", two_sum_arr, "for target 9:", two_sum(two_sum_arr, 9))

    # Remove Duplicates
    dup_arr = [1, 1, 2, 2, 3, 4, 4, 5]
    new_length = remove_duplicates_sorted(dup_arr)
    print("8. Remove duplicates from", [1, 1, 2, 2, 3, 4, 4, 5], "-> length:", new_length, "array:", dup_arr[:new_length])

    # Merge Sorted Arrays
    print("9. Merge", [1, 3, 5], "and", [2, 4, 6], ":", merge_sorted_arrays([1, 3, 5], [2, 4, 6]))

    # Maximum Subarray Sum
    subarray_arr = [-2, 1, -3, 4, -1, 2, 1, -5, 4]
    print("10. Max subarray sum in", subarray_arr, ":", max_subarray_sum(subarray_arr))

    # Counting Bits
    print("11. Counting bits for 37:", count_bits(37))
    print("    Counting bits for 0:", count_bits(0))
    print("    Counting bits for 1:", count_bits(1))
    print("    Counting bits for 15 (1111):", count_bits(15))
    print("    Counting bits for 161:", count_bits(161))

    # Romanizer
    roman_test = [1, 4, 5, 9, 10, 40, 50, 90, 100, 400, 500, 900, 1000, 3999]
    print("12. Roman numerals for", roman_test, ":", romanizer(roman_test))
    
    # Additional test case
    example_test = [1, 49, 23]
    print("    Example: Roman numerals for", example_test, ":", romanizer(example_test))

    # Largest Peak Distance
    peak_test1 = [1, 5, 2, 3, 1]
    print("13. Largest peak distance in", peak_test1, ":", largest_peak_distance(peak_test1))
    
    peak_test2 = [1, 2, 1, 3, 2, 1, 4, 1]
    print("    Largest peak distance in", peak_test2, ":", largest_peak_distance(peak_test2))
    
    peak_test3 = [1, 2, 3, 4, 5]  # No peaks
    print("    Largest peak distance in", peak_test3, ":", largest_peak_distance(peak_test3))