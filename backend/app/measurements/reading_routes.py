"""The normal ranges, the tasks and saved readings of some days, and
the export."""

from flask import jsonify

from app.authz.decorators import require_circle_role
from app.database import transaction
from app.extensions import get_clock
from app.measurements.blueprint import MEMBERS, bp
from app.measurements.queries import MeasurementQueries
from app.measurements.route_helpers import parse_range, parse_uuid


@bp.get("/measurement-ranges")
@require_circle_role(*MEMBERS)
def list_ranges(circle_id):
    """Read the normal ranges the patient's readings are judged by."""
    with transaction() as session:
        value = MeasurementQueries(session, get_clock().now()).ranges(
            parse_uuid(circle_id)
        )
    response = jsonify(measurement_ranges=value)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/measurement-occurrences")
@require_circle_role(*MEMBERS)
def list_occurrences(circle_id):
    """Calculate tasks for at most 35 calendar days."""
    dates = parse_range()
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).occurrences(
            parse_uuid(circle_id), dates.from_date, dates.to_date
        )
    response = jsonify(measurement_occurrences=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/measurement-readings")
@require_circle_role(*MEMBERS)
def list_readings(circle_id):
    """Read actual measurements and explicit skips."""
    dates = parse_range()
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).readings(
            parse_uuid(circle_id), dates.from_date, dates.to_date
        )
    response = jsonify(measurement_readings=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/measurement-readings/export")
@require_circle_role(*MEMBERS)
def export_readings(circle_id):
    """Return saved measurements for an authorized PDF export."""
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).all_readings(
            parse_uuid(circle_id)
        )
    response = jsonify(measurement_readings=values)
    response.headers["Cache-Control"] = "no-store"
    return response
