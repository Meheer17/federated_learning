import numpy as np

def generate_synthetic_user_styles(num_clients: int = 10):
    """Generate non-IID synthetic user style data weights for Flower simulation"""
    client_data = []
    for i in range(num_clients):
        # Simulate distinct user tone/style parameters
        formality = np.random.uniform(0.1, 0.9)
        avg_len = np.random.uniform(5.0, 45.0)
        style_vector = np.array([formality, avg_len / 50.0, np.random.rand()], dtype=np.float32)
        client_data.append(style_vector)
    return client_data
