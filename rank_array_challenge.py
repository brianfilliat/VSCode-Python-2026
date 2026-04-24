"""
Python 3 Coding Challenge: Rank the Array

Problem: Write a function that takes an array (or list) of scores and returns an
array of ranks corresponding to each score. The highest score should be assigned
rank 1, the second highest score should be assigned rank 2, and so forth.
If there are ties, all tied scores should receive the same rank.

Time Limit: 5.0 sec(s)
Memory Limit: 256 MB
"""


def rank_scores(scores):
    """
    Rank an array of scores where highest score gets rank 1, etc.
    Tied scores get the same rank.

    Args:
        scores: List of numeric scores

    Returns:
        List of ranks corresponding to each score

    Examples:
        >>> rank_scores([9, 3, 6, 10])
        [2, 4, 3, 1]
        >>> rank_scores([3, 3, 3, 3, 3, 5, 1])
        [2, 2, 2, 2, 2, 1, 3]
    """
    n = len(scores)
    if n == 0:
        return []

    # Create list of (score, index) pairs
    score_index = [(score, i) for i, score in enumerate(scores)]

    # Sort by score in descending order
    score_index.sort(key=lambda x: x[0], reverse=True)

    # Initialize ranks array
    ranks = [0] * n

    current_rank = 1
    i = 0

    while i < n:
        # Start of a group with the same score
        current_score = score_index[i][0]

        # Assign current rank to all scores in this group
        while i < n and score_index[i][0] == current_score:
            ranks[score_index[i][1]] = current_rank
            i += 1

        # Move to next rank
        current_rank += 1

    return ranks


# Test cases
if __name__ == "__main__":
    # Sample test cases from the problem
    test_cases = [
        ([9, 3, 6, 10], [2, 4, 3, 1]),
        ([3, 3, 3, 3, 3, 5, 1], [2, 2, 2, 2, 2, 1, 3]),
        ([10, 10, 10], [1, 1, 1]),  # All tied
        ([5], [1]),  # Single element
        ([1, 2, 3, 4, 5], [5, 4, 3, 2, 1]),  # All different
        ([], []),  # Empty list
    ]

    print("Running test cases:")
    print("-" * 60)

    all_passed = True
    for input_list, expected_output in test_cases:
        result = rank_scores(input_list)
        passed = result == expected_output
        all_passed = all_passed and passed

        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"{status}")
        print(f"  Input:    {input_list}")
        print(f"  Expected: {expected_output}")
        print(f"  Got:      {result}")
        print()

    print("-" * 60)
    if all_passed:
        print("All tests passed!")
    else:
        print("Some tests failed!")