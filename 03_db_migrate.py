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

    input_sessions = input_data['record_db1']['sevaSlots']
    for key in input_sessions.keys():
        k = key[:10]
        if len(input_sessions[key]['title']) == 11:
            name = "Nitya Seva"
            type = "Pushpanjali"
            icon = "assets/images/LauncherIcons/NityaSeva.png"
        else:
            if k == "2024-08-16":
                name = "Jhulan Utsava"
                type = "Kumkum Archana"
                icon = "assets/images/Festivals/JhulanUtsava.png"
            if k == "2024-08-25" or k == "2024-08-26":
                name = "Sri Krishna Janmastami"
                type = "Pushpanjali"
                icon = "assets/images/VKHillDieties/RadhaKrishna.png"
            if k == "2024-09-11":
                name = "Radhastami"
                type = "Kumkum Archana"
                icon = "assets/images/VKHillDieties/Padmavati.png"
            if k == "2024-11-01":
                name = "Deepavali"
                type = "Kumkum Archana"
                icon = "assets/images/LauncherIcons/Deepotsava.png"
            if key == "2025-01-01T09:35:16^675724" or key == "2025-01-01T14:34:22^628284":
                name = "Shubharambh"
                type = "Kumkum Archana"
                icon = "assets/images/NityaSeva/sadhu_seva.png"
            if key == "2025-01-01T09:58:17^992928" or key == "2025-01-01T14:30:43^349520":
                name = "Shubharambh"
                type = "Pushpanjali"
                icon = "assets/images/NityaSeva/sadhu_seva.png"
        session_settings = {
            "defaultAmount": 400,
            "defaultPaymentMode": "UPI",
            "icon": icon,
            "name": name,
            "sevakarta": input_sessions[key]['sevakartaSlot'],
            "timestamp": input_sessions[key]['timestampSlot'],
            "type": type
        }
        session_contents = {"Settings": session_settings, "Tickets": {}}
        if k in output_data.keys():
            output_data[k].update({key: session_contents})
        else:
            output_data[k] = {key: session_contents}

    print("Writing output file...")
    with open(output_json, 'w') as file:
        json.dump(output_data, file, indent=2)

    print("Data migration completed.")

def main():
    migrate_sessions()

if __name__ == "__main__":
    main()