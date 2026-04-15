import requests

class ApiLibraryPython:
    ROBOT_LIBRARY_SCOPE = 'SUITE'

    def __init__(self, base_url):
        self.base_url = base_url

    def reset_all(self):
        """Wykonuje POST /reset w celu przywrócenia stanu początkowego."""
        url = f"{self.base_url}/reset"
        response = requests.post(url)
        return {"status": int(response.status_code), "body": response.json()}

    def attach_ue(self, ue_id):
        """Wykonuje POST /ues z przekazanym identyfikatorem."""
        url = f"{self.base_url}/ues"
        payload = {"ue_id": int(ue_id)}
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": response.json()}

    def detach_ue(self, ue_id):
        """Wykonuje DELETE /ues/{ue_id}."""
        url = f"{self.base_url}/ues/{ue_id}"
        response = requests.delete(url)
        return {"status": int(response.status_code), "body": response.json()}

    def get_ue(self, ue_id):
        """Pobiera szczegóły UE przez GET /ues/{ue_id}."""
        url = f"{self.base_url}/ues/{ue_id}"
        response = requests.get(url)
        return {"status": int(response.status_code), "body": response.json()}

    def add_bearer(self, ue_id, bearer_id):
        """Dodaje bearer przez POST /ues/{ue_id}/bearers."""
        url = f"{self.base_url}/ues/{ue_id}/bearers"
        payload = {"bearer_id": int(bearer_id)}
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": response.json()}

    def start_traffic(self, ue_id, bearer_id, mbps=0, kbps=0):
        """Uruchamia ruch przez POST /ues/{ue_id}/bearers/{bearer_id}/traffic."""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        payload = {
            "protocol": "udp",
            "Mbps": int(mbps),
            "kbps": int(kbps),
            "bps": 0
        }
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": response.json()}

    def stop_traffic(self, ue_id, bearer_id):
        """Zatrzymuje ruch przez DELETE /ues/{ue_id}/bearers/{bearer_id}/traffic."""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        response = requests.delete(url)
        return {"status": int(response.status_code), "body": response.json()}

    def get_traffic_stats(self, ue_id, bearer_id):
        """Pobiera statystyki przez GET /ues/{ue_id}/bearers/{bearer_id}/traffic."""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        response = requests.get(url)
        return {"status": int(response.status_code), "body": response.json()}