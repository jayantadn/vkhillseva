import json
import sys


input_json = r"input_deepotsava_2024.json"
output_json = r"output_deepotsava_2024.json"
template_json = r"X:\GoogleDrive\PublicRO\Garuda\database_backup\template-NityaSeva.json"

def migrate_sessions():
    print("Migrating Sessions...")

    print("Reading input file...")
    with open(input_json, 'r') as file:
        input_data = json.load(file)

    with open(template_json, 'r') as file:
        output_data = json.load(file)

    for session in input_data['record_db1']['sevaTickets']:
        for ticketKey in input_data['record_db1']['sevaTickets'][session]:
            ticket = input_data['record_db1']['sevaTickets'][session][ticketKey]
            db_date = ticket['timestampSlot'][:10]
            db_session = ticket['timestampSlot'].replace('.', '^')
            key = ticket['timestampTicket'].replace('.', '^')
            if ticket['amount'] == 400:
                image = "assets/images/LauncherIcons/NityaSeva.png"
                seva = "Pushpanjali"
            elif ticket['amount'] == 500:
                image = "assets/images/NityaSeva/tas.png"
                seva = "Tulasi Archana Seva"
            elif ticket['amount'] == 1000:
                image = "assets/images/Logo/KrishnaLilaPark_square.png"
                seva = "Mandir-marjana Seva"
            elif ticket['amount'] == 2500:
                image = "assets/images/NityaSeva/gita.png"
                seva = "Gita-Dana Seva"
            else:
                print("Unknown seva amount: ", ticket['amount'])
                sys.exit(1)
            t = {
                "amount": ticket['amount'],
                "image": image,
                "mode": ticket['mode'],
                "note": "",
                "seva": seva,
                "ticketNumber": ticket['ticket'],
                "timestamp": ticket['timestampTicket'],
                "user": ticket['user']
            }
            output_data[db_date][db_session]['Tickets'][key] = t
    
    print("Writing output file...")
    with open(output_json, 'w') as file:
        json.dump(output_data, file, indent=2)

    print("Data migration completed.")

def import_deepotsava():
    output_data = {
        'RKC' : {
            'Sales': {}
        },
        'RRG' : {
            'Sales': {}
        }
    }

    with open(input_json, 'r') as file:
        input_data = json.load(file)

        print("processing RKC sales")
        rkc_sales = input_data['record_db1']['deepotsava']['RKC']['sales']
        for sale in rkc_sales:
            dbdate = rkc_sales[sale]['timestamp'][:10]
            dbtime = rkc_sales[sale]['timestamp'].replace('.', '^')
            if dbdate not in output_data['RKC']['Sales']:
                output_data['RKC']['Sales'][dbdate] = {}
            output_data['RKC']['Sales'][dbdate][dbtime] = {
                'count' : rkc_sales[sale]['count'],
                'deepamPrice': rkc_sales[sale]['costLamp'],
                'isPlateIncluded': False if rkc_sales[sale]['plate'] == 0 else True,
                'paymentMode': rkc_sales[sale]['paymentMode'],
                'platePrice': rkc_sales[sale]['costPlate'],
                'timestamp': rkc_sales[sale]['timestamp'],
                'username': rkc_sales[sale]['user']
            }
            
        print("processing RRG sales")
        rkc_sales = input_data['record_db1']['deepotsava']['RRG']['sales']
        for sale in rkc_sales:
            dbdate = rkc_sales[sale]['timestamp'][:10]
            dbtime = rkc_sales[sale]['timestamp'].replace('.', '^')
            if dbdate not in output_data['RRG']['Sales']:
                output_data['RRG']['Sales'][dbdate] = {}
            output_data['RRG']['Sales'][dbdate][dbtime] = {
                'count' : rkc_sales[sale]['count'],
                'deepamPrice': rkc_sales[sale]['costLamp'],
                'isPlateIncluded': False if rkc_sales[sale]['plate'] == 0 else True,
                'paymentMode': rkc_sales[sale]['paymentMode'],
                'platePrice': rkc_sales[sale]['costPlate'],
                'timestamp': rkc_sales[sale]['timestamp'],
                'username': rkc_sales[sale]['user']
            }

    with open(output_json, 'w') as file:
        json.dump(output_data, file, indent=2)
    print(f"Data written to {output_json}")
    

def main():
    # migrate_sessions()
    import_deepotsava()

if __name__ == "__main__":
    main()