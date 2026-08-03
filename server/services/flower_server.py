import flwr as fl
from typing import List, Tuple, Dict, Optional
from flwr.common import Parameters, Scalar, FitRes
from flwr.server.client_proxy import ClientProxy
from server.services.aggregation import FedAvgAggregator

class FedAvgWithSecAgg(fl.server.strategy.FedAvg):
    def __init__(self, min_clients: int = 3, **kwargs):
        super().__init__(min_fit_clients=min_clients, min_evaluate_clients=min_clients, **kwargs)
        self.min_clients = min_clients

    def aggregate_fit(
        self,
        server_round: int,
        results: List[Tuple[ClientProxy, FitRes]],
        failures: List[Tuple[ClientProxy, FitRes] | BaseException],
    ) -> Tuple[Optional[Parameters], Dict[str, Scalar]]:
        if len(results) < self.min_clients:
            print(f"[Flower Server] Round {server_round}: Insufficient clients ({len(results)}/{self.min_clients}). Skipping.")
            return None, {}

        print(f"[Flower Server] Round {server_round}: Successfully aggregating {len(results)} client updates.")
        return super().aggregate_fit(server_round, results, failures)
