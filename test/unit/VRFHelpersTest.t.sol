//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {CreateSubscription, AddConsumer, FundSubscription} from "../../script/VRFHelper.s.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../mocks/MockLinkToken.sol";

contract VRFHelperUnitTest is StdCheats, Test {
    uint96 constant BASE_FEE = 0.25 ether;
    uint96 constant GAS_PRICE_LINK = 1e9;
    uint256 constant DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address constant DEFAULT_ANVIL_ADDRESS =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant MOCK_CONSUMER_CONTRACT = address(1);

    // test that the subscription id is valid and the owner is the deployer(default anvil user)
    function testCreateSubscription() public {
        VRFCoordinatorV2Mock _vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            BASE_FEE,
            GAS_PRICE_LINK
        );
        CreateSubscription createSubscription = new CreateSubscription();

        uint64 subscriptionId = createSubscription.createSubscription(
            address(_vrfCoordinatorV2Mock),
            DEFAULT_ANVIL_PRIVATE_KEY
        );

        (, , address owner, ) = _vrfCoordinatorV2Mock.getSubscription(
            subscriptionId
        );

        assert(subscriptionId != uint64(0));
        assertEq(owner, DEFAULT_ANVIL_ADDRESS);
    }

    function testCreateSubscriptionUsingConfig() public {
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 subId = createSubscription.createSubscriptionUsingConfig();
        assert(subId != uint64(0));
    }

    function testCreateSubscriptionUsingRun() public {
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 subId = createSubscription.run();
        assert(subId != uint64(0));
    }

    function testAddConsumer() public {
        VRFCoordinatorV2Mock _vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            BASE_FEE,
            GAS_PRICE_LINK
        );
        CreateSubscription createSubscription = new CreateSubscription();
        AddConsumer addConsumer = new AddConsumer();

        uint64 subscriptionId = createSubscription.createSubscription(
            address(_vrfCoordinatorV2Mock),
            DEFAULT_ANVIL_PRIVATE_KEY
        );

        addConsumer.addConsumer(
            MOCK_CONSUMER_CONTRACT,
            address(_vrfCoordinatorV2Mock),
            subscriptionId,
            DEFAULT_ANVIL_PRIVATE_KEY
        );

        (, , , address[] memory consumers) = _vrfCoordinatorV2Mock
            .getSubscription(subscriptionId);

        assertEq(consumers.length, 1);
    }

    function testFundSubscription() public {
        VRFCoordinatorV2Mock _vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            BASE_FEE,
            GAS_PRICE_LINK
        );
        CreateSubscription createSubscription = new CreateSubscription();
        AddConsumer addConsumer = new AddConsumer();
        FundSubscription fundSubscription = new FundSubscription();
        LinkToken linkToken = new LinkToken();

        uint64 subscriptionId = createSubscription.createSubscription(
            address(_vrfCoordinatorV2Mock),
            DEFAULT_ANVIL_PRIVATE_KEY
        );

        addConsumer.addConsumer(
            MOCK_CONSUMER_CONTRACT,
            address(_vrfCoordinatorV2Mock),
            subscriptionId,
            DEFAULT_ANVIL_PRIVATE_KEY
        );

        fundSubscription.fundSubscription(
            address(_vrfCoordinatorV2Mock),
            subscriptionId,
            address(linkToken),
            DEFAULT_ANVIL_PRIVATE_KEY
        );

        (uint96 balance, , , ) = _vrfCoordinatorV2Mock.getSubscription(
            subscriptionId
        );

        assertEq(balance, 3 ether);
    }
}
