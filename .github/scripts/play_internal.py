"""Uploads a signed app bundle to Google Play's internal testing track.

android-test.yml runs it as:
    python play_internal.py <app-release.aab> <release notes>
with the PLAY_SERVICE_ACCOUNT secret (a service account's JSON key) in the
environment. Google Play must already know the app: the first bundle is
uploaded by hand in Play Console.
"""

import json
import os
import sys

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

PACKAGE = "com.tfaqud.tfaqud"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def publish(play, bundle: str, notes: str, status: str) -> str:
    """One edit: upload the bundle, put it on the internal track with
    [status], commit. Returns the bundle's version code."""
    edits = play.edits()
    edit = edits.insert(packageName=PACKAGE, body={}).execute()["id"]
    media = MediaFileUpload(
        bundle, mimetype="application/octet-stream", resumable=True
    )
    code = str(
        edits.bundles()
        .upload(packageName=PACKAGE, editId=edit, media_body=media)
        .execute()["versionCode"]
    )
    release = {
        "versionCodes": [code],
        "status": status,
        "releaseNotes": [{"language": "ar", "text": notes[:500]}],
    }
    edits.tracks().update(
        packageName=PACKAGE,
        editId=edit,
        track="internal",
        body={"track": "internal", "releases": [release]},
    ).execute()
    edits.commit(packageName=PACKAGE, editId=edit).execute()
    return code


def main(bundle: str, notes: str) -> None:
    credentials = service_account.Credentials.from_service_account_info(
        json.loads(os.environ["PLAY_SERVICE_ACCOUNT"]), scopes=SCOPES
    )
    play = build(
        "androidpublisher", "v3", credentials=credentials,
        cache_discovery=False,
    )
    try:
        code = publish(play, bundle, notes, "completed")
        print(f"Version {code} is on internal testing.")
    except HttpError as error:
        # Until Google Play has reviewed the app once, a release can only
        # be a draft, which waits in Play Console for «Start rollout».
        if "draft app" not in str(error):
            raise
        code = publish(play, bundle, notes, "draft")
        print(
            f"::notice::Version {code} waits as a draft: Play Console, "
            "Test and release, Internal testing, then Start rollout."
        )


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
