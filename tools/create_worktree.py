#!/usr/bin/env python3
"""
Create a git worktree for parallel development with efficient data copying.

Usage:
    python tools/create_worktree.py <branch-name>

This will:
1. Create a worktree in ../repo-name-branch-name/
2. Copy .data/ directory contents efficiently using rsync
3. Output a cd command to navigate to the new worktree
"""

import subprocess
import sys
from pathlib import Path


def main():
    # Get branch name from arguments
    if len(sys.argv) != 2:
        print("Usage: python tools/create_worktree.py <branch-name>")
        sys.exit(1)

    branch_name = sys.argv[1]

    # Get current repo path and name
    current_path = Path.cwd()
    repo_name = current_path.name

    # Build worktree path
    worktree_name = f"{repo_name}-{branch_name}"
    worktree_path = current_path.parent / worktree_name

    # Create the worktree
    print(f"Creating worktree at {worktree_path}...")
    try:
        # Check if branch exists locally
        result = subprocess.run(["git", "rev-parse", "--verify", branch_name], capture_output=True, text=True)

        if result.returncode == 0:
            # Branch exists, use it
            subprocess.run(["git", "worktree", "add", str(worktree_path), branch_name], check=True)
        else:
            # Branch doesn't exist, create it
            subprocess.run(["git", "worktree", "add", "-b", branch_name, str(worktree_path)], check=True)
            print(f"Created new branch: {branch_name}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to create worktree: {e}")
        sys.exit(1)

    # Copy .data directory if it exists
    data_dir = current_path / ".data"
    if data_dir.exists() and data_dir.is_dir():
        print("\nCopying .data directory (this may take a moment)...")
        target_data_dir = worktree_path / ".data"

        try:
            # Use rsync for efficient copying with progress
            subprocess.run(
                [
                    "rsync",
                    "-av",  # archive mode with verbose
                    "--progress",  # show progress
                    f"{data_dir}/",  # trailing slash to copy contents
                    f"{target_data_dir}/",
                ],
                check=True,
            )
            print("Data copy complete!")
        except subprocess.CalledProcessError as e:
            print(f"Warning: Failed to copy .data directory: {e}")
            print("You may need to copy it manually or use cp instead of rsync")
        except FileNotFoundError:
            # rsync not available, fallback to cp
            print("rsync not found, using cp instead...")
            try:
                subprocess.run(["cp", "-r", str(data_dir), str(worktree_path)], check=True)
                print("Data copy complete!")
            except subprocess.CalledProcessError as e:
                print(f"Warning: Failed to copy .data directory: {e}")

    # Output the cd command
    print("\n✓ Worktree created successfully!")
    print("\nTo navigate to your new worktree, run:")
    print(f"cd {worktree_path}")


if __name__ == "__main__":
    main()
