from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    version = os.environ.get('APP_VERSION', 'v1')
    message = os.environ.get('APP_MESSAGE', 'Hello from IoT App')
    return jsonify({
        "status": "ok",
        "message": message,
        "version": version
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8888, debug=False)
