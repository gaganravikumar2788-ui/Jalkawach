from fastapi import FastAPI

app = FastAPI(
    title="Public APIs Scripts Service",
    description="Internal microservice for API catalog validation & health",
    version="1.0.0",
)

@app.get("/")
@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "scripts",
        "description": "Internal public-apis scripts and validator service",
    }
