import random
import json
import os
import time

DATA_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "numbers.json")
COUNT = 100
MAX_ITERATIONS = 20
CORRUPTION_CHANCE = 0.3

def generate_numbers():
    return [random.randint(1, 10000) for _ in range(COUNT)]

def write_numbers(numbers):
    with open(DATA_FILE, "w") as f:
        json.dump(numbers, f)

def read_numbers():
    with open(DATA_FILE, "r") as f:
        return json.load(f)

def corrupt_numbers(numbers):
    result = numbers.copy()
    count = random.randint(1, 5)
    for _ in range(count):
        idx = random.randint(0, len(result) - 1)
        result[idx] = random.randint(1, 10000)
    return result

def verify_numbers(original, read_back):
    errors = []
    for i, (o, r) in enumerate(zip(original, read_back)):
        if o != r:
            errors.append((i, o, r))
    return errors

def main():
    iteration = 0
    all_correct = False
    total_errors = 0

    while not all_correct and iteration < MAX_ITERATIONS:
        iteration += 1
        print(f"\n=== Iteration {iteration} ===")

        numbers = generate_numbers()
        print(f"Generated {len(numbers)} random numbers")
        print(f"Sample: {numbers[:5]}...{numbers[-5:]}")

        write_numbers(numbers)
        print(f"Written to {DATA_FILE}")

        if random.random() < CORRUPTION_CHANCE:
            corrupted = corrupt_numbers(numbers)
            write_numbers(corrupted)
            print(f"[SIMULATED] Data corrupted! {len(verify_numbers(numbers, corrupted))} mismatches")

        read_back = read_numbers()
        print(f"Read back {len(read_back)} numbers")

        errors = verify_numbers(numbers, read_back)
        if errors:
            total_errors += len(errors)
            print(f"Found {len(errors)} errors:")
            for idx, expected, actual in errors[:3]:
                print(f"  Index {idx}: expected {expected}, got {actual}")
            if len(errors) > 3:
                print(f"  ... and {len(errors) - 3} more errors")
            print("Fixing: regenerating and rewriting numbers...")
            time.sleep(0.1)
        else:
            all_correct = True
            print(f"All {COUNT} numbers verified correctly!")
            print(f"Completed in {iteration} iteration(s)")
            print(f"Total errors encountered: {total_errors}")
            print(f"Final numbers: {numbers[:10]}...{numbers[-10:]}")

    if not all_correct:
        print(f"\nFailed after {MAX_ITERATIONS} iterations!")

if __name__ == "__main__":
    main()
