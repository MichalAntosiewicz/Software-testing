import requests

class ApiLibraryPython:
    ROBOT_LIBRARY_SCOPE = 'SUITE' #one instance for .robot file (Test Suite)

    def __init__ (self, base_url):
        self.base_url = base_url

    def attach_ue(self, ue_id):
        """Attaches UE to web"""
        # Connect with endpoint
        url = f"{self.base_url}/ues"

        # API payload
        payload = {
            "ue_id": ue_id
        }
        
        # POST /ues
        response = requests.post(url, json=payload)

        # Return response json
        return {
            "status": int(response.status_code),
            "body": response.json()
        }
        
    def reset_app_state(self):
        """Reset app state using endpoint: POST /reset"""
        url = f"{self.base_url}/reset"
        # POST
        response = requests.post(url)

        # Return status code
        return response.status_code
    
    def get_ue(self, ue_id):
        """Get connected UE additional info"""
        url = f"{self.base_url}/ues/{ue_id}"
        # GET
        response = requests.get(url)

        # Return response json
        return{
            "status": int(response.status_code),
            "body": response.json()
        }
    
    def add_bearer(self, ue_id, bearer_id):
        """Add a bearer to an attached UE"""
        url = f"{self.base_url}/ues/{ue_id}/bearers"
        
        # Zgodnie z Twoim screenem, request body to: {"bearer_id": 0}
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
        """POST /ues/{ue_id}/bearers/{bearer_id}/transfer/start"""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/transfer/start"
        payload = {"speed": int(speed)}
        response = requests.post(url, json=payload)
        return {"status": int(response.status_code), "body": response.json()}
    
    def get_data_transfer(self, ue_id, bearer_id):
        """GET /ues/{ue_id}/bearers/{bearer_id}/transfer"""
        url = f"{self.base_url}/ues/{ue_id}/bearers/{bearer_id}/transfer"
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
