"""The privacy policy, the terms and the deletion page: open to anyone,
in Arabic, with the contact address when one is set."""

import pytest

PAGES = {
    "/privacy": "سياسة الخصوصية",
    "/terms": "الشروط والأحكام",
    "/delete-account": "حذف حساب تفقُد",
}


@pytest.mark.parametrize("path,heading", PAGES.items())
def test_each_page_opens_without_signing_in(client, path, heading):
    response = client.get(path)

    assert response.status_code == 200
    assert response.mimetype == "text/html"
    assert heading in response.get_data(as_text=True)


def test_the_contact_address_shows_when_set(client):
    client.application.config["LEGAL_CONTACT_EMAIL"] = "care@example.com"

    page = client.get("/privacy").get_data(as_text=True)

    assert 'href="mailto:care@example.com"' in page
