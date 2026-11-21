"""The privacy policy, the terms and the deletion page: open to anyone,
in Arabic, each with the project's address for questions."""

import pytest

PAGES = {
    "/privacy": "سياسة الخصوصية",
    "/terms": "الشروط والأحكام",
    "/delete-account": "حذف حساب تفقُد",
}


@pytest.mark.parametrize("path,heading", PAGES.items())
def test_each_page_opens_without_signing_in(client, path, heading):
    response = client.get(path)

    page = response.get_data(as_text=True)
    assert response.status_code == 200
    assert response.mimetype == "text/html"
    assert heading in page
    assert 'href="mailto:tafaqod.app@gmail.com"' in page
