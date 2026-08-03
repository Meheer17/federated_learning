import numpy as np

class FedAvgAggregator:
    @staticmethod
    def aggregate_updates(weights_list: list[np.ndarray], sample_sizes: list[int]) -> np.ndarray:
        """Weighted Federated Averaging (FedAvg) math"""
        if not weights_list:
            raise ValueError("No weights provided for aggregation")

        total_samples = sum(sample_sizes)
        aggregated = np.zeros_like(weights_list[0], dtype=np.float64)

        for w, size in zip(weights_list, sample_sizes):
            weight_factor = size / total_samples
            aggregated += w * weight_factor

        return aggregated.astype(weights_list[0].dtype)

    @staticmethod
    def apply_secagg_unmasking(masked_updates: list[np.ndarray]) -> np.ndarray:
        """Sum of pairwise masked updates — individual masks cancel out"""
        return np.sum(masked_updates, axis=0)

    @staticmethod
    def add_post_aggregation_dp_noise(aggregated_weights: np.ndarray, clip_norm: float, epsilon: float) -> np.ndarray:
        """Gaussian mechanism noise injection"""
        sigma = clip_norm * np.sqrt(2 * np.log(1.25 / 1e-5)) / epsilon
        noise = np.random.normal(0, sigma, size=aggregated_weights.shape)
        return aggregated_weights + noise
