from bot.services.i18n import I18n


def test_translation_default():
    i18n = I18n()
    assert i18n.t("start") == "Старт"


def test_translation_en():
    i18n = I18n(default="en")
    assert i18n.t("help") == "Help"


def test_missing_key_returns_key():
    i18n = I18n()
    assert i18n.t("missing") == "missing"
