import sys
import subprocess
import sys
from packaging.version import Version

def create_or_switch_branch(new_branch):
    """Create a new branch """
    subprocess.check_output(["git", "checkout", "main"])
    subprocess.check_output(["git", "pull"])
    subprocess.check_output(["git", "checkout", "-b", new_branch, "main"])
    print(f"Created and switched to new branch: {new_branch}")

def run_command(command):
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        print(f"Command '{command}' failed with error:\n{result.stderr}")
        sys.exit(1)
    return result.stdout.strip()

def main():
    # choose the project
    projectid = input("Enter project (1. Garuda, 2. SangeetSeva): ")
    if projectid == "1":
        project = "vkhgaruda"
    elif projectid == "2":
        project = "vkhsangeetseva"
    else:
        print("Invalid project")
        sys.exit(1)

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



    print("Read the value of the 'version' key from Const")
    version_file = f'{project}/lib/common/const.dart'
    search_string = "  final String version = "
    with open(version_file, 'r') as file:
        lines = file.readlines()
        for line in lines:
            if line.startswith(search_string):
                version = line.split('=')[1].strip()
                break
    version = version.replace('"', "");

    print("Increment the version number based on user selection")
    if version_type == "major":
        # Split the latest branch version into major, minor, and bugfix parts
        major, minor, bugfix = version.split(".")
        # Increment the major version and reset minor and bugfix to 0
        major = str(int(major) + 1)
        minor = "0"
        bugfix = "0"
    elif version_type == "minor":
        # Split the latest branch version into major, minor, and bugfix parts
        major, minor, bugfix = version.split(".")
        # Increment the minor version and reset bugfix to 0
        minor = str(int(minor) + 1)
        bugfix = "0"
    elif version_type == "bugfix":
        # Split the latest branch version into major, minor, and bugfix parts
        major, minor, bugfix = version.split(".")
        # Increment the bugfix version
        bugfix = str(int(bugfix) + 1)
    new_branch = f"{project}_{major}.{minor}.{bugfix}"


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

    # print("main patch for testing")
    main_file = f'{project}/lib/main.dart'
    search_string = '        title: "ISKCON VK Hill Seva", theme: themeDefault, home: home);'
    replacement_string = '        title: "ISKCON VK Hill Seva", theme: themeDefault, home: test);\n'
    with open(main_file, 'r') as file:
        lines = file.readlines()
    with open(main_file, 'w') as file:
        for line in lines:
            if search_string in line:
                file.write(replacement_string)
            else:
                file.write(line)

    print("Set the remote for the new branch and push")
    try:
        subprocess.check_output(["git", "push", "-u", "origin", new_branch])
        print("Remote set for new branch")
    except subprocess.CalledProcessError:
        print("Failed to set remote for new branch")

    print("all operations completed")


if __name__ == "__main__":
    main()
