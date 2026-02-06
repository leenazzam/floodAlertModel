from flask import Flask, jsonify
from flask_cors import CORS
from flask_compress import Compress
import json, os

app = Flask(__name__)
CORS(app)
Compress(app)

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")

def read_json(filename):
    path = os.path.join(DATA_DIR, filename)
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

@app.get("/api/streets")
def get_streets():
    return jsonify(read_json("streets.json"))

@app.get("/api/schools")
def get_schools():
    schools_data = read_json("schools.json")   
    streets_data = read_json("streets.json")   

    streets = streets_data.get("streets", [])

    street_risk = {}
    for s in streets:
        oid = s.get("osm_id")
        if oid is None:
            continue
        street_risk[int(oid)] = float(s.get("risk", 0.0))

    if isinstance(schools_data, dict):
        schools = schools_data.get("schools", [])
    else:
        schools = schools_data

    out = []
    for sch in schools:
        nsid = sch.get("nearest_street_osm_id")
        r = 0.0
        if nsid is not None:
            r = street_risk.get(int(nsid), 0.0)

        item = dict(sch)
        item["risk"] = r 
        out.append(item)

    if isinstance(schools_data, dict):
        result = dict(schools_data)
        result["schools"] = out
        return jsonify(result)

    return jsonify(out)


if __name__ == "__main__":
 app.run(host="0.0.0.0", port=5000, debug=False, threaded=True)