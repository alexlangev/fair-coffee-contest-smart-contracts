//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {FreeCoffeeToken} from "./FreeCoffeeToken.sol";
import {FreeDonutToken} from "./FreeDonutToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Contest {
    ///////////////////////
    // Type Declarations //
    ///////////////////////
    enum Status {
        Open,
        Pending,
        Closed
    }

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    ///////////////////////
    // Errors /////////////
    ///////////////////////
    error Contest__EthUsdPriceMustBeGreaterThanZero();
    error Contest__EthCoffeePriceMustBeGreaterThanZero();
    error Contest__NotEnoughEthToBuyCoffee();
    error Contest__InvalidNumberOfCoffees();
    error Contest__ContestIsNotOpen();

    ///////////////////////
    // State Variables ////
    ///////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

    uint256 private immutable i_UsdCoffeePrice;
    uint256 private immutable i_TotalNumberOfFreeCoffeePrizes;
    uint256 private immutable i_TotalNumberOfFreeDonutPrizes;
    FreeCoffeeToken private immutable i_fct;
    FreeDonutToken private immutable i_fdt;
    AggregatorV3Interface private immutable i_ethUsdPriceFeed;

    Status private s_constestStatus;
    address[] private s_dailyLotteryParticipants;
    mapping(address => uint256) private s_contestParticipationCount;
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // VRF shit
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    ///////////////////////
    // Events /////////////
    ///////////////////////
    event ParticipationAdded(uint256 participationsAdded);
    event RequestSent(uint256 requestId, uint32 numWords);

    ///////////////////////
    // Functions //////////
    ///////////////////////
    constructor(
        uint256 _usdCoffeePrice,
        uint256 _totalNumberOfFreeCoffeePrizes,
        uint256 _totalNumberOfFreeDonutPrizes,
        address _freeCoffeeTokenAddress,
        address _freeCoffeeDonutAddress,
        address _ethUsdPriceFeedAddress,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) {
        i_UsdCoffeePrice = _usdCoffeePrice;
        i_TotalNumberOfFreeCoffeePrizes = _totalNumberOfFreeCoffeePrizes;
        i_TotalNumberOfFreeDonutPrizes = _totalNumberOfFreeDonutPrizes;
        i_fct = FreeCoffeeToken(_freeCoffeeTokenAddress);
        i_fdt = FreeDonutToken(_freeCoffeeDonutAddress);
        i_ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeedAddress);
        s_constestStatus = Status.Open;

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    /////////////////////////////
    // External Functions ///////
    /////////////////////////////
    function buyCofees(uint256 _numberOfCoffees) external payable {
        if (s_constestStatus != Status.Open) {
            revert Contest__ContestIsNotOpen();
        }
        if (_numberOfCoffees < 1 || _numberOfCoffees > 5) {
            revert Contest__InvalidNumberOfCoffees();
        }
        uint256 _ethCoffeePrice = getEthCoffeePrice();
        if (msg.value < _ethCoffeePrice * _numberOfCoffees) {
            revert Contest__NotEnoughEthToBuyCoffee();
        }
        emit ParticipationAdded(_numberOfCoffees);
        s_contestParticipationCount[msg.sender] += _numberOfCoffees;
    }

    // function redeemParticipation() external returns (bool, bool) {
    //     // Add VRF logic here!
    //     return (_wonFreeCoffee, _wonFreeDonut);
    // }

    // Only owner?
    // function requestRandomWords() external returns (uint256 requestId) {
    //     requestId =
    //         COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    //     s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
    //     requestIds.push(requestId);
    //     lastRequestId = requestId;
    //     emit RequestSent(requestId, numWords);
    //     return requestId;
    // }
    /////////////////////////////
    // View And Pure Functions //
    /////////////////////////////

    function getTotalNumberOfFreeCoffeePrizes() public view returns (uint256) {
        return i_TotalNumberOfFreeCoffeePrizes;
    }

    function getTotalNumberOfFreeDonutPrizes() public view returns (uint256) {
        return i_TotalNumberOfFreeDonutPrizes;
    }

    function getDailyLotteryParticipants() public view returns (address[] memory) {
        return s_dailyLotteryParticipants;
    }

    function getUsdCoffeePrice() public view returns (uint256) {
        return i_UsdCoffeePrice;
    }

    function getLatestEthUsdPrice() public view returns (uint256) {
        (, int256 _ethUsdPrice,,,) = i_ethUsdPriceFeed.latestRoundData();
        if (_ethUsdPrice <= 0) {
            revert Contest__EthUsdPriceMustBeGreaterThanZero();
        }
        return uint256(_ethUsdPrice);
    }

    function getEthCoffeePrice() public view returns (uint256) {
        uint256 _ethUsdPrice = getLatestEthUsdPrice(); // in 1e8 format.
        uint256 _ethCoffeePrice = (i_UsdCoffeePrice * 1e16 * ADDITIONAL_FEED_PRECISION) / _ethUsdPrice;
        if (_ethUsdPrice <= 0) {
            revert Contest__EthCoffeePriceMustBeGreaterThanZero();
        }
        return _ethCoffeePrice;
    }

    function getParticipationCount() public view returns (uint256) {
        return s_contestParticipationCount[msg.sender];
    }

    function getContestStatus() public view returns (Status) {
        return s_constestStatus;
    }
}

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables  1- constants 2- immutables 3- state
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
