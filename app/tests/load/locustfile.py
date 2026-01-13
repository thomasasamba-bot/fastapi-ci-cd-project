from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 5)

    @task(3)
    def index(self):
        self.client.get("/")

    @task(1)
    def health(self):
        self.client.get("/health")

    @task(1)
    def docs(self):
        self.client.get("/docs")

    @task(2)
    def metrics(self):
        self.client.get("/metrics")
