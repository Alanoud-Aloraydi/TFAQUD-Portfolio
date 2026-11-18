"""Every endpoint of the API, and the request id, error handlers and
development CORS around them."""

from flask import Flask

from app.appointments.routes import bp as appointments_bp
from app.appointments.visit_routes import bp as appointment_visits_bp
from app.auth.routes import bp as auth_bp
from app.circles.creation_requests import bp as creation_requests_bp
from app.circles.invitations import bp as invitations_bp
from app.circles.previous import bp as previous_notifications_bp
from app.circles.routes import bp as circles_bp
from app.cors import register_development_cors
from app.demo_routes import bp as demo_bp
from app.errors import register_error_handlers
from app.health import bp as health_bp
from app.home import bp as home_bp
from app.measurements.routes import bp as measurements_bp
from app.medications.routes import bp as medications_bp
from app.photo_routes import bp as photos_bp
from app.prayer_times.routes import bp as prayer_times_bp
from app.push.routes import bp as push_bp
from app.push.tick_routes import bp as tick_bp
from app.request_context import register_request_id
from app.snoozes.routes import bp as snoozes_bp
from app.users.routes import bp as users_bp

BLUEPRINTS = (
    health_bp, auth_bp, users_bp, home_bp, circles_bp, creation_requests_bp,
    invitations_bp, previous_notifications_bp, medications_bp, photos_bp,
    measurements_bp, appointments_bp, appointment_visits_bp,
    prayer_times_bp, push_bp, tick_bp, snoozes_bp, demo_bp,
)


def register_endpoints(app: Flask) -> None:
    """Register the request id, the error handlers, CORS in development and
    every blueprint."""
    register_request_id(app)
    register_error_handlers(app)
    if app.config["APP_ENV"] == "development":
        register_development_cors(app)
    for blueprint in BLUEPRINTS:
        app.register_blueprint(blueprint)


def register_commands(app: Flask, database: bool) -> None:
    """The `flask --app wsgi` commands that need the database."""
    if not database:
        return
    # `tick`: the scheduled notification scan, which Render's cron job runs
    # every 10 minutes (render.yaml).
    from app.push.tick_command import tick_command

    app.cli.add_command(tick_command)
    if app.config["APP_ENV"] != "production":
        # `demo-data`: demo circles, medicines and doses for trying the app
        # on a local server (app/demo_data/).
        from app.demo_data import demo_data_command

        app.cli.add_command(demo_data_command)
        # `keep-only`: only some accounts stay, on a test server
        # (app/keep_only/).
        from app.keep_only import keep_only_command

        app.cli.add_command(keep_only_command)
