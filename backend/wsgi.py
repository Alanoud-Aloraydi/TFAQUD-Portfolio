"""Entry point for running the server.

    flask --app wsgi run          local development
    python wsgi.py                the same, without the flask command
"""

from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False)
