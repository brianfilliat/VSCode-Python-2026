def solvePeaksProblem(arr):
    n = len(arr)
    if n < 3:
        return 0
    peaks = []
    for i in range(1, n-1):
        if arr[i-1] < arr[i] > arr[i+1]:
            peaks.append(i)
    if len(peaks) < 2:
        return 0
    max_dist = 0
    for i in range(1, len(peaks)):
        dist = peaks[i] - peaks[i-1]
        if dist > max_dist:
            max_dist = dist
    return max_dist

if __name__ == "__main__":
    # Example 1
    arr1 = [1, 5, 2, 3, 1]
    print("Example 1:", solvePeaksProblem(arr1))
    
    # Example 2
    arr2 = [1, 2, 1, 3, 2, 1, 4, 1]
    print("Example 2:", solvePeaksProblem(arr2))
