from bot.config import Config


def test_config_parses_urls_and_defaults(monkeypatch):
    monkeypatch.setenv("BOT_TOKEN", "TOKEN")
    monkeypatch.setenv("ACCESS_PASSWORD", "pw")
    monkeypatch.setenv("REMNA_BASE_URLS", "https://a,https://b")
    cfg = Config()
    assert cfg.remna_base_urls == ["https://a", "https://b"]
    assert cfg.refresh_default == 15
    assert cfg.enable_prometheus is False


def test_api_key_mapping(monkeypatch):
    monkeypatch.setenv("BOT_TOKEN", "TOKEN")
    monkeypatch.setenv("ACCESS_PASSWORD", "pw")
    monkeypatch.setenv("REMNA_BASE_URLS", "https://a,https://b")
    monkeypatch.setenv("REMNA_AUTH_MODE", "api_key")
    monkeypatch.setenv("REMNA_API_KEY", "https://a|k1,https://b|k2")
    cfg = Config()
    assert cfg.api_key_map["https://a"] == "k1"
    assert cfg.api_key_map["https://b"] == "k2"


def test_chat_ids_parsing(monkeypatch):
    monkeypatch.setenv("BOT_TOKEN", "TOKEN")
    monkeypatch.setenv("ACCESS_PASSWORD", "pw")
    monkeypatch.setenv("REMNA_BASE_URLS", "https://a")
    monkeypatch.setenv("ALERT_CHAT_IDS", "1,2")
    cfg = Config()
    assert cfg.alert_chat_ids == [1, 2]
