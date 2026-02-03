"""
Problem: Find the Point
URL: https://www.hackerrank.com/challenges/find-point/problem

Description:
Consider two points, p = (px, py) and q = (qx, qy). We consider the inversion 
or point reflection, r = (rx, ry), of point p across point q to be a 180° 
rotation of point p around q.

Given n sets of points p and q, find r for each pair of points and print two 
space-separated integers denoting the respective values of rx and ry on a new line.

Function Description:
Complete the findPoint function in the editor below.

findPoint has the following parameters:
- int px, py, qx, qy: x and y coordinates for points p and q

Returns:
- int[2]: the coordinates of the reflected point r

Constraints:
1 ≤ n ≤ 15
-100 ≤ px, py, qx, qy ≤ 100

Example:
p = (0, 0) and q = (1, 1)
Rotate p 180° around q to get r = (2, 2)
"""


def findPoint(px, py, qx, qy):
    """
    Find the reflection point r of point p across point q.
    
    The formula for reflection:
    rx = 2*qx - px
    ry = 2*qy - py
    
    Args:
        px (int): x coordinate of point p
        py (int): y coordinate of point p
        qx (int): x coordinate of point q
        qy (int): y coordinate of point q
    
    Returns:
        list: [rx, ry] coordinates of reflected point
    """
    rx = 2 * qx - px
    ry = 2 * qy - py
    return [rx, ry]


if __name__ == '__main__':
    # Test cases
    print(findPoint(0, 0, 1, 1))    # Expected: [2, 2]
    print(findPoint(1, 1, 2, 2))    # Expected: [3, 3]
    print(findPoint(1, 2, 3, 4))    # Expected: [5, 6]
    
    # HackerRank input format (uncomment to use)
    # n = int(input())
    # for _ in range(n):
    #     px, py, qx, qy = map(int, input().rstrip().split())
    #     result = findPoint(px, py, qx, qy)
    #     print(' '.join(map(str, result)))
