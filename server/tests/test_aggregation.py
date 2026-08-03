import numpy as np
from server.services.aggregation import FedAvgAggregator

def test_fedavg_weighted_math():
    w1 = np.array([1.0, 2.0, 3.0])
    w2 = np.array([3.0, 6.0, 9.0])
    sizes = [100, 100]

    aggregated = FedAvgAggregator.aggregate_updates([w1, w2], sizes)
    np.testing.assert_array_almost_equal(aggregated, np.array([2.0, 4.0, 6.0]))

def test_secagg_mask_cancellation():
    base = np.array([10.0, 20.0])
    mask1 = np.array([5.0, -5.0])
    mask2 = np.array([-5.0, 5.0])

    client1_masked = base + mask1
    client2_masked = base + mask2

    unmasked_sum = FedAvgAggregator.apply_secagg_unmasking([client1_masked, client2_masked])
    np.testing.assert_array_almost_equal(unmasked_sum, np.array([20.0, 40.0]))
