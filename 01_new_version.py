import os
import sys
import subprocess
import sys
from packaging.version import Version

app = ""
reltype = ""
hostingsite = ""
rootdir = ""

def create_or_switch_branch(newversion, oldversion):
    """Create a new branch """
    subprocess.check_output(["git", "checkout", oldversion])
    subprocess.check_output(["git", "pull"])
    subprocess.check_output(["git", "checkout", "-b", newversion, oldversion])
    print(f"Created and switched to new branch: {newversion}")

def run_command(command):
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        print(f"Command '{command}' failed with error:\n{result.stderr}")
        sys.exit(1)
    return result.stdout.strip()

def replace_string_in_file(file, search_string, replacement_string):
    curdir = os.getcwd()
    os.chdir(rootdir)
    with open(file, 'r') as file:
        lines = file.readlines()
    with open(file, 'w') as file:
        for line in lines:
            if search_string in line:
                file.write(replacement_string)
            else:
                file.write(line)   
    os.chdir(curdir)

def set_value_in_file(filepath, search_string, value):
    curdir = os.getcwd()
    os.chdir(rootdir)
    with open(filepath, 'r') as file:
        lines = file.readlines()
    with open(filepath, 'w') as file:
        for line in lines:
            if search_string in line:
                if '=' in line:
                    key, _ = line.split('=', 1)
                    file.write(f'{key}={value}\n')
                elif ':' in line:
                    key, _ = line.split(':', 1)
                    file.write(f'{key}: {value}\n')
            else:
                file.write(line)   
    os.chdir(curdir)

def get_value_from_file(filepath, search_string):
    ret = ""
    curdir = os.getcwd()
    os.chdir(rootdir)
    with open(filepath, 'r') as file:
        lines = file.readlines()
    for line in lines:
        if line.startswith("#"):
            continue
        if search_string in line:
            if '=' in line:
                _, value = line.split('=', 1)
                ret = value.strip()
                break
            elif ':' in line:
                key, value = line.split(':', 1)
                ret = value.strip()
                break
    return ret
    os.chdir(curdir)

def main():
    global rootdir
    rootdir = run_command('git rev-parse --show-toplevel')

    # Prompt for version type
    versionid = input("Enter version type (1. major, 2. minor, 3. bugfix): ")
    if versionid == "1":
        version_type = "major"
    elif versionid == "2":
        version_type = "minor"
    elif versionid == "3":
        version_type = "bugfix"
    else:
        print("Invalid version type")
        sys.exit(1)



    print("Get the latest remote branch")
    if len(sys.argv) > 1:
        oldversion = sys.argv[1]
    else:
        try:
            output = subprocess.check_output(["git", "ls-remote", "--heads", "origin"]).decode("utf-8")
            branches = [line.split("\t")[1].split("refs/heads/")[1] for line in output.splitlines()]
            branches = [branch for branch in branches if branch.count('.') == 2 and all(part.isdigit() for part in branch.split('.'))]
            oldversion = max(branches, key=Version)
        except subprocess.CalledProcessError:
            print("Failed to retrieve remote branches")

    print("Increment the version number based on user selection")
    if version_type == "major":
        # Split the latest branch version into major, minor, and bugfix parts
        major, minor, bugfix = oldversion.split(".")
        # Increment the major version and reset minor and bugfix to 0
        major = str(int(major) + 1)
        minor = "0"
        bugfix = "0"
    elif version_type == "minor":
        # Split the latest branch version into major, minor, and bugfix parts
        major, minor, bugfix = oldversion.split(".")
        # Increment the minor version and reset bugfix to 0
        minor = str(int(minor) + 1)
        bugfix = "0"
    elif version_type == "bugfix":
        # Split the latest branch version into major, minor, and bugfix parts
        major, minor, bugfix = oldversion.split(".")
        # Increment the bugfix version
        bugfix = str(int(bugfix) + 1)
    newversion = f"{major}.{minor}.{bugfix}"

    print("Checkout a new branch based on the latest branch")
    try:
        create_or_switch_branch(newversion, oldversion)
        set_value_in_file('vkhgaruda/pubspec.yaml', "version", f'{newversion}+1')
        set_value_in_file('vkhsangeetseva/pubspec.yaml', "version", f'{newversion}+1')
        set_value_in_file('vkhpackages/lib/common/const.dart', "version", f"\"{newversion}\";")
    except subprocess.CalledProcessError:
        print("ERROR: Failed to create new branch")
        sys.exit(1)
  
    print("set database path")
    set_value_in_file('vkhpackages/lib/common/const.dart', "dbrootGaruda", " \"TEST/GARUDA_01\";")
    set_value_in_file('vkhpackages/lib/common/const.dart', "dbrootSangeetSeva", " \"TEST/SANGEETSEVA_01\";")

    print("Set the remote for the new branch and push")
    try:
        subprocess.check_output(["git", "push", "-u", "origin", newversion])
        print("Remote set for new branch")
    except subprocess.CalledProcessError:
        print("Failed to set remote for new branch")

    print("all operations completed")


if __name__ == "__main__":
    main()
