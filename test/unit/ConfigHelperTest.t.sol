//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ConfigHelper} from "../../script/ConfigHelper.s.sol";
import {MockV3Aggregator} from "../mocks/MockAggregatorV3Interface.sol";

contract ConfigHelperUnitTest is StdCheats, Test {
    ConfigHelper configHelper;
    ConfigHelper.NetworkConfig networkConfig;

    bytes32 constant MOCK_GAS_LANE =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 constant CALLBACK_GAS_LIMIT = 500000;
    uint256 constant DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    modifier anvilOnly() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    modifier sepoliaOnly() {
        if (block.chainid != 11155111) {
            return;
        }
        _;
    }

    function setUp() public {
        configHelper = new ConfigHelper();
    }

    function testGetAnvilConfig() public anvilOnly {
        networkConfig = configHelper.getOrCreateAnvilEthConfig();

        assertEq(networkConfig.subscriptionId, 0);
        assertEq(networkConfig.gasLane, MOCK_GAS_LANE);
        assertEq(networkConfig.callbackGasLimit, CALLBACK_GAS_LIMIT);
        assert(networkConfig.aggregatorV3Interface != address(0));
        assert(networkConfig.vrfCoordinatorV2 != address(0));
        assert(networkConfig.link != address(0));
        assertEq(networkConfig.deployerKey, DEFAULT_ANVIL_PRIVATE_KEY);
    }

    function testGetActiveNetworkConfig() public {
        if (block.chainid == 31337) {
            networkConfig = configHelper.getOrCreateAnvilEthConfig();
            assertEq(networkConfig.deployerKey, DEFAULT_ANVIL_PRIVATE_KEY);
        } else if (block.chainid == 11155111) {
            // TODO add test for sepolia
        }
    }
}
