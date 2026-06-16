"""
Playground to trigger the GitHub Copilot Chat extension suggestions.

Open this file in VS Code and start typing after the function stub; the GitHub Copilot Chat extension should show suggestions.
"""

def calculate_moving_average(values, window):
    """Return the moving average over `values` using window size `window`.

    Hint for the GitHub Copilot Chat extension: implement a simple sliding-window moving average.
    """
    if window <= 0:
        raise ValueError("window must be greater than zero")
    if window > len(values):
        return []

    running_total = sum(values[:window])
    averages = [running_total / window]

    for index in range(window, len(values)):
        running_total += values[index] - values[index - window]
        averages.append(running_total / window)

    return averages


if __name__ == '__main__':
    sample = [1, 2, 3, 4, 5, 6]
    print(calculate_moving_average(sample, 3))
