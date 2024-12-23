import sys
import subprocess
import sys
import os

def create_or_switch_branch(new_branch):
    """Create a new branch """
    subprocess.check_output(["git", "checkout", "main"])
    subprocess.check_output(["git", "pull"])
    subprocess.check_output(["git", "checkout", "-b", new_branch, "main"])
    print(f"Created and switched to new branch: {new_branch}")

def main():
    # Prompt for version type
    version_type = input("Enter version type (1. major, 2. minor, 3. bugfix): ")

    # Set the version variable based on user input
    if version_type == "1":
        version = "major"
    elif version_type == "2":
        version = "minor"
    elif version_type == "3":
        version = "bugfix"
    else:
        print("Invalid version type")
        sys.exit(1)

    print("Get the latest remote branch")
    if len(sys.argv) > 1:
        latest_branch = sys.argv[1]
    else:
        try:
            output = subprocess.check_output(["git", "ls-remote", "--heads", "origin"]).decode("utf-8")
            branches = [line.split("\t")[1].split("refs/heads/")[1] for line in output.splitlines()]
            branches = [branch for branch in branches if branch.count('.') == 2 and all(part.isdigit() for part in branch.split('.'))]
            latest_branch = max(branches)
        except subprocess.CalledProcessError:
            print("Failed to retrieve remote branches")

    print("Increment the version number based on user selection")
    if version == "major":
        # Split the latest branch version into major, minor, and bugfix parts
        major, minor, bugfix = latest_branch.split(".")
        # Increment the major version and reset minor and bugfix to 0
        major = str(int(major) + 1)
        minor = "0"
        bugfix = "0"
    elif version == "minor":
        # Split the latest branch version into major, minor, and bugfix parts
        major, minor, bugfix = latest_branch.split(".")
        # Increment the minor version and reset bugfix to 0
        minor = str(int(minor) + 1)
        bugfix = "0"
    elif version == "bugfix":
        # Split the latest branch version into major, minor, and bugfix parts
        major, minor, bugfix = latest_branch.split(".")
        # Increment the bugfix version
        bugfix = str(int(bugfix) + 1)
    new_branch = f"{major}.{minor}.{bugfix}"

    print("Read the value of the 'version' key from Const")
    version_file = 'lib/common/const.dart'
    search_string = "  final String version = "
    with open(version_file, 'r') as file:
        lines = file.readlines()
        for line in lines:
            if line.startswith(search_string):
                version = line.split('=')[1].strip()
                break

    print("Checkout a new branch based on the latest branch")
    try:
        create_or_switch_branch(new_branch)
        # Update the version in const
        with open(version_file, 'w') as file:
            for line in lines:
                if line.startswith(search_string):
                    file.write(f'{search_string}"{new_branch}";\n')
                else:
                    file.write(line)
        pass
    except subprocess.CalledProcessError:
        print("ERROR: Failed to create new branch")
        sys.exit(1)

    print("dart fix")
    try:
        print("Applying dart fix")
        result = subprocess.run(["dart", "fix", "--apply"], capture_output=True, text=True, shell=True)
        print(result.stdout)
        if result.returncode != 0:
            print(result.stderr)
    except subprocess.CalledProcessError as e:
        print(f"CalledProcessError: {e}")
    except FileNotFoundError as e:
        print(f"FileNotFoundError: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

    print("Set the remote for the new branch and push")
    try:
        subprocess.check_output(["git", "push", "-u", "origin", new_branch])
        print("Remote set for new branch")
    except subprocess.CalledProcessError:
        print("Failed to set remote for new branch")


if __name__ == "__main__":
    main()
