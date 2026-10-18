def test_health_endpoint_responds(client):
    response = client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_health_needs_no_sign_in(client):
    response = client.get("/api/v1/health")

    assert response.status_code != 401


def test_no_static_route_is_exposed(client):
    assert client.get("/static/anything").status_code == 404
