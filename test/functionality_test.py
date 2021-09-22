from types import BuiltinMethodType
import google.auth
import pytest
import requests

@pytest.mark.usefixtures("service_url")
def test_check_content(service_url):
    client = requests.session()

    page = client.get(service_url)
    assert page.status_code == 200
    assert "Unicodex" in page.text

    page = client.get(service_url + "/u/1F44B")
    assert page.status_code == 200
    assert "Waving" in page.text

@pytest.mark.usefixtures("service_url", "get_admin_login")
def test_admin_workflow(service_url, get_admin_login):
    headers = {"Referer": service_url}
    login_slug = "/admin/login/?next=/admin/"
    fixture_code = "1F44B"
    model_admin_slug = "/admin/unicodex/codepoint/"

    client = requests.session()

    # Login
    admin_username, admin_password = get_admin_login

    client.get(service_url + login_slug, headers=headers)
    response = client.post(
        service_url + login_slug,
        data={
            "username": admin_username,
            "password": admin_password,
            "csrfmiddlewaretoken": client.cookies["csrftoken"],
        },
        headers=headers,
    )
    assert response.status_code == 200
    assert "Site administration" in response.text
    assert "Codepoints" in response.text

    # Try admin action
    response = client.post(
        service_url + model_admin_slug,
        data={
            "action": "generate_designs",
            "_selected_action": 1,
            "csrfmiddlewaretoken": client.cookies["csrftoken"],
        },
        headers=headers,
    )
    assert response.status_code == 200
    assert "Imported vendor versions" in response.text

    # check updated feature
    response = client.get(service_url + f"/u/{fixture_code}")
    assert fixture_code in response.text
    assert "Android" in response.text
