import 'package:flutter/material.dart';
import '../data/models/payment.dart';

/// Dialog for manually adding a new payment.
class AddPaymentDialog extends StatefulWidget {
  const AddPaymentDialog({super.key});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final _subscriberNameController = TextEditingController();
  final _stampController = TextEditingController();
  final _typeController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _subscriberNameController.dispose();
    _stampController.dispose();
    _typeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة تسديد جديد'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _accountController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الحساب *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'مطلوب';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'يجب أن يكون رقماً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'مطلوب';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'يجب أن يكون رقماً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'التاريخ *',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subscriberNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المشترك',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stampController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الختم',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'النوع',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('إضافة')),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final payment = Payment(
      referenceAccountNumber: int.parse(_accountController.text.trim()),
      amount: double.parse(_amountController.text.trim()),
      paymentDate: _selectedDate.millisecondsSinceEpoch,
      subscriberName: _subscriberNameController.text.trim().isEmpty
          ? null
          : _subscriberNameController.text.trim(),
      stampNumber: _stampController.text.trim().isEmpty
          ? null
          : _stampController.text.trim(),
      type: _typeController.text.trim().isEmpty
          ? null
          : _typeController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    );

    Navigator.of(context).pop(payment);
  }
}
