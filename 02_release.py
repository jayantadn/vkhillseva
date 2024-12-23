import subprocess
import sys

def run_command(command):
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        print(f"Command '{command}' failed with error:\n{result.stderr}")
        sys.exit(1)
    return result.stdout.strip()

def main():
    print("get the version number")
    branch_name = run_command('git rev-parse --abbrev-ref HEAD')
    branch_name = branch_name.lstrip()

    print("generate the changelog from git log")
    base_branch = run_command('git merge-base origin/main HEAD')
    logs = run_command(f'git log {base_branch}..HEAD --pretty=%B')
    log_messages = logs.split('\n\n')
    filtered_log_messages = []
    for log_message in log_messages:
        first_line = log_message.split('\n')[0]
        if first_line.startswith("feature") or first_line.startswith("fix"):
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

    print("run the commands to build")   
    run_command("flutter clean")
    run_command("flutter pub get")
    run_command("flutter build web")
    run_command("firebase deploy --only hosting")
    run_command("git checkout *.cache")

    print("all operations completed")
    
if __name__ == '__main__':
    main()
