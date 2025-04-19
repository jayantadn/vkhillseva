import subprocess
import sys
import os
import shutil

reltype = ""
hostingsite = ""
rootdir = ""

def run_command(command):
    print(f"Running command: {command}")
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        print(f"Command '{command}' failed with error:\n{result.stderr}")
        sys.exit(1)
    return result.stdout.strip()

def update_changelog(version):       
    print("generate the changelog from git log")
    base_branch = run_command('git merge-base origin/main HEAD')
    logs = run_command(f'git log {base_branch}..HEAD --pretty=%B')
    log_messages = logs.split('\n\n')
    filtered_log_messages = []
    for log_message in log_messages:
        first_line = log_message.split('\n')[0]
        if first_line.startswith("feature:") or first_line.startswith("fix:"):
            filtered_log_messages.append(log_message)
    log_messages = filtered_log_messages
    log_messages.reverse()

    print("write changelog")
    with open('changelog.md', 'r') as file:
        existing_contents = file.read()
    with open('changelog.md', 'w') as file:
        file.write(f'# {version}\n')
        for log_message in log_messages:
            file.write(f'- {log_message}\n')
        file.write('\n')  
        file.write(existing_contents)

def set_parameters():
    global rootdir
    global reltype

    rootdir = run_command('git rev-parse --show-toplevel')
    
    if len(sys.argv) == 2:
        reltype = sys.argv[1]
    else:
        relid = input("Enter the release type: 1. Release 2. Test ")
        if relid == '1':
            reltype = 'release'
        elif relid == '2':
            reltype = 'test'
        else:
            print("Invalid release type")
            sys.exit(1)
    print(f"Release type: {reltype}")
    
def set_hosting_site(app):
    global hostingsite
    if(app == 'vkhgaruda' and reltype == 'release'):
        hostingsite = 'vkhillgaruda'
    elif(app == 'vkhgaruda' and reltype == 'test'):
        hostingsite = 'testgaruda'    
    elif(app == 'vkhsangeetseva' and reltype == 'release'):
        hostingsite = 'govindasangetseva'
    elif(app == 'vkhsangeetseva' and reltype == 'test'):
        hostingsite = 'testsangeetseva'
    else:
        print("Hosting site could not be determined")
        sys.exit(1)
    print(f"Hosting site: {hostingsite}")

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

def release(app):
    os.chdir(rootdir)
        
    print("get the branch name")
    branch_name = run_command('git rev-parse --abbrev-ref HEAD')
    branch_name = branch_name.lstrip()
    if branch_name == 'main':
        value = get_value_from_file(f"{app}/pubspec.yaml", "version")
        version = value.split('+')[0]
    else:
        version = branch_name
        update_changelog(version)

    print("Changing directory to app folder")
    try:
        os.chdir(app)
    except FileNotFoundError:
        print(f"Error: '{app}' directory not found.")
        sys.exit(1)

    print("Undo main patch for testing")
    main_file = f'{rootdir}/{app}/lib/main.dart'
    search_string = '      home: test,'
    replacement_string = '      home: home,\n'
    with open(main_file, 'r') as file:
        lines = file.readlines()
    with open(main_file, 'w') as file:
        for line in lines:
            if search_string in line:
                file.write(replacement_string)
            else:
                file.write(line)

    print("Applying dart fix")
    os.chdir(f"{rootdir}/{app}")
    try:
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

    # print("update the list of icons")
    # src_file = 'pubspec.yaml'
    # src_contents = "- assets/images/"
    # images = []
    # dst_file = 'lib/common/const.dart'
    # dst_start = 'final List<String> icons = ['
    # dst_end = '];'
    # with open(src_file, 'r') as file:
    #     src_lines = file.readlines()
    #     for line in src_lines:
    #         if src_contents in line:
    #             image = line.strip()
    #             image = image[1:]
    #             image = image.strip()
    #             images.append(image.strip())
    # with open(dst_file, 'r') as file:
    #     dst_lines = file.readlines()
    # with open(dst_file, 'w') as file:
    #     flag_start = False
    #     for line in dst_lines:
    #         if line.strip() == dst_start:
    #             flag_start = True
    #             file.write(line)
    #             for image in images:
    #                 file.write(f'      "{image}",\n')
    #         else:
    #             if(not flag_start):
    #                 file.write(line)
    #             else:
    #                 if line.strip() == dst_end:
    #                     file.write(line)
    #                     flag_start = False
    
    print("set database path")
    prefix = ""
    if(reltype == 'test'):
        prefix = "TEST/"
    set_value_in_file('vkhpackages/lib/common/const.dart', "final String dbrootGaruda", f" \"{prefix}GARUDA_01\";" )
    set_value_in_file('vkhpackages/lib/common/const.dart', "final String dbrootSangeetSeva", f" \"{prefix}SANGEETSEVA_01\";" )

    try:
        print("commit all changes and push to git")
        if run_command('git status --porcelain'):
            run_command('git add -A')
            if branch_name == "main":
                run_command('git commit -m "post release changes"')
            else:
                run_command(f'git commit -m "release {branch_name}"')
            run_command('git push origin')
            if branch_name != "main":
                run_command('git checkout main')
                run_command('git pull')
                run_command(f'git merge {branch_name}')
                run_command('git push origin')
        else:
            print("No changes to commit")

        print("building for web")
        run_command("flutter clean")
        run_command("flutter pub get")
        run_command("flutter build web")
        set_hosting_site(app)
        run_command(f"firebase deploy --only hosting:{hostingsite}")

        if reltype == 'release':
            print("building for android")
            run_command("flutter build apk")
            apk_path = "build/app/outputs/flutter-apk/app-release.apk"
            new_apk_path = f"build/app/outputs/flutter-apk/vkhgaruda_v{version}.apk"
            if os.path.exists(apk_path):
                if os.path.exists(new_apk_path):
                    os.remove(new_apk_path)
                os.rename(apk_path, new_apk_path)
            else:
                print("ERROR: APK not found")

            print("upload apk to my google drive")
            drive_path = "X:/GoogleDrive/PublicRO/Garuda"
            if os.path.exists(drive_path):
                shutil.copy(new_apk_path, drive_path)
                shutil.copy(os.path.join(drive_path, f'vkhgaruda_v{version}.apk'), os.path.join(drive_path, 'vkhgaruda_latest.apk'))
            else:
                print("ERROR: Google Drive not found in your local system")

    except Exception as e:
        print("reverting changes")
        run_command(f'git checkout {branch_name}')


    print("all operations completed")

def main():
    set_parameters()
    release("vkhgaruda")
    release("vkhsangeetseva")

if __name__ == '__main__':
    main()
