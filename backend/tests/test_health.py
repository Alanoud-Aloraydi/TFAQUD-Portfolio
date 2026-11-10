def test_health_endpoint_responds(client):
    response = client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_no_static_route_is_exposed(client):
    assert client.get("/static/anything").status_code == 404
