from flask import Flask, request, jsonify
from dotenv import load_dotenv
from web3 import Web3
import os

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Infura API Key (Ethereum RPC)
INFURA_API_KEY = os.getenv("96200534d4d240ad9f0c26bbbb038b64")
ETH_RPC_URL = f"https://mainnet.infura.io/v3/{96200534d4d240ad9f0c26bbbb038b64}"

# Initialize Web3
w3 = Web3(Web3.HTTPProvider(https://mainnet.infura.io/v3/{96200534d4d240ad9f0c26bbbb038b64))


@app.route("/get_token_balance", methods=["GET"])
def get_tokens():
    """Fetch ETH balance for a given wallet address."""
    address = request.args.get("address")

    if not w3.is_address(address):
        return jsonify({"error": "Invalid Ethereum address"}), 400

    try:
        balance_wei = w3.eth.get_balance(address)
        balance_eth = w3.from_wei(balance_wei, 'ether')

        return jsonify({"address": address, "balance": f"{balance_eth} ETH"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002, debug=True)
