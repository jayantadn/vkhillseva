import subprocess
import sys
import os
import shutil
import json
import argparse
from datetime import datetime, time
import firebase_admin
from firebase_admin import credentials
import requests

reltype = ""
hostingsite = ""
rootdir = ""
target = "both"  # Default: build both web and apk
app_selection = "both"  # Default: release both apps
verbose = False  # Default: detailed logging disabled
warnings = []  # Collect warnings to display at the end


def is_temple_service_time(now=None):
    if now is None:
        now = datetime.now()

    # Saturday=5, Sunday=6
    if now.weekday() not in (5, 6):
        return False

    current_time = now.time()
    windows = [
        (time(9, 30), time(13, 45)),
        (time(15, 45), time(20, 45)),
    ]

    return any(start <= current_time <= end for start, end in windows)


def update_remote_config(param_key, param_value, cred_file="../garuda-1ba07-firebase-adminsdk-fbsvc-c07e3d6e0a.json"):
    """Update a Firebase Remote Config parameter.
    
    Args:
        param_key: The parameter key to update
        param_value: The value to set
        cred_file: Path to the Firebase credentials JSON file
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Initialize Firebase app if not already initialized
        try:
            app = firebase_admin.get_app()
        except ValueError:
            cred = credentials.Certificate(cred_file)
            app = firebase_admin.initialize_app(cred)
            cred = credentials.Certificate(cred_file)
        else:
            # Get credentials from existing app
            cred = credentials.Certificate(cred_file)
        
        # Get access token
        access_token = cred.get_access_token().access_token
        project_id = app.project_id
        
        # Remote Config REST API endpoint
        base_url = f"https://firebaseremoteconfig.googleapis.com/v1/projects/{project_id}/remoteConfig"
        
        # Get current template
        headers = {
            "Authorization": f"Bearer {access_token}",
        }
        response = requests.get(base_url, headers=headers)
        template = response.json()
        
        # Update or add the parameter
        if "parameters" not in template:
            template["parameters"] = {}
        
        template["parameters"][param_key] = {
            "defaultValue": {
                "value": param_value
            }
        }
        
        # Update the template
        headers["Content-Type"] = "application/json; UTF-8"
        etag = response.headers.get("ETag")
        if etag:
            headers["If-Match"] = etag
        
        response = requests.put(base_url, headers=headers, json=template)
        if response.status_code == 200:
            print("Remote Config updated successfully!")
            print(f"{param_key} set to: {param_value}")
            return True
        else:
            print(f"Error updating Remote Config: {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"Error updating Remote Config: {e}")
        return False


def run_command(command, retries=0, retry_delay=5):
    """Run a shell command with optional retry mechanism.
    
    Args:
        command: The command to execute
        retries: Number of times to retry on failure (default: 0)
        retry_delay: Seconds to wait between retries (default: 5)
    
    Returns:
        Command output as string
    """
    import time
    
    attempt = 0
    max_attempts = retries + 1
    
    while attempt < max_attempts:
        if verbose:
            if attempt > 0:
                print(f"Retry attempt {attempt}/{retries} for command: {command}")
            else:
                print(f"Running command: {command}")
        
        result = subprocess.run(
            command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        if result.returncode == 0:
            if verbose and result.stdout:
                print(f"Command output:\n{result.stdout}")
            return result.stdout.strip()
        
        # Command failed
        attempt += 1
        if attempt < max_attempts:
            print(f"Command '{command}' failed (attempt {attempt}/{max_attempts})")
            print(f"Error: {result.stderr}")
            print(f"Retrying in {retry_delay} seconds...")
            time.sleep(retry_delay)
        else:
            # Final attempt failed
            print(f"Command '{command}' failed after {max_attempts} attempts with error:\n{result.stderr}")
            sys.exit(1)
    
    return result.stdout.strip()


def update_changelog(app, version):
    print("updating effort")
    effort_hr = 0
    try:
        with open('.timetracker', 'r') as f:
            timetracker_data = json.load(f)
            effort_sec = timetracker_data.get('total', 0)
            effort_hr = effort_sec // 3600
        os.unlink('.timetracker')
    except FileNotFoundError:
        print(".timetracker file not found, skipping effort update.")
    except Exception as e:
        print(f"Error reading .timetracker: {e}")

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

    changelog_file = f"{app}/changelog_{app}.json"
    print("write changelog")
    with open(changelog_file, 'r') as file:
        changelog = json.load(file)
        if f"{version}" in changelog.keys():
            effort = changelog[f"{version}"]['effort']
            effort = effort.replace('h', '')
            effort = float(effort) + effort_hr
            changelog[f"{version}"]['effort'] = f"{effort}h"
            for msg in log_messages:
                if msg.startswith("feature:"):
                    clean_msg = msg.replace("feature:", "").strip()
                    if clean_msg not in changelog[f"{version}"]['features']:
                        changelog[f"{version}"]['features'].append(clean_msg)
                elif msg.startswith("fix:"):
                    clean_msg = msg.replace("fix:", "").strip()
                    if clean_msg not in changelog[f"{version}"]['fixes']:
                        changelog[f"{version}"]['fixes'].append(clean_msg)
        else:
            changelog[f"{version}"] = {
                'effort': "",
                'features': [],
                'fixes': []
            }
            changelog[f"{version}"]['effort'] = f"{effort_hr}h"
            for msg in log_messages:
                if msg.startswith("feature:"):
                    clean_msg = msg.replace("feature:", "").strip()
                    changelog[f"{version}"]['features'].append(clean_msg)
                elif msg.startswith("fix:"):
                    clean_msg = msg.replace("fix:", "").strip()
                    changelog[f"{version}"]['fixes'].append(clean_msg)
    # Sort the changelog dictionary by keys in descending order using semantic versioning
    def version_key(version_string):
        """Convert version string to tuple of integers for proper sorting."""
        try:
            return tuple(map(int, version_string.split('.')))
        except ValueError:
            # If parsing fails, return a tuple that sorts to the end
            return (0, 0, 0)
    
    changelog = dict(
        sorted(changelog.items(), key=lambda x: version_key(x[0]), reverse=True))
    with open(changelog_file, 'w') as file:
        json.dump(changelog, file, indent=4)

    print("Testcases refreshing")
    with open('vkhgaruda/test/nitya_seva.md', 'r+') as testspec:
        content = testspec.read()
        testspec.seek(0)
        testspec.write(content.replace("-[x]", "-[]"))
        testspec.truncate()
        # Load the updated changelog
        with open(changelog_file, 'r') as f:
            changelog = json.load(f)

        # Get the first (latest) version's features
        first_version = next(iter(changelog))
        features = changelog[first_version].get('features', [])

        # Read the test spec again to update after "# new features"
        testspec.seek(0)
        content = testspec.read()
        split_marker = "# new features"
        if split_marker in content:
            before, _ = content.split(split_marker, 1)
            new_content = before + split_marker + "\n"
            for feature in features:
                new_content += f"-[] {feature}\n"
            testspec.seek(0)
            testspec.write(new_content)
            testspec.truncate()

def set_parameters():
    global rootdir
    global reltype
    global target
    global app_selection
    global verbose

    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description='Build and release Flutter application',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 02_release.py --type release
  python 02_release.py --type release --target web
  python 02_release.py --type release --target apk
  python 02_release.py --type test --target both
  python 02_release.py -t release -T web
  python 02_release.py --type release --app vkhgaruda
  python 02_release.py --type release --app vkhsangeetseva
  python 02_release.py --type release --app both
  python 02_release.py --type release --verbose
        '''
    )
    parser.add_argument(
        '-t', '--type',
        choices=['release', 'test'],
        required=True,
        help='Release type: release or test'
    )
    parser.add_argument(
        '-T', '--target',
        choices=['web', 'apk', 'both'],
        default='both',
        help='Build target: web, apk, or both (default: both)'
    )
    parser.add_argument(
        '-a', '--app',
        choices=['vkhgaruda', 'vkhsangeetseva', 'both'],
        default='both',
        help='App to release: vkhgaruda, vkhsangeetseva, or both (default: both)'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable detailed logging of commands being run'
    )
    
    args = parser.parse_args()
    
    reltype = args.type
    target = args.target
    app_selection = args.app
    verbose = args.verbose
    
    print(f"Release type: {reltype}")
    print(f"Target: {target}")
    print(f"App: {app_selection}")
    print(f"Verbose logging: {verbose}")

    rootdir = run_command('git rev-parse --show-toplevel')


def set_hosting_site(app):
    global hostingsite
    if (app == 'vkhgaruda' and reltype == 'release'):
        hostingsite = 'vkhillgaruda'
    elif (app == 'vkhgaruda' and reltype == 'test'):
        hostingsite = 'testgaruda'
    elif (app == 'vkhsangeetseva' and reltype == 'release'):
        hostingsite = 'govindasangeetseva'
    elif (app == 'vkhsangeetseva' and reltype == 'test'):
        hostingsite = 'testsangeetseva'
    else:
        print("Hosting site could not be determined")
        sys.exit(1)
    print(f"Hosting site: {hostingsite}")


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


def has_firebase_functions(app):
    """Check if the app has Firebase functions configured.
    
    Args:
        app: The app name (e.g., 'vkhgaruda' or 'vkhsangeetseva')
        
    Returns:
        bool: True if functions are configured, False otherwise
    """
    try:
        firebase_json_path = f"{rootdir}/{app}/firebase.json"
        if not os.path.exists(firebase_json_path):
            return False
        
        with open(firebase_json_path, 'r') as f:
            firebase_config = json.load(f)
            # Check if 'functions' key exists and is not empty
            return 'functions' in firebase_config and len(firebase_config['functions']) > 0
    except Exception as e:
        print(f"Warning: Could not check Firebase functions configuration: {e}")
        return False




def release(app):
    os.chdir(rootdir)

    print("get the branch name")
    branch_name = run_command('git rev-parse --abbrev-ref HEAD')
    branch_name = branch_name.lstrip()
    version_full = get_value_from_file(f"{app}/pubspec.yaml", "version")
    if not version_full:
        print(f"ERROR: Could not read version from {app}/pubspec.yaml")
        sys.exit(1)

    version = version_full.split('+')[0].strip()
    version_suffix = version_full.split('+')[1].strip() if '+' in version_full else "0"

    if branch_name != 'main':
        update_changelog(app, version)

    print("Changing directory to app folder")
    try:
        os.chdir(app)
    except FileNotFoundError:
        print(f"Error: '{app}' directory not found.")
        sys.exit(1)

    if branch_name != 'main':
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
            result = subprocess.run(
                "dart fix --apply", capture_output=True, text=True, shell=True)
            print(result.stdout)
            if result.returncode != 0:
                print(result.stderr)
        except subprocess.CalledProcessError as e:
            print(f"CalledProcessError: {e}")
        except FileNotFoundError as e:
            print(f"FileNotFoundError: {e}")
        except Exception as e:
            print(f"An unexpected error occurred: {e}")

        print("set database path")
        prefix = ""
        if (reltype == 'test'):
            prefix = "TEST/"
        set_value_in_file('vkhpackages/lib/common/const.dart',
                          "final String dbrootGaruda", f" \"{prefix}GARUDA_01\";")
        set_value_in_file('vkhpackages/lib/common/const.dart',
                          "final String dbrootSangeetSeva", f" \"{prefix}SANGEETSEVA_01\";")

        print("commit all changes and push to git")
        if run_command('git status --porcelain'):
            run_command('git add -A')
            if branch_name == "main":
                run_command('git commit -m "post release changes"')
            else:
                run_command(f'git commit -m "release {branch_name}"')
            run_command('git push origin')
            # disabling merge to main to prevent merge changes due to version change in pubspec
            if branch_name != "main" and reltype == 'release':
                run_command('git checkout main')
                run_command('git pull')
                run_command(f'git merge {branch_name}')
                run_command('git push origin')
        else:
            print("No changes to commit")

    # Build based on target parameter
    run_command("flutter clean")
    run_command("flutter pub get")

    if target in ['web', 'both']:
        print("building for web")
        run_command("flutter build web")
        print("publish web app")
        set_hosting_site(app)
        deploy_command = f"firebase deploy --only hosting:{hostingsite}"
        run_command(deploy_command, retries=2, retry_delay=10)

    if reltype == 'release':
        
        # sanity checks
        cred_file = "../garuda-1ba07-firebase-adminsdk-fbsvc-c07e3d6e0a.json"
        if not os.path.isfile(cred_file):
            print(f"ERROR: Required Firebase credentials file not found: {cred_file}")
            print("Aborting release to prevent Remote Config update failure.")
            sys.exit(1)

        # function deployment
        if has_firebase_functions(app):
            print("deploying firebase functions")
            run_command("firebase deploy --only functions", retries=2, retry_delay=10)
        else:
            print(f"Skipping Firebase functions deployment - no functions configured for {app}")

        if target in ['apk', 'both']:
            # android build
            print("building for android")
            run_command("flutter build apk --release")
            apk_path = "build/app/outputs/flutter-apk/app-release.apk"
            new_apk_path = f"build/app/outputs/flutter-apk/vkhgaruda_v{version}.apk"
            if os.path.exists(apk_path):
                if os.path.exists(new_apk_path):
                    os.remove(new_apk_path)
                os.rename(apk_path, new_apk_path)

                # Upload Garuda APK to Google Drive
                if app == 'vkhgaruda':
                    gdrive_sync_paths = [
                        "/media/GoogleDrive/Documents/Spiritual/Garuda_releases",
                        "W:\\media\\GoogleDrive\\Documents\\Spiritual\\Garuda_releases"
                    ]
                    gdrive_path = None
                    for path in gdrive_sync_paths:
                        if os.path.exists(path) and os.path.isdir(path):
                            gdrive_path = path
                            break
                    if gdrive_path:
                        dest_path = os.path.join(gdrive_path, os.path.basename(new_apk_path))
                        try:
                            shutil.copy2(new_apk_path, dest_path)
                            print(f"APK copied to Google Drive: {dest_path}")
                        except Exception as e:
                            print(f"Failed to copy APK to Google Drive: {e}")
                    else:
                        print("Google Drive sync folder not found, skipping upload")

            else:
                print("ERROR: APK not found")
        print("update firebase remote config")
        # Get app prefix by removing 'vkh' from app name
        app_prefix = app[3:]  # Remove first 3 characters

        # Update Remote Config values
        print(f"Setting {app_prefix}_trigger_update = true")
        update_remote_config(f"{app_prefix}_trigger_update", "true", cred_file=cred_file)

        print(f"Setting {app_prefix}_version = {version}")
        update_remote_config(f"{app_prefix}_version", version, cred_file=cred_file)

        print(f"Setting {app_prefix}_version_suffix = {version_suffix}")
        update_remote_config(f"{app_prefix}_version_suffix", version_suffix, cred_file=cred_file)


    if branch_name != "main" and reltype == 'release':
        print("Checking out main branch after release")
        run_command('git checkout main')
        run_command('git pull')

    print("all operations completed")


def main():
    set_parameters()

    if reltype == 'release' and is_temple_service_time():
        warning = (
            "Warning: Release started during temple service time "
            "(Saturday/Sunday with 30-minute buffer)."
        )
        warnings.append(warning)
        print("\n" + "!" * 70)
        print(warning)
        print("Proceeding may impact service time. Press Enter to continue or Ctrl+C to cancel.")
        print("!" * 70 + "\n")
        input()

    input("Please stop the timetracker if running...")
    
    if app_selection in ['vkhgaruda', 'both']:
        release("vkhgaruda")
    
    if app_selection in ['vkhsangeetseva', 'both']:
        release("vkhsangeetseva")
    
    # Print all warnings at the end
    if warnings:
        print("\n" + "="*70)
        print("⚠️  WARNINGS SUMMARY")
        print("="*70)
        for i, warning in enumerate(warnings, 1):
            print(f"{i}. {warning}")
        print("="*70)
    else:
        print("\n✅ All operations completed successfully with no warnings!")
  



if __name__ == '__main__':
    main()
