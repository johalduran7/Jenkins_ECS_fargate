from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

@app.route('/start-build', methods=['POST'])
def start_build():
    data = request.json
    destination = data.get("destination")

    if not destination:
        return jsonify({"status": "error", "message": "Missing 'destination' in request"}), 400

    try:
        result = subprocess.run([
            "/kaniko/executor",
            "--context", "/build/context",
            "--dockerfile", "/build/context/Dockerfile",
            "--destination", destination
        ], check=True, text=True, capture_output=True)

        return jsonify({"status": "success", "output": result.stdout})
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "output": e.stderr}), 500

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5001)
