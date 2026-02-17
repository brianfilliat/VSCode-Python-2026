# Python List Operations Challenge
# This script demonstrates basic list operations in Python

# 1. Creating Lists
my_list = [1, 2, 3, 4, 5]
print("Original list:", my_list)

# 2. Accessing Elements
print("First element:", my_list[0])
print("Last element:", my_list[-1])
print("Element at index 2:", my_list[2])

# 3. Slicing Lists
print("First three elements:", my_list[:3])
print("Elements from index 2 to 4:", my_list[2:5])
print("Last two elements:", my_list[-2:])
print("Every other element:", my_list[::2])

# 4. Adding Elements
my_list.append(6)
print("After append(6):", my_list)

my_list.insert(0, 0)
print("After insert(0, 0):", my_list)

my_list.extend([7, 8])
print("After extend([7, 8]):", my_list)

# 5. Removing Elements
my_list.remove(3)  # Removes first occurrence of 3
print("After remove(3):", my_list)

popped = my_list.pop()  # Removes and returns last element
print("Popped element:", popped, "List now:", my_list)

popped_index = my_list.pop(2)  # Removes and returns element at index 2
print("Popped from index 2:", popped_index, "List now:", my_list)

# 6. Sorting Lists
unsorted = [3, 1, 4, 1, 5, 9, 2]
print("Unsorted list:", unsorted)
unsorted.sort()
print("Sorted list:", unsorted)

unsorted_desc = [3, 1, 4, 1, 5, 9, 2]
unsorted_desc.sort(reverse=True)
print("Sorted descending:", unsorted_desc)

# 7. Reversing Lists
to_reverse = [1, 2, 3, 4, 5]
to_reverse.reverse()
print("Reversed list:", to_reverse)

# 8. List Comprehensions
squares = [x**2 for x in range(1, 6)]
print("Squares from 1 to 5:", squares)

cubes = [x**3 for x in range(1, 6) if x % 2 == 0]
print("Cubes of even numbers 1-5:", cubes)

# 9. Filtering with List Comprehensions
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
evens = [x for x in numbers if x % 2 == 0]
print("Even numbers:", evens)

odds = [x for x in numbers if x % 2 != 0]
print("Odd numbers:", odds)

# 10. List Concatenation and Repetition
list1 = [1, 2, 3]
list2 = [4, 5, 6]
combined = list1 + list2
print("Concatenated:", combined)

repeated = list1 * 3
print("Repeated 3 times:", repeated)

# 11. List Methods
sample_list = [1, 2, 3, 2, 4, 2]
print("Count of 2:", sample_list.count(2))
print("Index of first 2:", sample_list.index(2))

copy_list = sample_list.copy()
print("Copied list:", copy_list)

sample_list.clear()
print("After clear:", sample_list)

# Challenge: Find the maximum value in a list without using built-in max()
def find_maximum(lst):
    if not lst:
        return None
    maximum = lst[0]
    for num in lst[1:]:
        if num > maximum:
            maximum = num
    return maximum

test_list = [3, 1, 4, 1, 5, 9, 2, 6]
print("Maximum in", test_list, "is:", find_maximum(test_list))

# Challenge: Remove duplicates from a list while preserving order
def remove_duplicates(lst):
    seen = set()
    result = []
    for item in lst:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result

duplicate_list = [1, 2, 2, 3, 3, 3, 4, 1, 5]
print("List with duplicates:", duplicate_list)
print("Without duplicates:", remove_duplicates(duplicate_list))

# Challenge: Flatten a nested list
def flatten(nested_list):
    flat_list = []
    for item in nested_list:
        if isinstance(item, list):
            flat_list.extend(flatten(item))
        else:
            flat_list.append(item)
    return flat_list

nested = [1, [2, [3, 4], 5], 6, [7, 8]]
print("Nested list:", nested)
print("Flattened:", flatten(nested))


# Sorting Algorithms Challenge
# Implementations of common sorting algorithms

# 1. Bubble Sort
def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
    return arr

# 2. Selection Sort
def selection_sort(arr):
    n = len(arr)
    for i in range(n):
        min_idx = i
        for j in range(i + 1, n):
            if arr[j] < arr[min_idx]:
                min_idx = j
        arr[i], arr[min_idx] = arr[min_idx], arr[i]
    return arr

# 3. Insertion Sort
def insertion_sort(arr):
    for i in range(1, len(arr)):
        key = arr[i]
        j = i - 1
        while j >= 0 and key < arr[j]:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key
    return arr

# 4. Quick Sort
def quick_sort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quick_sort(left) + middle + quick_sort(right)

# 5. Merge Sort
def merge_sort(arr):
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])
    right = merge_sort(arr[mid:])
    return merge(left, right)

def merge(left, right):
    result = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] < right[j]:
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    result.extend(left[i:])
    result.extend(right[j:])
    return result

# Test the sorting algorithms
test_arr = [64, 34, 25, 12, 22, 11, 90]
print("\nSorting Algorithms Test:")
print("Original array:", test_arr.copy())

print("Bubble Sort:", bubble_sort(test_arr.copy()))
print("Selection Sort:", selection_sort(test_arr.copy()))
print("Insertion Sort:", insertion_sort(test_arr.copy()))
print("Quick Sort:", quick_sort(test_arr.copy()))
print("Merge Sort:", merge_sort(test_arr.copy()))

# Challenge: Sort a list of strings by length
def sort_by_length(strings):
    return sorted(strings, key=len)

string_list = ["apple", "banana", "kiwi", "cherry", "fig"]
print("\nSort strings by length:", sort_by_length(string_list))

# Challenge: Sort a list of tuples by the second element
def sort_tuples_by_second(tuples):
    return sorted(tuples, key=lambda x: x[1])

tuple_list = [("Alice", 25), ("Bob", 20), ("Charlie", 30)]
print("Sort tuples by age:", sort_tuples_by_second(tuple_list))