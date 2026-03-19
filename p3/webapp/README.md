# IoT Webapp - Simple Flask Application

This is a simple Flask web application designed to work with the p3 Kubernetes GitOps setup.

## Quick Start (Local Testing)

### Using Docker Compose
```bash
docker-compose up
# Access at http://localhost:8888
```

### Using Python directly
```bash
pip install -r requirements.txt
python app.py
# Access at http://localhost:8888
```

## Endpoints

- `GET /` - Returns status, message, and version
- `GET /health` - Returns health check

## Example Responses

```bash
curl http://localhost:8888/
# {"status":"ok","message":"Hello from IoT App - Python Flask","version":"v1"}

curl http://localhost:8888/health
# {"status":"healthy"}
```

## Environment Variables

- `APP_VERSION` - Default: `v1`
- `APP_MESSAGE` - Default: `Hello from IoT App - Python Flask`

## Building and Pushing to Docker Hub

### 1. Build the image
```bash
docker build -t your-username/iot-app:v1 .
```

### 2. Login to Docker Hub
```bash
docker login
```

### 3. Push to Docker Hub
```bash
docker push your-username/iot-app:v1
```

### 4. Tag as latest (optional)
```bash
docker tag your-username/iot-app:v1 your-username/iot-app:latest
docker push your-username/iot-app:latest
```

## Deploying with p3

After pushing to Docker Hub:

1. Update the deployment.yaml in the p3/confs folder to use your image:
   ```yaml
   spec:
     containers:
     - name: app
       image: your-username/iot-app:v1
   ```

2. Push these manifests to GitHub

3. Update `p3/confs/argocd-app.yaml` with your GitHub repo URL

4. Re-run vagractup
