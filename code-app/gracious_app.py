import boto3
import json
from flask import Flask, jsonify

def get_gracy_secrets():
    client = boto3.client('secretsmanager', region_name="us-east-1")
    response = client.get_secret_value(SecretId="Gracy-App-Secrets")
    return json.loads(response['SecretString'])

app = Flask(__name__)

@app.after_request
def apply_security_headers(response):
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Server'] = 'Webserver'
    response.headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
    response.headers['Cross-Origin-Opener-Policy'] = 'same-origin'
    response.headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
    response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, proxy-revalidate'
    return response

@app.route('/')
def hello():
    return jsonify({"message": "WELCOME TO your E-HEALTH PLATFORM by Gracious", "status": "Green", "security": "Hardened"})

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=False)