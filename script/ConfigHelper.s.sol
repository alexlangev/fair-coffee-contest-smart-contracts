// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {LinkToken} from "../test/mocks/MockLinkToken.sol";
import {VRFCoordinatorV2Mock} from "../test/mocks/VRFCoordinatorV2Mock.sol";
import {MockV3Aggregator} from "../test/mocks/MockAggregatorV3Interface.sol";

contract ConfigHelper is Script {
    struct NetworkConfig {
        uint64 subscriptionId;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        address aggregatorV3Interface;
        address vrfCoordinatorV2;
        address link;
        uint256 deployerKey;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 1852e8;
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public s_activeNetworkConfig;

    event HelperConfig__CreatedMockVRFCoordinator(address vrfCoordinator);

    constructor() {
        if (block.chainid == 11155111) {
            // sepolia stuff
        } else {
            s_activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        uint96 _baseFee = 0.25 ether;
        uint96 _gasPriceLink = 1e9;

        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        VRFCoordinatorV2Mock _vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            _baseFee,
            _gasPriceLink
        );
        LinkToken _link = new LinkToken();
        vm.stopBroadcast();

        emit HelperConfig__CreatedMockVRFCoordinator(address(_vrfCoordinatorV2Mock));

        NetworkConfig memory _anvilNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 500000,
            aggregatorV3Interface: address(mockPriceFeed),
            vrfCoordinatorV2: address(_vrfCoordinatorV2Mock),
            link: address(_link),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });

        return _anvilNetworkConfig;
    }
}
