import torch

# Check if CUDA (GPU) is available
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# Try loading the model
try:
    model_path = '../ckpt_weight/aic24.pkl'  # Adjust this path if needed
    reid = torch.load(model_path, map_location=device).to(device).eval()
    print("Model loaded successfully!")
except FileNotFoundError:
    print(f"Error: Model file not found at {model_path}")
except Exception as e:
    print(f"Error loading model: {e}")
