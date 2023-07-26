// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./access/Ownable.sol";
import "./token/ERC20/utils/SafeERC20.sol";
import "./token/ERC20/extensions/IERC20Metadata.sol";
import "./security/ReentrancyGuard.sol";

contract Blackblockairdrop is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    address public immutable token;
    uint256 public immutable start_data;
    uint256 public immutable end_data;
    uint256 public immutable default_reward;
    uint256 public immutable boosting_reward;
    uint256 private reserve_amount_reward;

    struct AIRDROPS {
        address account;
        string twitter_username;
        string telegram_username;
        string tweet_link;
        string youtube_link;
        bool boosting;
        bool check;
    }

    mapping (address => AIRDROPS) public air_drops;

    address[] public accounts;

    constructor(address _token, uint256 _reward, uint256 _boosting_reward, uint256 _startday, uint256 _days) {
        token = _token;
        default_reward = _reward * 10 ** IERC20Metadata(_token).decimals();
        boosting_reward = _boosting_reward * 10 ** IERC20Metadata(_token).decimals();
        start_data = _startday;
        end_data = _startday + (_days * 86400);
    }

    /*******************************Register Account******************************/

    function registerAccount(string[] calldata data) external nonReentrant returns (bool) {

        require(start_data < block.timestamp && start_data > 0, "No Airdrops at the moment");
        require(end_data > block.timestamp, "This airdrop is ended");

        address account = _msgSender();

        require(account != air_drops[account].account, "Account exists");

        string memory twitter_username = data[0];
        string memory telegram_username = data[1];
        string memory tweet_link = data[2];
        string memory youtube_link = data[3];

        uint256 temp_amount = keccak256(bytes(youtube_link)) > 0 
        ? reserve_amount_reward - (default_reward + boosting_reward) 
        : reserve_amount_reward - default_reward;

        require(reserve_amount_reward >= temp_amount, "This airdrop is ended");

        air_drops[account] = AIRDROPS(account, twitter_username, telegram_username, tweet_link, youtube_link, false ,false);

        accounts.push(account);

        reserve_amount_reward = temp_amount;

        emit Register(account, twitter_username, telegram_username, tweet_link, youtube_link);

        return true;

    }

    /********************************Reward Airdrop********************************/

    function airdrop() external nonReentrant returns (bool) {

        require(end_data < block.timestamp, "This airdrop is in progress");

        address account = _msgSender();

        require(account == air_drops[account].account, "Account not exists");

        bool check = air_drops[account].check;
        bool boosting = air_drops[account].boosting;

        if(check && boosting) {
            deleteAccount(account);
            emit Airdrop(account, (default_reward + boosting_reward));
            IERC20(token).safeTransfer(account, (default_reward + boosting_reward));
        } else if (check) {
            deleteAccount(account);
            emit Airdrop(account, default_reward);
            IERC20(token).safeTransfer(account, default_reward);
        } else {
            revert("Reward error");
        }

        return true;

    }

    /********************************Check Airdrops********************************/

    function checkAirdrops(address[] calldata accounts_, bool[] calldata check_, string[] calldata boosting_) external onlyOwner() {

        address[] memory _accounts = accounts_;
        bool[] memory _check = check_;
        string[] memory _boosting = boosting_;

        for (uint256 i = 0; i < _accounts.length; i++) {
            _checkAirdrop(_accounts[i], _check[i], _boosting[i]);
        }

    }

    /****************************Add reserve for reward****************************/

    function reserve(uint256 _reserve_amount) external onlyOwner() {
        require(IERC20(token).balanceOf(_msgSender()) >= _reserve_amount, "Insufficient balance");
        IERC20(token).safeTransferFrom(_msgSender(), address(this), _reserve_amount);
        reserve_amount_reward = reserve_amount_reward + _reserve_amount;
    }

    /******************************Withdraw Remainder******************************/

    function withdrawRemainder() external onlyOwner() {
        require(end_data < block.timestamp, "This airdrop is in progress");
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 withdraw = balance - reserve_amount_reward;
        IERC20(token).safeTransfer(_msgSender(), balance - withdraw);
    }

    /***********************************Airdrop************************************/

    function _checkAirdrop(address _account, bool _check, string memory _boosting) private {

        address account = _account;

        require(account == air_drops[account].account, "Account not exists");

        bytes32 boostingHash = keccak256(bytes(_boosting));
        bytes32 compareHas = keccak256(bytes(air_drops[account].youtube_link));

        if (boostingHash == compareHas) {
            air_drops[account].boosting = true;
        }

        air_drops[account].check = _check;

        emit Checkairdrop(_account, boostingHash, compareHas, _check);

    }

    /*********************************Delete Account*******************************/

    function deleteAccount(address account) private {
        delete air_drops[account];
    }

    /********************************Fetch Accounts********************************/

    function fetchAccounts(uint cursor, uint byPage) external view returns (AIRDROPS[] memory airdrops, uint newCursor) {

        uint length = byPage;

        if (length > accounts.length - cursor) {
            length = accounts.length - cursor;
        }

        AIRDROPS[] memory _airdrop = new AIRDROPS[](length);

        for (uint i = 0; i < length; i++) {

            address account = accounts[cursor + i];

            AIRDROPS memory param_ = air_drops[account];

            _airdrop[i] = param_;

        }

        return (_airdrop,  cursor + length);
    }

    /****************************Reserve Amount Reward*****************************/

    function reserveAmountReward() external view returns (uint256 amount) {
        amount = reserve_amount_reward;
    }

    /*************************************Events***********************************/

    event Register(address account, string twitter_username, string telegram_username, string tweet_link, string youtube_link);
    event Checkairdrop(address account, bytes32 boostinghash, bytes32 comparehas, bool check);
    event Airdrop(address account, uint256 reward);

}
