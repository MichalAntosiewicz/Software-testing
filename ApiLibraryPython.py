import requests

class ApiLibraryPython:
    ROBOT_LIBRARY_SCOPE = 'SUITE'

    def __init__ (self, base_url):
        self.base_url = base_url

    def attach_ue(self, ue_id):
        """Attaches UE to web"""
        url = f"{self.base_url}/ues"

        payload = {
            "ue_id": ue_id
        }
        
        response = requests.post(url, json=payload)

        return {
            "status": int(response.status_code),
            "body": response.json()
        }
        
    def reset_app_state(self):
        """Reset app state using endpoint: POST /reset"""
        url = f"{self.base_url}/reset"
        response = requests.post(url)

        return response.status_code
    
    def get_ue(self, ue_id):
        """Get connected UE additional info"""
        url = f"{self.base_url}/ues/{ue_id}"
        response = requests.get(url)

        return{
            "status": int(response.status_code),
            "body": response.json()
        }
    
    def add_bearer(self, ue_id, bearer_id):
        """Add a bearer to an attached UE"""
        url = f"{self.base_url}/ues/{ue_id}/bearers"
        
        payload = {
            "bearer_id": int(bearer_id)
        }
        
        response = requests.post(url, json=payload)

        try:
            body = response.json()
        except ValueError:
            body = response.text

        return {
            "status": int(response.status_code),
            "body": body
        }
    
    def start_data_transfer(self, ue_id, bearer_id, speed):
        """ZMIANA: Ścieżka kończy się na /traffic zamiast /transfer/start"""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        payload = {"protocol": "udp", "Mbps": int(speed), "kbps": 0, "bps": 0}
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": response.json()}
    
    def get_data_transfer(self, ue_id, bearer_id):
        """ZMIANA: Ścieżka to /traffic zamiast /transfer"""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        response = requests.get(url)
        return {"status": int(response.status_code), "body": response.json()}
    
    def stop_data_transfer(self, ue_id, bearer_id=None):
        """POST /ues/{ue_id}/transfer/stop lub dla konkretnego bearera"""
        if bearer_id:
            url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/transfer/stop"
        else:
            url = f"{self.base_url}/ues/{ue_id}/transfer/stop"
        response = requests.post(url)
        return {"status": int(response.status_code), "body": response.json() if response.text else {}}


    def start_traffic(self, ue_id, bearer_id, mbps=0, kbps=0):
        """POST /ues/{ue_id}/bearers/{bearer_id}/traffic"""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        payload = {
            "protocol": "udp",
            "Mbps": int(mbps),
            "kbps": int(kbps),
            "bps": 0
        }
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": response.json()}

    def get_traffic_stats(self, ue_id, bearer_id):
        """GET /ues/{ue_id}/bearers/{bearer_id}/traffic"""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        response = requests.get(url)
        return {"status": int(response.status_code), "body": response.json()}

    def stop_traffic(self, ue_id, bearer_id):
        """DELETE /ues/{ue_id}/bearers/{bearer_id}/traffic"""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
        response = requests.delete(url)
        return {"status": int(response.status_code), "body": response.json()}

    def detach_ue(self, ue_id):
        """DELETE /ues/{ue_id}"""
        url = f"{self.base_url}/ues/{ue_id}"
        response = requests.delete(url)
        return {"status": int(response.status_code), "body": response.json()}
    

    def remove_bearer(self, ue_id, bearer_id):
        """Obsługuje: DELETE /ues/{ue_id}/bearers/{bearer_id}"""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}"
        response = requests.delete(url)
        return {"status": int(response.status_code), "body": response.json()}

    def start_traffic_mb(self, ue_id, bearer_id, mbps_value, protocol="udp"):
        """Obsługuje: POST /ues/{ue_id}/bearers/{bearer_id}/traffic"""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/traffic"
   
        payload = {
            "protocol": str(protocol),
            "Mbps": int(mbps_value)
        }
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": response.json()}