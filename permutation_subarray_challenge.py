# Python Permutation Subarray Challenge
# This script implements algorithms for finding the maximum subarray to remove from a permutation

# 1. Get Maximum Subarray Length to Remove
def getMaximumSubarray(arr):
    n = len(arr)
    if n <= 1:
        return 0
    pos = [0] * (n + 1)
    for i in range(n):
        pos[arr[i]] = i
    max_length = 1  # removing just the largest element
    min_p = pos[n]
    max_p = pos[n]
    for a in range(n - 1, 1, -1):
        min_p = min(min_p, pos[a])
        max_p = max(max_p, pos[a])
        if max_p - min_p + 1 == n - a + 1:
            max_length = max(max_length, n - a + 1)
    return max_length

# Test in main block
if __name__ == "__main__":
    # Example 1: n=3, arr=[3,1,2]
    arr1 = [3, 1, 2]
    print("1. Maximum subarray length to remove for", arr1, ":", getMaximumSubarray(arr1))

    # Sample Case 0: n=4, arr=[4,3,2,1]
    arr2 = [4, 3, 2, 1]
    print("2. Maximum subarray length to remove for", arr2, ":", getMaximumSubarray(arr2))

    # Sample Input 1: n=5, arr=[2,3,1,4,5]
    arr3 = [2, 3, 1, 4, 5]
    print("3. Maximum subarray length to remove for", arr3, ":", getMaximumSubarray(arr3))


    fptr = open(os.environ['OUTPUT_PATH'], 'w')

    arr_count = int(input().strip())

    arr = []

    for _ in range(arr_count):
        arr_item = int(input().strip())
        arr.append(arr_item)

    result = getMaximumSubarray(arr)

    fptr.write(str(result) + '\n')





