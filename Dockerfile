# Use the latest Python image from DockerHub
FROM python:3.10-slim

# Create working directory inside container
WORKDIR /app

# Copy requirements.txt and install dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy all source code into container
COPY . .

# Expose the Flask app port
EXPOSE 8080

# Start the Flask app
CMD ["python", "app.py"]