"""Demo data for trying the app against a local server.

    flask --app wsgi demo-data            make the demo data
    flask --app wsgi demo-data --reset    delete it and make it fresh
    flask --app wsgi demo-data --if-missing   make it only when it is not
                                              there (the server's start on
                                              Render, with DEMO_DATA=true)

It makes two demo accounts and fills the first one with care circles,
medicines of every kind and a month of dose records. Everything goes through
the app's own services (care, medical file, medication plans, dose records),
with the clock set back where the story needs it, so every row is one the
app could have made itself and the database rules check all of it.

Not for production: it refuses to run there. The demo numbers are made up,
so a real SMS to them could reach a stranger: it runs only with the fake SMS
sender (a demo account signs in with the code it writes in the server log),
or with DEMO_SIGN_IN_CODE set (the demo accounts sign in with that code and
get no SMS; app/sms/demo.py), as on the shared test server on Render, where
/internal/demo-data makes it fresh each morning."""

from app.demo_accounts import DEMO_ACCOUNTS, DEMO_PHONES
from app.demo_data.builder import DemoBuilder
from app.demo_data.command import demo_data_command
from app.demo_data.lifecycle import (
    demo_allowed,
    rebuild_demo,
    remove_demo_accounts,
)
from app.demo_data.shapes import Summary
from app.demo_data.story import (
    DEMO_ZONE,
    EVERY_DAY,
    HISTORY_DAYS,
    INVITED_PHONE,
    JEDDAH_POINT,
    LONDON_POINT,
    OPEN_WINDOW,
    REQUEST_PHONE,
    RIYADH_POINT,
    SKIP_REASONS,
)

__all__ = [
    "DEMO_ACCOUNTS",
    "DEMO_PHONES",
    "DEMO_ZONE",
    "DemoBuilder",
    "EVERY_DAY",
    "HISTORY_DAYS",
    "INVITED_PHONE",
    "JEDDAH_POINT",
    "LONDON_POINT",
    "OPEN_WINDOW",
    "REQUEST_PHONE",
    "RIYADH_POINT",
    "SKIP_REASONS",
    "Summary",
    "demo_allowed",
    "demo_data_command",
    "rebuild_demo",
    "remove_demo_accounts",
]
