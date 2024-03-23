// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TypecastRegistry {
    struct Mission {
        address devAddress;
        uint256 devFid;
        address recruiterAddress;
        uint256 recruiterFid;
        uint256 amountDue;
        uint256 hiredAt;
        uint256 completedAt;
    }

    uint256 public constant FUND_WITHDRAWAL_DELAY = 7 days;
    mapping(address recruiter => mapping(address devAddress => Mission))
        public missions;

    error TypecastRegistry__InvalidAmount(uint256 amount);
    error TypecastRegistry__InvalidAddress();
    error TypecastRegistry__MissionNotFound();
    error TypecastRegistry__MissionNotPastDue();
    error TypecastRegistry__TransferFailed();
    error TypecastRegistry__MissionCancelPastDue();

    function hire(
        address _devAddress,
        uint256 _devFid,
        uint256 _recruiterFid
    ) external payable {
        if (_devAddress == address(0)) {
            revert TypecastRegistry__InvalidAddress();
        }
        if (msg.value <= 0) {
            revert TypecastRegistry__InvalidAmount(msg.value);
        }
        _createMission(
            msg.sender,
            _recruiterFid,
            _devAddress,
            _devFid,
            msg.value
        );
    }

    function cancelMission(address _devAddress) external {
        Mission storage mission = missions[msg.sender][_devAddress];
        if (mission.hiredAt <= 0) {
            revert TypecastRegistry__MissionNotFound();
        }
        if (_isPastDue(mission.hiredAt)) {
            revert TypecastRegistry__MissionCancelPastDue();
        }
        delete missions[msg.sender][_devAddress];
        (bool success, ) = msg.sender.call{value: mission.amountDue}("");
        if (!success) {
            revert TypecastRegistry__TransferFailed();
        }
    }

    function completeMission(address _recruiter) external {
        Mission storage mission = missions[_recruiter][msg.sender];
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
    }

    function _createMission(
        address _recruiter,
        uint256 _recruiterFid,
        address _devAddress,
        uint256 _devFid,
        uint256 _amount
    ) private {
        Mission memory newMission = Mission(
            _devAddress,
            _devFid,
            _recruiter,
            _recruiterFid,
            _amount,
            block.timestamp,
            0
        );
        missions[_recruiter][_devAddress] = newMission;
    }

    function _isPastDue(uint256 _time) private view returns (bool) {
        return (block.timestamp - _time) < FUND_WITHDRAWAL_DELAY;
    }

    function getMission(
        address _recruiter,
        address _devAddress
    ) external view returns (Mission memory) {
        return missions[_recruiter][_devAddress];
    }
}
