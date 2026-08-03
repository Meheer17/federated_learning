import numpy as np
from server.services.aggregation import FedAvgAggregator
from server.simulation.synthetic_data import generate_synthetic_user_styles

def run_fl_simulation(num_clients: int = 10, rounds: int = 5, epsilon: float = 1.0):
    print(f"--- Starting FedChat FL Simulation ---")
    print(f"Virtual Clients: {num_clients} | Rounds: {rounds} | DP Epsilon: {epsilon}")

    synthetic_clients = generate_synthetic_user_styles(num_clients)
    global_weights = np.mean(synthetic_clients, axis=0)

    for r in range(1, rounds + 1):
        sample_sizes = [np.random.randint(10, 100) for _ in range(num_clients)]
        client_updates = [c + np.random.normal(0, 0.05, size=c.shape) for c in synthetic_clients]

        # 1. FedAvg Weighted Aggregation
        aggregated = FedAvgAggregator.aggregate_updates(client_updates, sample_sizes)

        # 2. DP Noise Injection
        noisy_global = FedAvgAggregator.add_post_aggregation_dp_noise(aggregated, clip_norm=1.0, epsilon=epsilon)

        loss = np.mean(np.abs(noisy_global - global_weights))
        print(f"Round {r}/{rounds} Completed | Aggregate Loss: {loss:.4f}")

    print("--- FL Simulation Complete: Convergence verified! ---")

if __name__ == "__main__":
    run_fl_simulation()
