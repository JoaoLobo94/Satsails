import 'dart:typed_data';
import 'package:lwk_dart/lwk_dart.dart';
import 'package:satsails/models/liquid_config_model.dart';
import 'dart:convert';
import 'package:http/http.dart';

class LiquidModel {
  final Liquid config;

  LiquidModel(this.config);

  Future<String> getAddress() async {
    final address = await config.liquid.wallet.lastUnusedAddress();
    return address.confidential;
  }

  Future<bool> sync() async {
    await config.liquid.wallet.sync(config.electrumUrl);
    return true;
  }

  Future<Balances> balance() async {
    final Balances balance = await config.liquid.wallet.balance();
    return balance;
  }

  Future<List<Tx>> txs() async {
    final txs = await config.liquid.wallet.txs();
    return txs;
  }

  Future<String> build_lbtc_tx(TransactionBuilder params) async {
    try {
      final pset = await config.liquid.wallet.build_lbtc_tx(
        sats: params.amount,
        outAddress: params.outAddress,
        // hardcorded until we have a way to send sats/vb
        absFee: params.fee * (2048 + 1 * 85),
      );
      return pset;
    } on LwkError catch (e) {
      throw e.msg;
    }
  }

  // hardcorded until we have a drain wallet
  Future<String> build_drain_wallet_tx(TransactionBuilder params) async {
    var amount = params.amount;
    while (true) {
      try {
        final pset = await config.liquid.wallet.build_lbtc_tx(
          sats: amount,
          outAddress: params.outAddress,
          // hardcorded until we have a way to send sats/vb
          absFee: params.fee * (2048 + 1 * 85),
        );
        return pset;
      } on LwkError catch (e) {
        if (amount > 0) {
          amount -= 100;
        } else {
          throw e.msg;
        }
      }
    }
  }

  Future<String> build_asset_tx(TransactionBuilder params) async {
    try {
    final pset = await config.liquid.wallet.build_asset_tx(
      sats: params.amount,
      outAddress: params.outAddress,
      // hardcorded until we have a way to send sats/vb
      absFee: params.fee * (2048 + 1 * 85),
      assetId: params.assetId,
    );
    return pset;
    } on LwkError catch (e) {
      throw e.msg;
    }
  }

  Future<PsetAmounts> decode(String pset) async {
    final decodedPset = await config.liquid.wallet.decode(pset: pset);
    return decodedPset;
  }

  Future<Uint8List> sign(SignParams params) async {
    final signedTxBytes =
    await config.liquid.wallet.sign(network: config.liquid.network, pset: params.pset, mnemonic: params.mnemonic);

    return signedTxBytes;
  }

  Future<String> broadcast(Uint8List signedTxBytes) async {
    try {
      final tx = await config.liquid.wallet.broadcast(electrumUrl: config.electrumUrl, txBytes: signedTxBytes);
      return tx;
    } on LwkError catch (e) {
      throw e.msg;
    }
  }


  Future<double> getLiquidFees(int blocks) async {
    try {
      Response response =
      await get(Uri.parse('https://blockstream.info/liquid/api/fee-estimates'));
      Map data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data[blocks.toString()];
      } else {
        throw Exception("Getting estimated fees is not successful.");
      }
    } catch (_) {
      rethrow;
    }
  }
}


class Liquid {
  final LiquidConfig liquid;
  final String electrumUrl;

  Liquid({
    required this.liquid,
    required this.electrumUrl,
  });
}

class TransactionBuilder {
  final int amount;
  final String outAddress;
  final double fee;
  final String assetId;

  TransactionBuilder({
    required this.amount,
    required this.outAddress,
    required this.fee,
    required this.assetId,
  });
}

class SignParams {
  final String pset;
  final String mnemonic;

  SignParams({
    required this.pset,
    required this.mnemonic,
  });
}