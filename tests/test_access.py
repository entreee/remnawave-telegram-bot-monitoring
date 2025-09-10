from bot.services.access import AccessService


def test_login_logout(tmp_path):
    db = tmp_path / "access.db"
    svc = AccessService(db)
    svc.login(1, "alice")
    assert svc.is_authorized(1) is True
    svc.logout(1)
    assert svc.is_authorized(1) is False
