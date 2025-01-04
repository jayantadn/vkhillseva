import json


input_json = r"X:\GoogleDrive\PublicRO\Garuda\database_backup\input.json"
output_json = r"X:\GoogleDrive\PublicRO\Garuda\database_backup\output.json"
template_json = r"X:\GoogleDrive\PublicRO\Garuda\database_backup\template-NityaSeva.json"

def migrate_sessions():
    print("Migrating Sessions...")

    print("Reading input file...")
    with open(input_json, 'r') as file:
        input_data = json.load(file)

    with open(template_json, 'r') as file:
        output_data = json.load(file)

    for session in input_data['record_db1']['sevaTickets']:
        print (session)
    
    print("Writing output file...")
    with open(output_json, 'w') as file:
        json.dump(output_data, file, indent=2)

    print("Data migration completed.")

def main():
    migrate_sessions()

if __name__ == "__main__":
    main()