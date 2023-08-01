// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {ConfigHelper} from "./ConfigHelper.s.sol";
import {Contest} from "../src/Contest.sol";
import {FreeCoffeeToken} from "../src/FreeCoffeeToken.sol";
import {FreeDonutToken} from "../src/FreeDonutToken.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./VRFHelper.s.sol";

contract DeployContest is Script {
    function run() external returns (Contest, ConfigHelper) {
        ConfigHelper configHelper = new ConfigHelper();
        AddConsumer addConsumer = new AddConsumer();
        FreeCoffeeToken freeCoffeeToken = new FreeCoffeeToken();
        FreeDonutToken freeDonutToken = new FreeDonutToken();
        (
            uint64 subscriptionId,
            bytes32 gasLane,
            uint32 callbackGasLimit,
            address aggregatorV3Interface,
            address vrfCoordinatorV2,
            address link,
            uint256 deployerKey
        ) = configHelper.s_activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinatorV2, deployerKey);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinatorV2, subscriptionId, link, deployerKey);
        }

        vm.startBroadcast(deployerKey);
        Contest contest = new Contest(
            150,
            50000,
            50000,
            address(freeCoffeeToken),
            address(freeDonutToken),
            aggregatorV3Interface, // pricefeed aggv3interface
            subscriptionId,
            gasLane, // gaslane
            callbackGasLimit,
            vrfCoordinatorV2
            );
        vm.stopBroadcast();

        addConsumer.addConsumer(address(contest), vrfCoordinatorV2, subscriptionId, deployerKey);

        return (contest, configHelper);
    }
}
