#!/bin/python3

import math
import os
import random
import re
import sys



#
# Complete the 'getMaximumSubarray' function below.
#
# The function is expected to return an INTEGER.
# The function accepts INTEGER_ARRAY arr as parameter.
#

def getMaximumSubarray(arr):
    n = len(arr)
    if n <= 1:
        return 0
    pos = [0] * (n + 1)
    for i in range(n):
        pos[arr[i]] = i
    max_length = 1
    min_p = pos[n]
    max_p = pos[n]
    for a in range(n - 1, 1, -1):
        min_p = min(min_p, pos[a])
        max_p = max(max_p, pos[a])
        if max_p - min_p + 1 == n - a + 1:
            max_length = max(max_length, n - a + 1)
    return max_length

if __name__ == '__main__':
    data = sys.stdin.read().strip().split('\n')
    n = int(data[0])
    arr = [int(data[i+1]) for i in range(n)]
    result = getMaximumSubarray(arr)
    print(result)












