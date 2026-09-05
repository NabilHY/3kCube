import requests


def main():
    server_ip = "192.168.56.110"
    base_url = f"http://{server_ip}"

    hosts = [
        "app1.com",  # routes to app-one via ingress rule
        "app2.com",  # routes to app-two via ingress rule
        "app3.com",
        None,  # no Host header — hits the default backend (app-three)
    ]

    for host in hosts:
        headers = {"Host": host} if host else {}
        label = host or "default-backend"

        print(f"--- Testing: {label} ---")
        try:
            if host:
                response = requests.get(base_url, headers=headers)
            else:
                response = requests.get(base_url)
            print("Status Code:", response.status_code)
            # print("Response Body:")
            # print(response.text)
        except requests.exceptions.ConnectionError:
            print("Error: Could not connect to the IP address. Is the server running?")
        print()


if __name__ == "__main__":
    main()
