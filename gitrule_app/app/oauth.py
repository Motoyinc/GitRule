import requests
from keycloak import KeycloakOpenID
import json

class Oauto:
    def __init__(self, config:'dict'):
        self.config:'dict' = config

        keycloak_openid = KeycloakOpenID(server_url=self.config['server_url'],
                                          client_id=self.config['client_id'],
                                          realm_name=self.config['realm_name'],
                                          client_secret_key=self.config['client_secret_key'])

        # 获取Token
        token = keycloak_openid.token("username", "password")

        # 刷新Token
        token = keycloak_openid.refresh_token(token['refresh_token'])

        # 使用Token访问受保护的资源
        headers = {
            'Authorization': 'Bearer ' + token['access_token']
        }
        response = requests.get("http://localhost:5000/protected/resource", headers=headers)



if __name__ == '__main__':
    data = {
        'server_url': "http://localhost:8080/auth/",
        'client_id': "example-client",
        'realm_name': "example-realm",
        'client_secret_key': "your-client-secret",
        'username': "you_username",
        'password': "you_password",
    }
    filename = 'config.json'
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)