import os
import sys
import subprocess
import sys
from packaging.version import Version

apps = ["vkhgaruda", "vkhsangeetseva"]
reltype = ""
hostingsite = ""
rootdir = ""

def create_or_switch_branch(newversion, oldversion):
    """Create a new branch """
    subprocess.check_output(["git", "checkout", oldversion])
    subprocess.check_output(["git", "pull"])
    subprocess.check_output(["git", "checkout", "-b", newversion, oldversion])
    print(f"Created and switched to new branch: {newversion}")

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

def run_command(command):
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        print(f"Command '{command}' failed with error:\n{result.stderr}")
        sys.exit(1)
    return result.stdout.strip()

def replace_string_in_file(filepath, search_string, replacement_string):
    curdir = os.getcwd()
    os.chdir(rootdir)
    with open(filepath, 'r') as file:
        lines = file.readlines()
    with open(filepath, 'w') as file:
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

    print("Get the current version from pubspec.yaml")
    branch_from_version = False
    if len(sys.argv) > 1:
        oldversion = sys.argv[1]
        branch_from_version = True
    else:
        try:
            versions = []
            for app in apps:
                version_full = get_value_from_file(f'{app}/pubspec.yaml', "version")
                if version_full:
                    v = version_full.split('+')[0].strip()
                    versions.append(v)
            oldversion = max(versions, key=Version) if versions else None
        except Exception:
            print("Failed to retrieve version from pubspec.yaml")
            oldversion = None

    print("Increment the version number based on user selection")
    if branch_from_version and oldversion:
        # Use the provided version as base
        if version_type == "major":
            major, minor, bugfix = oldversion.split(".")
            major = str(int(major) + 1)
            minor = "0"
            bugfix = "0"
        elif version_type == "minor":
            major, minor, bugfix = oldversion.split(".")
            minor = str(int(minor) + 1)
            bugfix = "0"
        elif version_type == "bugfix":
            major, minor, bugfix = oldversion.split(".")
            bugfix = str(int(bugfix) + 1)
    else:
        # Branch from main - use latest version found or start fresh
        if oldversion:
            if version_type == "major":
                major, minor, bugfix = oldversion.split(".")
                major = str(int(major) + 1)
                minor = "0"
                bugfix = "0"
            elif version_type == "minor":
                major, minor, bugfix = oldversion.split(".")
                minor = str(int(minor) + 1)
                bugfix = "0"
            elif version_type == "bugfix":
                major, minor, bugfix = oldversion.split(".")
                bugfix = str(int(bugfix) + 1)
        else:
            # No version found, start with 1.0.0
            major, minor, bugfix = "1", "0", "0"
        oldversion = "main"
    
    newversion = f"{major}.{minor}.{bugfix}"

    print("Checkout a new branch based on the latest branch")
    try:
        create_or_switch_branch(newversion, oldversion)
        for app in apps:
            # Get the old build number from pubspec.yaml
            old_version_string = get_value_from_file(f'{app}/pubspec.yaml', "version")
            old_build_number = 1  # default if no build number exists
            if '+' in old_version_string:
                old_build_number = int(old_version_string.split('+')[1])
            # Set new version with incremented build number
            set_value_in_file(f'{app}/pubspec.yaml', "version", f'{newversion}+{old_build_number + 1}')
        set_value_in_file('vkhpackages/lib/common/const.dart', "version", f"\"{newversion}\";")
    except subprocess.CalledProcessError:
        print("ERROR: Failed to create new branch")
        sys.exit(1)
  
    print("set database path")
    set_value_in_file('vkhpackages/lib/common/const.dart', "dbrootGaruda", " \"TEST/GARUDA_01\";")
    set_value_in_file('vkhpackages/lib/common/const.dart', "dbrootSangeetSeva", " \"TEST/SANGEETSEVA_01\";")

    # No longer need to call increment_version_suffix since we already set the correct build number above

    print("Set the remote for the new branch and push")
    try:
        subprocess.check_output(["git", "push", "-u", "origin", newversion])
        print("Remote set for new branch")
    except subprocess.CalledProcessError:
        print("Failed to set remote for new branch")
   
    print("all operations completed")
    input("Recompute total time and start tracker...")


if __name__ == "__main__":
    main()
