from remna_client.endpoints.overview import parse as parse_overview
from remna_client.endpoints.nodes import parse as parse_nodes


def test_overview_parser():
    ov = parse_overview({"status": "ok"})
    assert ov.status == "ok"


def test_nodes_parser():
    nodes = parse_nodes([{"name": "n1", "status": "up", "cpu": 0.5}])
    assert nodes[0].name == "n1"
    assert nodes[0].cpu == 0.5
