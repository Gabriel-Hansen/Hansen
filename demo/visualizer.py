
import subprocess
import json
import os
import sys

def run_simulation():
    # Build simulator first
    print("Building simulator...")
    subprocess.run(["cargo", "build"], cwd="./simulator", check=True, capture_output=True)
    
    # Run
    print("Running simulation...")
    cmd = ["./target/debug/simulator", "particles", "--json"]
    result = subprocess.run(cmd, cwd="./simulator", capture_output=True, text=True)
    
    try:
        data = json.loads(result.stdout)
        return data
    except json.JSONDecodeError as e:
        print("Failed to parse JSON output:")
        print(result.stdout)
        sys.exit(1)

def visualize(data):
    print("\n--- Particle Visualization (ASCII) ---")
    print("Rendering 1D movement over time...\n")
    
    # Find max position for scaling
    max_pos = 0
    for frame in data:
        max_pos = max(max_pos, max(frame["particles"]))
    
    scale_factor = 50.0 / max_pos if max_pos > 0 else 1.0

    for frame in data:
        fname = frame["frame"]
        particles = frame["particles"]
        
        # Create a line
        line = [' '] * 60
        for p in particles:
            idx = int(p * scale_factor)
            if idx >= 60: idx = 59
            line[idx] = '*'
        
        print(f"Frame {fname:02d} |" + "".join(line) + "|")

if __name__ == "__main__":
    data = run_simulation()
    visualize(data)
    print("\nDemo Complete.")
