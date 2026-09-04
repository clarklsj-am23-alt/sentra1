import 'package:flutter/material.dart';
import '../models/transit_card_model.dart';
import '../services/card_database_service.dart';
import '../services/fare_calculation_service.dart';
import '../../live_arrivals/services/gtfs_service.dart';

class TransitDashboardScreen extends StatefulWidget {
  const TransitDashboardScreen({super.key});

  @override
  State<TransitDashboardScreen> createState() => _TransitDashboardScreenState();
}

class _TransitDashboardScreenState extends State<TransitDashboardScreen> {
  final _dbService = CardDatabaseService.instance;
  final _gtfsService = GtfsService();

  List<TransitCard> _cards = [];
  List<TransitArrival> _arrivals = [];
  bool _loading = true;

  int _hops = 4;
  String _selectedCardType = 'OKU Concession';
  double _calculatedFare = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    final cards = await _dbService.getAllCards();
    final arrivals = await _gtfsService.fetchLiveArrivals('KL Sentral');

    if (!mounted) return;
    setState(() {
      _cards = cards;
      _arrivals = arrivals;
      _calculatedFare = FareCalculationService.calculateFare(
        stationHops: _hops,
        cardType: _selectedCardType,
      );
      _loading = false;
    });
  }

  void _showAddCardDialog() {
    final nameCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    final balCtrl = TextEditingController();
    String type = 'Standard Adult';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Transit Card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Card Label (e.g. My Concession TnG)'),
                ),
                TextField(
                  controller: numCtrl,
                  decoration: const InputDecoration(labelText: 'Card Number / Serial'),
                ),
                TextField(
                  controller: balCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Initial Balance (RM)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'Standard Adult', child: Text('Standard Adult')),
                    DropdownMenuItem(value: 'OKU Concession', child: Text('OKU Concession (50% Off)')),
                    DropdownMenuItem(value: 'Student', child: Text('Student Concession')),
                  ],
                  onChanged: (val) => setDialogState(() => type = val!),
                  decoration: const InputDecoration(labelText: 'Card Category'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && balCtrl.text.isNotEmpty) {
                  final newCard = TransitCard(
                    cardName: nameCtrl.text.trim(),
                    cardNumber: numCtrl.text.trim(),
                    balance: double.tryParse(balCtrl.text.trim()) ?? 0.0,
                    cardType: type,
                  );
                  await _dbService.insertCard(newCard);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadAllData();
                }
              },
              child: const Text('Save Card'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardActions(TransitCard card) {
    final topUpCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.cardName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete Card',
                  onPressed: () async {
                    if (card.id != null) {
                      await _dbService.deleteCard(card.id!);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadAllData();
                    }
                  },
                ),
              ],
            ),
            Text(
              'Card No: ${card.cardNumber} (${card.cardType})',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              'Current Balance: RM ${card.balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            const Text(
              'Quick Top Up',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [10, 20, 50].map((amount) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text('+ RM $amount'),
                    onPressed: () async {
                      if (card.id != null) {
                        await _dbService.updateBalance(
                          card.id!,
                          card.balance + amount,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadAllData();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: topUpCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Custom Amount (RM)',
                prefixText: 'RM ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(topUpCtrl.text.trim()) ?? 0.0;
                  if (amount > 0 && card.id != null) {
                    await _dbService.updateBalance(
                      card.id!,
                      card.balance + amount,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadAllData();
                  }
                },
                child: const Text('Top Up Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fares & Transit Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_card),
            onPressed: _showAddCardDialog,
            tooltip: 'Add Card',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Transit Cards', style: Theme.of(context).textTheme.titleMedium),
              TextButton(onPressed: _showAddCardDialog, child: const Text('+ Add New')),
            ],
          ),
          SizedBox(
            height: 150,
            child: _cards.isEmpty
                ? const Center(child: Text('No cards saved. Add a Touch \'n Go card.'))
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cards.length,
              itemBuilder: (ctx, i) {
                final card = _cards[i];
                return InkWell(
                  onTap: () => _showCardActions(card), // <-- Opens top-up & delete sheet
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: card.cardType.contains('OKU')
                            ? [Colors.teal.shade700, Colors.teal.shade900]
                            : [Colors.blue.shade700, Colors.indigo.shade900],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              card.cardName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              card.cardType,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'RM ${card.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          card.cardNumber,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('Quick Fare Rate Estimator', style: Theme.of(context).textTheme.titleMedium),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
// ✅ Fixed code:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Distance: $_hops stops',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        'Est. Fare: RM ${_calculatedFare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    min: 1,
                    max: 20,
                    divisions: 19,
                    value: _hops.toDouble(),
                    onChanged: (val) {
                      setState(() {
                        _hops = val.toInt();
                        _calculatedFare = FareCalculationService.calculateFare(
                          stationHops: _hops,
                          cardType: _selectedCardType,
                        );
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: _selectedCardType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Standard Adult', child: Text('Standard Adult Rate')),
                      DropdownMenuItem(value: 'OKU Concession', child: Text('OKU Concession (50% Off)')),
                      DropdownMenuItem(value: 'Student', child: Text('Student Rate (50% Off)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCardType = val;
                          _calculatedFare = FareCalculationService.calculateFare(
                            stationHops: _hops,
                            cardType: _selectedCardType,
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Live GTFS Station Arrivals (KL Sentral)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._arrivals.map((arrival) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey.shade100,
                child: const Icon(Icons.directions_subway, color: Colors.blueGrey),
              ),
              title: Text('${arrival.routeId} -> ${arrival.destination}'),
              subtitle: Text(arrival.platform),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${arrival.arrivalMinutes} min',
                  style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}