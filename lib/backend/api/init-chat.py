from flask import Flask, request, jsonify

def handler(request):
    data = request.get_json()
    return jsonify({
        "message": "Chat initialized",
        "received": data
    })
