#!/bin/python3

import math
import os
import random
import re
import sys

#
# Complete the 'hourglassSum' function below.
#
# The function is expected to return an INTEGER.
# The function accepts 2D_INTEGER_ARRAY arr as parameter.
#

def hourglassSum(arr):
    # Write your code here
    max_sum = -63

    for row in range(4):
        for col in range(4):
            current_sum = (
                arr[row][col] + arr[row][col + 1] + arr[row][col + 2]
                + arr[row + 1][col + 1]
                + arr[row + 2][col] + arr[row + 2][col + 1] + arr[row + 2][col + 2]
            )

            max_sum = max(max_sum, current_sum)

    return max_sum


if __name__ == '__main__':
    fptr = open(os.environ['D:\DOCU-2026\Python-vscode-2026'], 'w')

    arr = []

    for _ in range(6):
        arr.append(list(map(int, input().rstrip().split())))

    result = hourglassSum(arr)

    fptr.write(str(result) + '\n')

    fptr.close()
