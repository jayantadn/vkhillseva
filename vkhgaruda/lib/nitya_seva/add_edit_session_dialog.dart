import 'package:flutter/material.dart';
import 'package:vkhpackages/vkhpackages.dart';

class AddEditSessionDialog extends StatefulWidget {
  final Session? session;
  final List<FestivalSettings> sevaList;
  final List<String> sevaAmounts;
  final List<String> paymentModes;
  final String username;
  final DateTime now;
  final String dbDate;
  final Function(Session) onAddOrUpdate;

  const AddEditSessionDialog({
    Key? key,
    required this.session,
    required this.sevaList,
    required this.sevaAmounts,
    required this.paymentModes,
    required this.username,
    required this.now,
    required this.dbDate,
    required this.onAddOrUpdate,
  }) : super(key: key);

  @override
  State<AddEditSessionDialog> createState() => _AddEditSessionDialogState();
}

class _AddEditSessionDialogState extends State<AddEditSessionDialog> {
  late String _selectedSevaType;
  late String _selectedSeva;
  late String _sevaAmount;
  late String _paymentMode;
  late List<String> _sevaAmounts;
  late List<String> _paymentModes;

  final TextEditingController _festivalSevaAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSevaType = widget.session?.type ?? "Pushpanjali";
    _selectedSeva = widget.session?.name ?? "Nitya Seva";
    _sevaAmounts = List<String>.from(widget.sevaAmounts);
    _sevaAmount = widget.session?.defaultAmount.toString() ?? _sevaAmounts.first;
    _paymentModes = List<String>.from(widget.paymentModes);
    _paymentMode = widget.session?.defaultPaymentMode ?? _paymentModes.first;

    _festivalSevaAmountController.text = _sevaAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              // title
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 32),
                Text(
                  widget.session == null ? 'Add New Session' : 'Edit Session',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                // radio row Pushpanjali and Kumkum Archana
                SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSevaType = "Pushpanjali";
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedSevaType == "Pushpanjali"
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            "Pushpanjali",
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: _selectedSevaType == "Pushpanjali"
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSevaType = "Kumkum Archana";
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedSevaType == "Kumkum Archana"
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            border: Border(
                              top: BorderSide(
                                  color: Theme.of(context).colorScheme.primary),
                              right: BorderSide(
                                  color: Theme.of(context).colorScheme.primary),
                              bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            "Kumkum Archana",
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: _selectedSevaType == "Kumkum Archana"
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // seva dropdown
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _selectedSeva,
                  decoration: const InputDecoration(labelText: 'Seva'),
                  items: widget.sevaList.map((FestivalSettings value) {
                    return DropdownMenuItem<String>(
                      value: value.name,
                      child: Text(value.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      if (newValue != null) {
                        _selectedSeva = newValue;
                      }
                    });
                  },
                ),
                
                
                SizedBox(height: 16.0),
                Row(
                  children: [
                    // default seva amount
                    if(_selectedSeva == "Nitya Seva")
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sevaAmount,
                        decoration: const InputDecoration(
                            labelText: 'Default seva amount'),
                        items: _sevaAmounts.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _sevaAmount = newValue ?? _sevaAmounts.first;
                          });
                        },
                      ),
                    ),

                    // festival seva amount
                    if(_selectedSeva != "Nitya Seva")
                    Expanded(child: TextField(
                      controller: _festivalSevaAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Festival Seva amount',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _sevaAmount = value;
                        });
                      },
                    )),

                    // default payment mode
                    SizedBox(width: 16.0),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _paymentMode,
                        decoration: const InputDecoration(
                            labelText: 'Default payment mode'),
                        items: _paymentModes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _paymentMode = newValue ?? _paymentModes.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // cancel button
                    Expanded(
                      child: OutlinedButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          _sevaAmounts.clear();
                          _paymentModes.clear();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),

                    // add or update button
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        child: Text(widget.session == null ? 'Add' : 'Update'),
                        onPressed: () {
                          // validations
                          if (_selectedSeva != "Nitya Seva") {
                            if (_sevaAmount.isEmpty) {
                              Toaster().error("Please enter a valid seva amount");
                              return;
                            }
                            
                            final amount = int.tryParse(_sevaAmount);
                            if (amount == null || amount <= 0) {
                              Toaster().error("Please enter a valid seva amount");
                              return;
                            }
                          }

                          String icon = '';
                          for (var element in widget.sevaList) {
                            if (element.name == _selectedSeva) {
                              icon = element.icon;
                              break;
                            }
                          }
                          Session newSession = Session(
                            name: _selectedSeva,
                            type: _selectedSevaType,
                            defaultAmount: int.parse(_sevaAmount),
                            defaultPaymentMode: _paymentMode,
                            icon: icon,
                            sevakarta: widget.username,
                            timestamp: widget.session == null
                                ? widget.now
                                : widget.session!.timestamp,
                          );
                          widget.onAddOrUpdate(newSession);
                          _sevaAmounts.clear();
                          _paymentModes.clear();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
