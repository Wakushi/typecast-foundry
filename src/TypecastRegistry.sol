// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TypecastRegistry {
    struct Mission {
        address devAddress;
        uint256 devFid;
        address recruiterAddress;
        uint256 recruiterFid;
        uint256 amountDue;
        uint256 hiredAt;
        uint256 completedAt;
        string offerIpfsHash;
    }

    uint256 public constant FUND_WITHDRAWAL_DELAY = 7 days;
    AggregatorV3Interface private s_priceFeed;
    mapping(address recruiter => mapping(address devAddress => Mission))
        public s_missions;
    mapping(string offerIpfsHash => Mission mission)
        public s_missionByOfferIpfsHash;
    mapping(string offerIpfsHash => bool closed) public s_offerStatus;
    mapping(uint256 recruiterFid => mapping(uint256 devFid => Mission mission))
        public s_missionsByFid;

    error TypecastRegistry__InvalidAmount(uint256 amount);
    error TypecastRegistry__InvalidAddress();
    error TypecastRegistry__MissionNotFound();
    error TypecastRegistry__MissionNotPastDue();
    error TypecastRegistry__TransferFailed();
    error TypecastRegistry__MissionCancelPastDue();
    error TypecastRegistry__OfferClosed();

    event MissionCreated(
        address recruiter,
        uint256 indexed recruiterFid,
        address devAddress,
        uint256 indexed devFid,
        uint256 amount,
        uint256 hiredAt,
        string indexed offerIpfsHash
    );
    event MissionCancelled(
        address indexed recruiter,
        address indexed devAddress
    );
    event MissionCompleted(
        address indexed recruiter,
        address indexed devAddress
    );
    event OfferClosed(string indexed offerIpfsHash);

    constructor(address _priceFeed) {
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function hire(
        address _devAddress,
        uint256 _devFid,
        uint256 _recruiterFid,
        string memory offerIpfsHash
    ) external payable {
        if (_devAddress == address(0)) {
            revert TypecastRegistry__InvalidAddress();
        }
        if (msg.value <= 0) {
            revert TypecastRegistry__InvalidAmount(msg.value);
        }
        if (isOfferClosed(offerIpfsHash)) {
            revert TypecastRegistry__OfferClosed();
        }
        _createMission(
            msg.sender,
            _recruiterFid,
            _devAddress,
            _devFid,
            msg.value,
            offerIpfsHash
        );
    }

    function cancelMission(address _devAddress) external {
        Mission storage mission = s_missions[msg.sender][_devAddress];
        uint256 amountDue = mission.amountDue;
        if (mission.hiredAt <= 0) {
            revert TypecastRegistry__MissionNotFound();
        }
        if (_isWithinCancellationPeriod(mission.hiredAt)) {
            revert TypecastRegistry__MissionCancelPastDue();
        }
        delete s_missions[msg.sender][_devAddress];
        delete s_missionsByFid[mission.recruiterFid][mission.devFid];
        s_offerStatus[mission.offerIpfsHash] = true;
        (bool success, ) = msg.sender.call{value: amountDue}("");
        if (!success) {
            revert TypecastRegistry__TransferFailed();
        }
        emit MissionCancelled(msg.sender, _devAddress);
    }

    function completeMission(address _recruiter) external {
        Mission storage mission = s_missions[_recruiter][msg.sender];
        if (mission.hiredAt <= 0) {
            revert TypecastRegistry__MissionNotFound();
        }
        if (!_isPastDue(mission.hiredAt)) {
            revert TypecastRegistry__MissionNotPastDue();
        }
        mission.completedAt = block.timestamp;
        (bool success, ) = msg.sender.call{value: mission.amountDue}("");
        if (!success) {
            revert TypecastRegistry__TransferFailed();
        }
        emit MissionCompleted(_recruiter, msg.sender);
    }

    function _createMission(
        address _recruiter,
        uint256 _recruiterFid,
        address _devAddress,
        uint256 _devFid,
        uint256 _amount,
        string memory _offerIpfsHash
    ) private {
        Mission memory newMission = Mission(
            _devAddress,
            _devFid,
            _recruiter,
            _recruiterFid,
            _amount,
            block.timestamp,
            0,
            _offerIpfsHash
        );
        s_missions[_recruiter][_devAddress] = newMission;
        s_missionByOfferIpfsHash[_offerIpfsHash] = newMission;
        s_missionsByFid[_recruiterFid][_devFid] = newMission;
        _closeOffer(_offerIpfsHash);

        emit MissionCreated(
            _recruiter,
            _recruiterFid,
            _devAddress,
            _devFid,
            _amount,
            block.timestamp,
            _offerIpfsHash
        );
    }

    function _closeOffer(string memory _offerIpfsHash) private {
        s_offerStatus[_offerIpfsHash] = true;

        emit OfferClosed(_offerIpfsHash);
    }

    function _isPastDue(uint256 _time) private view returns (bool) {
        return (block.timestamp - _time) < FUND_WITHDRAWAL_DELAY;
    }

    function _isWithinCancellationPeriod(
        uint256 _time
    ) private view returns (bool) {
        return (block.timestamp - _time) <= FUND_WITHDRAWAL_DELAY;
    }

    function getMissionByFid(
        uint256 _recruiterFid,
        uint256 _devFid
    ) external view returns (Mission memory) {
        return s_missionsByFid[_recruiterFid][_devFid];
    }

    function getMissionByOfferIpfsHash(
        string memory _offerIpfsHash
    ) external view returns (Mission memory) {
        return s_missionByOfferIpfsHash[_offerIpfsHash];
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = s_priceFeed.latestRoundData();
        return uint256(price) * 10 ** 10;
    }

    function isOfferClosed(
        string memory _offerIpfsHash
    ) public view returns (bool) {
        return s_offerStatus[_offerIpfsHash];
    }
}
