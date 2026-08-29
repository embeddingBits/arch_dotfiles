from flask import Flask, request
import json

app = Flask(__name__)

@app.route('/data', methods=['POST'])
def receive():
    payload = request.json.get('payload', [])
    for item in payload:
        if item['name'] == 'gyroscope':
            data = {
                'x': item['values']['x'],
                'y': item['values']['y'],
                'z': item['values']['z']
            }
            with open('/tmp/gyro.json', 'w') as f:
                json.dump(data, f)
    return 'OK', 200

app.run(host='0.0.0.0', port=5000)
