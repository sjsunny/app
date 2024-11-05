import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_web/razorpay_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'package:http/http.dart' as http;


class Razor extends StatefulWidget {
  final int amount;
  final String currency;
  final String contact;
  final String email;
  const Razor({
    required this.amount,
    required this.currency,
    required this.contact,
    required this.email,
    Key? key,
  }) : super(key: key);
  //const Razor({Key? key}) : super(key: key);

  @override
  State<Razor> createState() => _RazorState();
}

class _RazorState extends State<Razor> {
  late Razorpay razorpay;

  @override
  void initState() {
    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, errorHandler);
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, successHandler);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, externalWalletHandler);
    super.initState();
  }



  TextEditingController amountController = TextEditingController();
  void errorHandler(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.message!),
      backgroundColor: Colors.red,
    ));
  }
  Future<void> postPaymentDataToFlask() async {

    const url =
        'https://umeed.app/payment_success'; // Replace with your Flask app's endpoint
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json', // Set the content type to JSON
      },
      body: jsonEncode({

        'userId': widget.email,
        'currency': widget.currency,
        'amount': widget.amount,
      }),
    );

    if (response.statusCode == 200) {
      // Data posted successfully.

      // Data sending failed, you can handle retries or other logic here
    }
  }
  void successHandler(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.paymentId!),
      backgroundColor: Colors.green,

    ));
    postPaymentDataToFlask();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MyApp(),
      ),
    );


  }

  void externalWalletHandler(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.walletName!),
      backgroundColor: Colors.green,
    ));
  }



  void openCheckout() {
    var options = {
      "key": "rzp_live_Z0qfc9VQ6G85BW",
      "amount": widget.amount,
      "name": "Umeed Matrimony Inc",
      "description": "Umeed Matrimony Inc Subscription",
      "timeout": "180",
      "currency": widget.currency,
      "prefill": {
        "contact": widget.contact,
        "email": widget.email,
      }
    };
    razorpay.open(options);
  }
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromRGBO(33, 37, 41, 1.0), // Set your desired status bar color
    ));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Razor pay",
          style: TextStyle(color: Colors.white), // Set app bar title text color to white
        ),
        backgroundColor: const Color.fromRGBO(33, 37, 41, 1.0),
        iconTheme: IconThemeData(color: Colors.white), // Set icon color to white// Set your desired app bar color
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Amount: ${widget.amount / 100} ${widget.currency}",
              style: TextStyle(fontSize: 24, color: Colors.black), // Set text color to white
            ),
            const SizedBox(
              height: 20,
            ),
            MaterialButton(
              onPressed: () {
                openCheckout();
              },
              color: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Set button border radius
              ), // Set button background color to green
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 70, vertical: 15),
                child: Text(
                  "Pay now",
                  style: TextStyle(color: Colors.white), // Set button text color to white
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}