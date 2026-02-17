# Counting Bits Problem
# Given an integer n (1 < n < 10^9), determine:
# • The number of 1-bits in its binary representation.
# • The positions of each 1-bit, listed in ascending order.
# Positions are counted from left to right, starting at 1, and leading zeros are ignored.
# Return an array where the first element is the count of 1-bits, remaining elements are positions.

def count_bits(n: int) -> list[int]:
    binary = bin(n)[2:]  # Remove '0b' prefix
    count = 0
    positions = []
    for i in range(len(binary)):
        if binary[i] == '1':
            count += 1
            positions.append(i + 1)  # Positions start at 1
    return [count] + positions

if __name__ == "__main__":
    # Read input from stdin
    n = int(input().strip())
    result = count_bits(n)
    print('\n'.join(map(str, result)))