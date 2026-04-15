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
