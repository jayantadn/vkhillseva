import json


input_json = r"X:\GoogleDrive\PublicRO\Garuda\database_backup\input.json"
output_json = r"X:\GoogleDrive\PublicRO\Garuda\database_backup\output.json"

def garuda1_to_garuda2():
    print("Migrating Garuda 1 to Garuda 2...")

    print("Reading input file...")
    with open(input_json, 'r') as file:
        input_data = json.load(file)

    output_data = {}

    dates = input_data['record_db1']['sevaSlots']
    for key in dates.keys():
        k = key[:10]
        output_data[k] = {}

    print("Writing output file...")
    with open(output_json, 'w') as file:
        json.dump(output_data, file, indent=2)

    print("Data migration completed.")

def main():
    garuda1_to_garuda2()

if __name__ == "__main__":
    main()