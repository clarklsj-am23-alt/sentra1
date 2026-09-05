import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/transit_card_model.dart';
import '../services/card_database_service.dart';
import '../services/transit_card_cloud_service.dart';
import '../../live_arrivals/services/gtfs_service.dart';

const Color appYellow = Color(0xFFFCEB00);

class TransitDashboardScreen extends StatefulWidget {
  const TransitDashboardScreen({super.key});

  @override
  State<TransitDashboardScreen> createState() => _TransitDashboardScreenState();
}

class _TransitDashboardScreenState extends State<TransitDashboardScreen> {
  final _dbService = CardDatabaseService.instance;
  final _cloudService = TransitCardCloudService();
  final _gtfsService = GtfsService();

  List<TransitArrival> _liveArrivals = [];
  bool _loadingArrivals = false;

  // Transit Cards State
  List<TransitCard> _cards = [];
  bool _loadingCards = true;

  // Schedules & Transport Mode State
  String _selectedType = 'LRT';

  @override
  void initState() {
    super.initState();
    _loadCardsData();
    _loadSchedules(_selectedType);
  }

  Future<void> _loadCardsData() async {
    setState(() => _loadingCards = true);
    final cards = await _dbService.getAllCards();
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _loadingCards = false;
    });
  }

  Future<void> _loadSchedules(String mode) async {
    setState(() => _loadingArrivals = true);
    final arrivals = await _gtfsService.fetchArrivalsByMode(mode);
    if (!mounted) return;
    setState(() {
      _liveArrivals = arrivals;
      _loadingArrivals = false;
    });
  }

  void _showCardActions(TransitCard card) async {
    final topUpCtrl = TextEditingController();
    List<CardTransaction> transactions = [];

    if (card.id != null) {
      try {
        transactions = await _dbService.getTransactionsByCard(card.id!);
      } catch (e) {
        debugPrint('Could not fetch transactions: $e');
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      card.cardName,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete Card',
                    onPressed: () async {
                      if (card.id != null) {
                        await _dbService.deleteCard(card.id!);
                        await _cloudService.deleteCardFromCloud(card.id!);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadCardsData();
                      }
                    },
                  ),
                ],
              ),
              Text(
                'Card No: ${card.cardNumber} (${card.cardType})',
                style: GoogleFonts.dmSans(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                'Current Balance: RM ${card.balance.toStringAsFixed(2)}',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              Text(
                'Quick Top Up',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [10, 20, 50].map((amount) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(
                        '+ RM $amount',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: appYellow.withValues(alpha: 0.3),
                      onPressed: () async {
                        if (card.id != null) {
                          final newBal = card.balance + amount;
                          await _dbService.updateBalance(card.id!, newBal);
                          await _cloudService.syncCardToCloud(
                            TransitCard(
                              id: card.id,
                              cardName: card.cardName,
                              cardNumber: card.cardNumber,
                              balance: newBal,
                              cardType: card.cardType,
                            ),
                          );
                          try {
                            await _dbService.logTransaction(
                              cardId: card.id!,
                              title: 'Quick Top Up',
                              amount: amount.toDouble(),
                              type: 'TOP_UP',
                            );
                          } catch (_) {}
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadCardsData();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topUpCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: appYellow,
                  ),
                  onPressed: () async {
                    final amount =
                        double.tryParse(topUpCtrl.text.trim()) ?? 0.0;
                    if (amount > 0 && card.id != null) {
                      final newBal = card.balance + amount;
                      await _dbService.updateBalance(card.id!, newBal);
                      await _cloudService.syncCardToCloud(
                        TransitCard(
                          id: card.id,
                          cardName: card.cardName,
                          cardNumber: card.cardNumber,
                          balance: newBal,
                          cardType: card.cardType,
                        ),
                      );
                      try {
                        await _dbService.logTransaction(
                          cardId: card.id!,
                          title: 'Manual Top Up',
                          amount: amount,
                          type: 'TOP_UP',
                        );
                      } catch (_) {}
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadCardsData();
                    }
                  },
                  child: Text(
                    'Top Up Now',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Divider(height: 24),
              Text(
                'Recent Transactions',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                Text(
                  'No transactions recorded yet.',
                  style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 13),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: transactions.length,
                    itemBuilder: (context, idx) {
                      final tx = transactions[idx];
                      final isTopUp = tx.type == 'TOP_UP';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isTopUp ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isTopUp ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          tx.title,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          tx.date,
                          style: GoogleFonts.dmSans(fontSize: 11),
                        ),
                        trailing: Text(
                          '${isTopUp ? '+' : '-'} RM ${tx.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: isTopUp ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCardDialog() {
    final nameCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    final balCtrl = TextEditingController();
    String type = 'OKU Concession';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Add Transit Card',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Card Label (e.g. My Concession TnG)',
                  ),
                ),
                TextField(
                  controller: numCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Card Number / Serial',
                  ),
                ),
                TextField(
                  controller: balCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Initial Balance (RM)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(
                      value: 'Standard Adult',
                      child: Text('Standard Adult'),
                    ),
                    DropdownMenuItem(
                      value: 'OKU Concession',
                      child: Text('OKU Concession (50% Off)'),
                    ),
                    DropdownMenuItem(
                      value: 'Student',
                      child: Text('Student Concession'),
                    ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: appYellow,
              ),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && balCtrl.text.isNotEmpty) {
                  final newCard = TransitCard(
                    cardName: nameCtrl.text.trim(),
                    cardNumber: numCtrl.text.trim(),
                    balance: double.tryParse(balCtrl.text.trim()) ?? 0.0,
                    cardType: type,
                  );
                  final insertedId = await _dbService.insertCard(newCard);
                  final cardWithId = TransitCard(
                    id: insertedId,
                    cardName: newCard.cardName,
                    cardNumber: newCard.cardNumber,
                    balance: newCard.balance,
                    cardType: newCard.cardType,
                  );
                  await _cloudService.syncCardToCloud(cardWithId);

                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadCardsData();
                }
              },
              child: const Text('Save Card'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules & Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card, color: appYellow),
            tooltip: 'Add Card',
            onPressed: _showAddCardDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. TRANSIT CARDS WALLET
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transit Cards & Pass',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: Text(
                  'Add New',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                onPressed: _showAddCardDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 145,
            child: _loadingCards
                ? const Center(child: CircularProgressIndicator())
                : _cards.isEmpty
                ? Center(
                    child: Text(
                      'No transit cards added yet.',
                      style: GoogleFonts.dmSans(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cards.length,
                    itemBuilder: (ctx, i) {
                      final card = _cards[i];
                      final isOku = card.cardType.contains('OKU');

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showCardActions(card),
                        child: Container(
                          width: 270,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isOku
                                ? Colors.black
                                : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isOku ? appYellow : Colors.grey.shade800,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      card.cardName,
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: appYellow,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          card.cardType,
                                          style: GoogleFonts.dmSans(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4.0),
                                        child: Icon(
                                          Icons.more_vert,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                'RM ${card.balance.toStringAsFixed(2)}',
                                style: GoogleFonts.dmSans(
                                  color: appYellow,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    card.cardNumber,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Text(
                                    'Manage',
                                    style: TextStyle(
                                      color: appYellow,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 24),

          // 2. SEGMENTED TRANSPORT MODE & SCHEDULE LIST
          Text(
            'Select Transport Mode',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'LRT',
                label: Text('LRT'),
                icon: Icon(Icons.train),
              ),
              ButtonSegment(
                value: 'MRT',
                label: Text('MRT'),
                icon: Icon(Icons.subway),
              ),
              ButtonSegment(
                value: 'Rapid Bus',
                label: Text('Bus'),
                icon: Icon(Icons.directions_bus),
              ),
              ButtonSegment(
                value: 'KTM',
                label: Text('KTM'),
                icon: Icon(Icons.directions_railway),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedType = newSelection.first;
              });
              _loadSchedules(_selectedType);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedType,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh live arrivals',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
                onPressed: () => _loadSchedules(_selectedType),
              ),
              const SizedBox(width: 8),
              Chip(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                label: Text(
                  '${_liveArrivals.length} Arrivals',
                  style: GoogleFonts.dmSans(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: appYellow,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingArrivals)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._liveArrivals.map(
              (arrival) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Text(
                      _selectedType.substring(0, 1),
                      style: GoogleFonts.dmSans(
                        color: appYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    arrival.line,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'To ${arrival.destination} • ${arrival.platform}',
                          style: GoogleFonts.dmSans(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (arrival.isStepFree)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.accessible,
                              size: 14,
                              color: Colors.black,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Step-Free',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: appYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${arrival.arrivalMinutes} min',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'LIVE',
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
