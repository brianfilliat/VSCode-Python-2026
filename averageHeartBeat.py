#!/bin/python3

import math
import os
import random
import re
import sys
import requests
import json
import urllib.parse


#
# Complete the 'averageHeartBeat' function below.
#
# The function is expected to return an INTEGER.
# The function accepts following parameters:
#  1. STRING marathon
#  2. STRING sex
# API URL: https://jsonmock.hackerrank.com/api/marathon?sex=<sex>
# 

def averageHeartBeat(marathon, sex):
    # Write your code here
    base_url = f"https://jsonmock.hackerrank.com/api/marathon?marathon_name={urllib.parse.quote(marathon)}&sex={sex}"
    response = requests.get(base_url)
    data = response.json()
    total_pages = data['total_pages']
    heartbeats = []
    for runner in data['data']:
        heartbeats.append(runner['avgheartbeat'])
    for page in range(2, total_pages + 1):
        response = requests.get(f"{base_url}&page={page}")
        data = response.json()
        for runner in data['data']:
            heartbeats.append(runner['avgheartbeat'])
    if heartbeats:
        avg = sum(heartbeats) / len(heartbeats)
        return math.floor(avg)
    else:
        return 0

if __name__ == '__main__':
    data = sys.stdin.read().strip().split('\n')
    marathon = data[0]
    sex = data[1]
    result = averageHeartBeat(marathon, sex)
    print(result)