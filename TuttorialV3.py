import torch
print(torch.__file__)



person_info = {
    "name": "Bob",
    "age": 25,
    "city": "London"
}

print(f"Person's name: {person_info["name"]}")
# Adding a new key-value pair
person_info["email"] = "bob@example.com"
print(f"Person info after adding email: {person_info}")

# Modifying a value
person_info["age"] = 26
print(f"Person info after updating age: {person_info}")

# Deleting a key-value pair
del person_info["city"]
print(f"Person info after deleting city: {person_info}")

# mypy: allow-untyped-defs
import torch

class StaticForLoop(torch.nn.Module):
    """
    A for loop with constant number of iterations should be unrolled in the exported graph.
    """

    def forward(self, x):
        # constant
        ret = [i + x for i in range(10)]
        return ret

example_args = (torch.randn(3, 2),)
tags = {"python.control-flow"}
model = StaticForLoop()




























