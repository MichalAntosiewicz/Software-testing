import requests


class ApiLibraryPython2:
    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self, base_url):
        self.base_url = base_url.rstrip("/")

    def _parse_body(self, response):
        try:
            return response.json()
        except ValueError:
            text = response.text.strip()
            return text if text else {}

    def attach_ue(self, ue_id):
        """Attaches UE to web."""
        url = f"{self.base_url}/ues"
        payload = {"ue_id": ue_id}
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def reset_app_state(self):
        """Reset app state using endpoint: POST /reset."""
        url = f"{self.base_url}/reset"
        response = requests.post(url)
        return int(response.status_code)

    def get_ue(self, ue_id):
        """Get connected UE additional info."""
        url = f"{self.base_url}/ues/{ue_id}"
        response = requests.get(url)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def add_bearer(self, ue_id, bearer_id):
        """Add a bearer to an attached UE."""
        url = f"{self.base_url}/ues/{ue_id}/bearers"
        payload = {"bearer_id": int(bearer_id)}
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def start_data_transfer(self, ue_id, bearer_id, speed):
        """Legacy helper kept for compatibility with older suites."""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        payload = {"protocol": "udp", "Mbps": int(speed), "kbps": 0, "bps": 0}
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def get_data_transfer(self, ue_id, bearer_id):
        """Legacy helper kept for compatibility with older suites."""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        response = requests.get(url)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def stop_data_transfer(self, ue_id, bearer_id=None):
        """POST /ues/{ue_id}/transfer/stop or for a specific bearer."""
        if bearer_id:
            url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/transfer/stop"
        else:
            url = f"{self.base_url}/ues/{ue_id}/transfer/stop"
        response = requests.post(url)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def start_traffic(self, ue_id, bearer_id, mbps=0, kbps=0):
        """POST /ues/{ue_id}/bearers/{bearer_id}/traffic."""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        payload = {"protocol": "udp", "Mbps": int(mbps), "kbps": int(kbps), "bps": 0}
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def get_traffic_stats(self, ue_id, bearer_id):
        """GET /ues/{ue_id}/bearers/{bearer_id}/traffic."""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        response = requests.get(url)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def stop_traffic(self, ue_id, bearer_id):
        """DELETE /ues/{ue_id}/bearers/{bearer_id}/traffic."""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        response = requests.delete(url)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def detach_ue(self, ue_id):
        """DELETE /ues/{ue_id}."""
        url = f"{self.base_url}/ues/{ue_id}"
        response = requests.delete(url)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def remove_bearer(self, ue_id, bearer_id):
        """DELETE /ues/{ue_id}/bearers/{bearer_id}."""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}"
        response = requests.delete(url)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def start_traffic_mb(self, ue_id, bearer_id, mbps_value, protocol="udp"):
        """POST /ues/{ue_id}/bearers/{bearer_id}/traffic."""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        payload = {"protocol": str(protocol), "Mbps": int(mbps_value)}
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def stop_all_traffic(self, ue_id):
        """DELETE /ues/{ue_id}/traffic."""
        url = f"{self.base_url}/ues/{ue_id}/traffic"
        response = requests.delete(url)
        return {"status": int(response.status_code), "body": self._parse_body(response)}

    def get_ues_stats(self, ue_id):
        """GET /ues/stats."""
        url = f"{self.base_url}/ues/stats"
        payload = {"ue_id": int(ue_id)}
        response = requests.get(url, params=payload)
        return {"status": int(response.status_code), "body": self._parse_body(response)}
