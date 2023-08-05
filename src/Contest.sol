//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {FreeCoffeeToken} from "./FreeCoffeeToken.sol";
import {FreeDonutToken} from "./FreeDonutToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Contest is VRFConsumerBaseV2, AutomationCompatibleInterface {

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
        address user;
    }

    ///////////////////////
    // Errors /////////////
    ///////////////////////
    error Contest__EthUsdPriceMustBeGreaterThanZero();
    error Contest__EthCoffeePriceMustBeGreaterThanZero();
    error Contest__NotEnoughEthToBuyCoffee();
    error Contest__InvalidNumberOfCoffees();
    error Contest__ContestIsNotOpen();
    error Contest__NotEnoughParticipations();
    error Contest__RequestIdDoesntExist();
    error Contest__TransferFailed();

    ///////////////////////
    // State Variables ////
    ///////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint256 private immutable i_UsdCoffeePrice;
    uint256 private immutable i_TotalNumberOfFreeCoffeePrizes;
    uint256 private immutable i_TotalNumberOfFreeDonutPrizes;
    uint256 public immutable i_interval;
    FreeCoffeeToken private immutable i_fct;
    FreeDonutToken private immutable i_fdt;
    AggregatorV3Interface private immutable i_ethUsdPriceFeed;

    Status private s_constestStatus;
    address[] private s_dailyLotteryParticipants;
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    mapping(address => uint256[]) public s_userUnclaimedRandomWords;
    uint256 private s_lastTimeStamp;
    uint256 s_lastRandomWord; // TODO BETTER OPTION?

    // VRF shit
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;

    ///////////////////////
    // Events /////////////
    ///////////////////////
    event ParticipationAdded(address indexed buyer, uint256 participationsAdded, uint256 requestId);
    event RequestSent(uint256 indexed requestId, uint32 numWords, address indexed user);
    event ParticipationRedeemed();
    event DailyLotteryJoined(address indexed user);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, address user);
    event FreeCoffeeInstantWin(address indexed user);
    event FreeDonutInstantWin(address indexed user);
    event DailyLotteryDraw(address indexed winner);

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
        address vrfCoordinatorV2,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
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
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    /////////////////////////////
    // External Functions ///////
    /////////////////////////////

    // you get a random number request id along with your coffee (your participation receipt)
    function buyCofees(uint256 _numberOfCoffees) external payable returns (uint256) {
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
        uint256 requestId = requestRandomWords(uint32(_numberOfCoffees));
        emit ParticipationAdded(msg.sender, _numberOfCoffees, requestId);
        return requestId;
    }

    // Ask for random number and get a requestId as receipt
    function redeemParticipation() external {
        if (s_constestStatus != Status.Open) {
            revert Contest__ContestIsNotOpen();
        }
        if(s_userUnclaimedRandomWords[msg.sender].length < 1){
            revert Contest__NotEnoughParticipations();
        }

        uint256 randomWordIndex = s_userUnclaimedRandomWords[msg.sender].length - 1;
        uint256 randomWord = s_userUnclaimedRandomWords[msg.sender][randomWordIndex];
        emit ParticipationRedeemed();
        s_userUnclaimedRandomWords[msg.sender].pop();

        if(randomWord % 100 < 10) {
            emit FreeCoffeeInstantWin(msg.sender);
            i_fct.mint(msg.sender, 1); // owner?
        } else if(randomWord % 100 < 20){
            emit FreeDonutInstantWin(msg.sender);
            i_fdt.mint(msg.sender, 1); // owner?
        } else {
            emit DailyLotteryJoined(msg.sender);
            s_dailyLotteryParticipants.push(msg.sender);
        }
    }

    function requestRandomWords(uint32 _numberOfWords) public returns (uint256) {
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            _numberOfWords
        );

        s_requests[requestId] = RequestStatus({
            fulfilled: false,
            exists: true,
            randomWords: new uint256[](0),
            user: msg.sender
        });

        emit RequestSent(requestId, _numberOfWords, msg.sender);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        if(!s_requests[_requestId].exists){
            revert Contest__RequestIdDoesntExist();
        }
        s_lastRandomWord = _randomWords[0];
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        for (uint256 i = 0; i < _randomWords.length; i += 1){
            s_userUnclaimedRandomWords[s_requests[_requestId].user].push(_randomWords[i]);
        }
        emit RequestFulfilled(_requestId, _randomWords, msg.sender);
    }
    
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.timestamp - s_lastTimeStamp) > i_interval;
    }

// Daily lottery draw!
    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - s_lastTimeStamp) > i_interval) {
            s_lastTimeStamp = block.timestamp;
            uint256 indexOfWinner = s_lastRandomWord % s_dailyLotteryParticipants.length;
            address winner = s_dailyLotteryParticipants[indexOfWinner];
            (bool success,) = winner.call{value: address(this).balance}(""); // TODO change this
            if (!success) {
                revert Contest__TransferFailed();
            }
            emit DailyLotteryDraw(winner);
            s_dailyLotteryParticipants = new address[](0);
        }
    }


        // uint256 indexOfWinner = randomWords[0] % s_players.length;
        // address payable recentWinner = s_players[indexOfWinner];
        // s_recentWinner = recentWinner;
        // s_players = new address payable[](0);
        // s_raffleState = RaffleState.OPEN;
        // s_lastTimeStamp = block.timestamp;
        // (bool success,) = recentWinner.call{value: address(this).balance}("");
        // // require(success, "Transfer failed");
        // if (!success) {
        //     revert Raffle__TransferFailed();
        // }
        // emit WinnerPicked(recentWinner);


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

    function getContestStatus() public view returns (Status) {
        return s_constestStatus;
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool, uint256[] memory, address) {
        if(!s_requests[_requestId].exists){
            revert Contest__RequestIdDoesntExist();
        }
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords, request.user);
    }

    function getUserUnclaimedRandomWords() external view returns(uint256[] memory){
        return s_userUnclaimedRandomWords[msg.sender];
    }
}