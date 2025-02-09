import subprocess
import sys
import os
import shutil

def run_command(command):
    print(f"Running command: {command}")
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        print(f"Command '{command}' failed with error:\n{result.stderr}")
        sys.exit(1)
    return result.stdout.strip()



def main():
    print("get the branch name")
    branch_name = run_command('git rev-parse --abbrev-ref HEAD')
    branch_name = branch_name.lstrip()

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

    print("write changelog")
    with open('changelog.md', 'r') as file:
        existing_contents = file.read()
    with open('changelog.md', 'w') as file:
        file.write(f'# {branch_name}\n')
        for log_message in log_messages:
            file.write(f'- {log_message}\n')
        file.write('\n')  
        file.write(existing_contents)

    # print("Undo main patch for testing")
    # main_file = 'lib/main.dart'
    # search_string = '        title: "ISKCON VK Hill Seva", theme: themeDefault, home: test);'
    # replacement_string = '        title: "ISKCON VK Hill Seva", theme: themeDefault, home: home);\n'
    # with open(main_file, 'r') as file:
    #     lines = file.readlines()
    # with open(main_file, 'w') as file:
    #     for line in lines:
    #         if search_string in line:
    #             file.write(replacement_string)
    #         else:
    #             file.write(line)

    # print("Applying dart fix")
    # try:
    #     result = subprocess.run(["dart", "fix", "--apply"], capture_output=True, text=True, shell=True)
    #     print(result.stdout)
    #     if result.returncode != 0:
    #         print(result.stderr)
    # except subprocess.CalledProcessError as e:
    #     print(f"CalledProcessError: {e}")
    # except FileNotFoundError as e:
    #     print(f"FileNotFoundError: {e}")
    # except Exception as e:
    #     print(f"An unexpected error occurred: {e}")

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
    

    try:
        print("commit all changes and push to git")
        if run_command('git status --porcelain'):
            run_command('git add -A')
            run_command(f'git commit -m "release {branch_name}"')
            run_command('git push origin')
            run_command('git checkout main')
            run_command('git pull')
            run_command(f'git merge {branch_name}')
            run_command('git push origin')
        else:
            print("No changes to commit")

        # print("building for web")
        # run_command("flutter clean")
        # run_command("flutter pub get")
        # run_command("flutter build web")
        # run_command("firebase deploy --only hosting:vkhgaruda")

        # print("building for android")
        # run_command("flutter build apk")
        # apk_path = "build/app/outputs/flutter-apk/app-release.apk"
        # new_apk_path = f"build/app/outputs/flutter-apk/vkhgaruda_v{branch_name}.apk"
        # if os.path.exists(apk_path):
        #     if os.path.exists(new_apk_path):
        #         os.remove(new_apk_path)
        #     os.rename(apk_path, new_apk_path)
        # else:
        #     print("ERROR: APK not found")

        # print("upload apk to my google drive")
        # drive_path = "X:/GoogleDrive/PublicRO/Garuda"
        # if os.path.exists(drive_path):
        #     shutil.copy(new_apk_path, drive_path)
        #     shutil.copy(os.path.join(drive_path, f'vkhgaruda_v{branch_name}.apk'), os.path.join(drive_path, 'vkhgaruda_latest.apk'))
        # else:
        #     print("ERROR: Google Drive not found in your local system")

    except Exception as e:
        print("reverting changes")
        run_command(f'git checkout {branch_name}')


    print("all operations completed")
    
if __name__ == '__main__':
    main()
