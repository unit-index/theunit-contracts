// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "../interfaces/IRewardDistributor.sol";
import "../interfaces/IRewardTracker.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "forge-std/console.sol"; // test

contract RewardTracker is IERC20, IRewardTracker {

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant PRECISION = 1e30;

    uint8 public constant decimals = 18;

    bool public isInitialized;

    string public name;
    string public symbol;

    address public admin;

    address public distributor;
    mapping (address => bool) public isDepositToken;
    mapping (address => mapping (address => uint256)) public override depositBalances;
    mapping (address => uint256) public totalDepositSupply;

    uint256 public override totalSupply;

    uint256 public totalStakedAmounts;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    uint256 public cumulativeRewardPerToken;
    mapping (address => uint256) public override stakedAmounts;
    mapping (address => uint256) public claimableReward;
    mapping (address => uint256) public previousCumulatedRewardPerToken;
    mapping (address => uint256) public override cumulativeRewards;
    mapping (address => uint256) public override averageStakedAmounts;

    address public gov;

    mapping (address => bool) public isHandler;

    mapping (uint256 => uint256) public lockTime;

    struct Lock{
        uint256 amount;
        uint256 unlockTime;
        uint256 point;
    }

    mapping (address => mapping (uint256 => Lock) ) public override locked; 

    mapping (address => uint256 ) public lockedIndex;

    event Claim(address receiver, uint256 amount);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        gov = msg.sender;

        lockTime[30] = 1;  // 30 days => 1x
        lockTime[90] = 2;
        lockTime[180] = 4;
        lockTime[360] = 8;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
    }

    function initialize(
        address _depositToken,
        address _distributor
    ) external onlyGov {
        require(!isInitialized, "RewardTracker: already initialized");
        isInitialized = true;
        isDepositToken[_depositToken]  = true;
        distributor = _distributor;
    }

    function setDepositToken(address _depositToken, bool _isDepositToken) external onlyGov {
        isDepositToken[_depositToken] = _isDepositToken;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).transfer(_account, _amount);
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return balances[_account];
    }

    function relock( uint256 _lockIndex, uint8 _lockDay) external {
         _relock(msg.sender, _lockIndex, _lockDay);
    }
    
    function stake(address _depositToken, uint256 _amount, uint8 _lockTime) external override  {
        _stake(msg.sender, msg.sender, _depositToken, _amount, _lockTime);
    }

    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount, uint8 _lockDay) external override  {
        _validateHandler();
        _stake(_fundingAccount, _account, _depositToken, _amount, _lockDay);
    }

    function unstake(address _depositToken, uint256 _lockIndex) external override {
        _unstake(msg.sender, _depositToken, _lockIndex, msg.sender);
    }

    function unstakeForAccount(address _account, address _depositToken, uint256 _lockIndex, address _receiver) external override  {
        _validateHandler();
        _unstake(_account, _depositToken, _lockIndex, _receiver);
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        if (isHandler[msg.sender]) {
            _transfer(_sender, _recipient, _amount);
            return true;
        }

        uint256 nextAllowance = allowances[_sender][msg.sender] - _amount;
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function tokensPerInterval() external override view returns (uint256) {
        (uint256 _tokensPerInterval, ) =  IRewardDistributor(distributor).rewardTokenInfo(address(this));
        return _tokensPerInterval;
    }

    function updateRewards() external override  {
        _updateRewards(address(0));
    }

    function claim(address _receiver) external override returns (uint256) {
        return _claim(msg.sender, _receiver);
    }

    function claimForAccount(address _account, address _receiver) external override returns (uint256) {
        _validateHandler();
        return _claim(_account, _receiver);
    }

    function claimable(address _account) public override view returns (uint256) {
        uint256 stakedAmount = stakedAmounts[_account];
        if (stakedAmount == 0) {
            return claimableReward[_account];
        }
        uint256 supply = totalStakedAmounts;
        uint256 pendingRewards = IRewardDistributor(distributor).pendingRewards(address(this)) * PRECISION;
        uint256 nextCumulativeRewardPerToken = cumulativeRewardPerToken + (pendingRewards / supply);
        return claimableReward[_account] + (stakedAmount *  (nextCumulativeRewardPerToken - previousCumulatedRewardPerToken[_account]) / PRECISION);
    }

    function rewardToken() public view returns (address) {
        return IRewardDistributor(distributor).rewardToken();
    }

    function _claim(address _account, address _receiver) private returns (uint256) {
        _updateRewards(_account);
        uint256 tokenAmount = claimableReward[_account];
        claimableReward[_account] = 0;

        if (tokenAmount > 0) {
            IERC20(rewardToken()).transfer(_receiver, tokenAmount);
            emit Claim(_account, tokenAmount);
        }
        return tokenAmount;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "RewardTracker: mint to the zero address");

        totalSupply = totalSupply + _amount;
        balances[_account] = balances[_account] + _amount;

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "RewardTracker: burn from the zero address");
        balances[_account] = balances[_account] - _amount;
        totalSupply = totalSupply - _amount;

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "RewardTracker: transfer from the zero address");
        require(_recipient != address(0), "RewardTracker: transfer to the zero address");
        balances[_sender] = balances[_sender] - _amount;
        balances[_recipient] = balances[_recipient] + _amount;
        emit Transfer(_sender, _recipient,_amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "RewardTracker: approve from the zero address");
        require(_spender != address(0), "RewardTracker: approve to the zero address");
        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "RewardTracker: forbidden");
    }

    function _relock(address _account, uint256 _lockIndex, uint8 _lockDay) private {
        uint256 newPoint = lockTime[_lockDay];
        require(newPoint > 0, "RewardTracker: invalid LockDay");

        Lock memory lock = locked[_account][_lockIndex];

        require(newPoint >= lock.point, "RewardTracker: relock only add time");

        uint256 _pointAmount = lock.amount * lock.point;

        uint256 _newPointAmount = lock.amount * newPoint;

        stakedAmounts[_account] =  stakedAmounts[_account] - _pointAmount;
        totalStakedAmounts =  totalStakedAmounts - _pointAmount; 

        stakedAmounts[_account] = stakedAmounts[_account] + _newPointAmount;
        totalStakedAmounts =  totalStakedAmounts + _newPointAmount;

        uint256 _unlockTime = block.timestamp + (uint256(_lockDay) * 24 * 3600);
        locked[_account][_lockIndex] = Lock(lock.amount , _unlockTime, _newPointAmount);
    }

    function _stake(address _fundingAccount, address _account, address _depositToken, uint256 _amount, uint8 _lockDay) private {
        require(_amount > 0, "RewardTracker: invalid _amount");
        require(isDepositToken[_depositToken], "RewardTracker: invalid _depositToken");
        uint256 point = lockTime[_lockDay];
        require(point > 0, "RewardTracker: invalid LockDay");

        IERC20(_depositToken).transferFrom(_fundingAccount, address(this), _amount);  // Warp in
        _updateRewards(_account);

        uint256 _lockIndex = lockedIndex[_account];
        // TODO - change back to * 24 * 3600
        uint256 _unlockTime = block.timestamp + (uint256(_lockDay) * 2);

        locked[_account][_lockIndex] = Lock(_amount, _unlockTime, point);
        lockedIndex[_account] += 1;

        uint256 _pointAmount = _amount * point;

        stakedAmounts[_account] = stakedAmounts[_account] + _pointAmount; // stake了多少，包括倍数
        totalStakedAmounts =  totalStakedAmounts + _pointAmount;         // 一共staked 了多少 包括倍数

        depositBalances[_account][_depositToken] = depositBalances[_account][_depositToken] + _amount; //  实际充值了多少
        totalDepositSupply[_depositToken] = totalDepositSupply[_depositToken] + _amount; //  一共实际充值了多少
        _mint(_account, _amount); // mint stake token ULP
    }

    function _unstake(address _account, address _depositToken, uint256 _lockIndex, address _receiver ) private {
        require(isDepositToken[_depositToken], "RewardTracker: invalid _depositToken");
        // uint256 point = lockTime[_lockDay];
        // require(point > 0, "RewardTracker: invalid LockDay");
         Lock memory lock = locked[_account][_lockIndex];
        require(lock.amount > 0, "RewardTracker: invalid _amount");
        require(lock.unlockTime <= block.timestamp, "RewardTracker: invalid _lockIndex");

        _updateRewards(_account);

        uint256 _pointAmount = lock.amount * lock.point;

        uint256 stakedAmount = stakedAmounts[_account];
        require(stakedAmounts[_account] >= _pointAmount, "RewardTracker: _pointAmount exceeds stakedAmount");
    
        stakedAmounts[_account] = stakedAmount - _pointAmount;

        totalStakedAmounts =  totalStakedAmounts - _pointAmount; 

        uint256 depositBalance = depositBalances[_account][_depositToken];
        require(depositBalance >= lock.amount, "RewardTracker: _amount exceeds depositBalance");

        depositBalances[_account][_depositToken] = depositBalance - lock.amount;

        totalDepositSupply[_depositToken] = totalDepositSupply[_depositToken] - lock.amount;

        _burn(_account, lock.amount); // burn stake token
        
        IERC20(_depositToken).transfer(_receiver, lock.amount);
    }

    function _updateRewards(address _account) private {
        uint256 blockReward = IRewardDistributor(distributor).distribute();

        // uint256 supply = totalSupply;
        uint256 supply = totalStakedAmounts;

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        if (supply > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken + (blockReward * PRECISION / supply);
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (_account != address(0)) {
            uint256 stakedAmount = stakedAmounts[_account];
            uint256 accountReward = stakedAmount * (_cumulativeRewardPerToken - previousCumulatedRewardPerToken[_account]) / PRECISION;
            uint256 _claimableReward = claimableReward[_account] + accountReward;

            claimableReward[_account] = _claimableReward;
            previousCumulatedRewardPerToken[_account] = _cumulativeRewardPerToken;

            if (_claimableReward > 0 && stakedAmounts[_account] > 0) {
                uint256 nextCumulativeReward = cumulativeRewards[_account] + accountReward;

                averageStakedAmounts[_account] = averageStakedAmounts[_account] * cumulativeRewards[_account] / nextCumulativeReward
                    + (stakedAmount * accountReward / nextCumulativeReward);

                cumulativeRewards[_account] = nextCumulativeReward;
            }
        }
    }
}
