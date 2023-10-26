// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Farm is Ownable {

    event Deposit(
        address indexed from,
        uint256 multiplier,
        uint256 lockIndex,
        uint256 amount
    );

    event Withdraw(
        address indexed from,
        uint256 lockIndex,
        uint256 amount
    );

    event Claim(
       address indexed from,
       uint256 lockIndex,
       uint256 _period,
       uint256 pending,
       address _to
    );

    event TransferLockOwner(
          address indexed from,
          address indexed to,
          uint256 index,
          uint256 amount
    );

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;            
        uint256 allocPoint;        
        uint256 lastRewardBlock;   
        uint256 accCakePerShare;
    }

    struct UserLockInfo{
        uint256 amount;
        uint256 unLockTime;
        uint256 multiplier; // 倍数
        uint256 rewardDebt;
        uint256 pid;
    }

    uint256[] public accCakePerShareArchive;  // 这个period结束的时候的 accCakePerShare

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    uint256 public cakePerBlock;
    uint256[] public periodAmount;
    uint256 public periodBlock; 
    uint256 public periodIndex;

    uint256 public lastPeriodStartBlock;

    address public tokenFactory;

    mapping (address => mapping (uint256 => UserLockInfo)) public userLock;
    mapping (address => uint256) public userUnlockIndexs;

    PoolInfo[] public poolInfo;

    uint256 public multiplier1; // 锁一个月一倍， 2个月2倍。。。。
    uint256 public multiplier2;
    uint256 public multiplier3;
    uint256 public multiplier4;

    address public un;

    uint256[4] public lockTime;

    uint256[4] public multipliers;

    uint256[] public unPerBlockList;
    
    uint256 public totalWeights; // 总权重，表示总的倍率只和

    mapping (uint256 => mapping (address => UserInfo)) public userInfo; // pid => user => info 

    constructor(
        address initialOwner,
        uint256 _periodBlock,
        uint256[] memory _unPerBlockList,
        uint256 _startBlock,
        address _un
    ) Ownable(initialOwner) {
        periodBlock = _periodBlock; // 一个 period 周期是多少个block
        startBlock = _startBlock;       // 开始块
        lastPeriodStartBlock = startBlock;

        unPerBlockList = _unPerBlockList;
        cakePerBlock = _unPerBlockList[0];

        lockTime[0] = 30 days;
        lockTime[1] = 90 days;
        lockTime[2] = 180 days;
        lockTime[3] = 360 days;
        un = _un;
    }

    function setMultiplier(
        uint256 _multiplier1, 
        uint256 _multiplier2, 
        uint256 _multiplier3, 
        uint256 _multiplier4 
    ) public onlyOwner{
        multipliers[0] = _multiplier1;
        multipliers[1] = _multiplier2;
        multipliers[2] = _multiplier3;
        multipliers[3] = _multiplier4;
    }

    function add(uint256 _allocPoint, IERC20 _lpToken) public onlyOwner {
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCakePerShare: 0
        }));
        updateStakingPool();
    }

    // lock LP
    function depositAndLock(uint256 _pid, uint256 _multiplierIndex, uint256 _amount, address _to) public { 
        require(_amount > 0, "Farm: amount cannot be 0");
        require( _multiplierIndex < 4, "Farm: _multiplierIndex < 4");

        updatePool(_pid);
        
        PoolInfo memory pool = poolInfo[_pid];
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);

        userUnlockIndexs[_to] = userUnlockIndexs[_to] + 1;
        uint256 _unlockTime = lockTime[_multiplierIndex] + block.timestamp;
        uint256 _multiplier =  multipliers[_multiplierIndex];
        uint256 _rewardDebt =  _amount * _multiplier * pool.accCakePerShare / 1e12;

        userLock[_to][userUnlockIndexs[_to]] = UserLockInfo(
            _amount,
            _unlockTime, 
           _multiplier,
           _rewardDebt,
            _pid
        );

        totalWeights = (totalWeights + _amount) * _multiplier;

        emit Deposit(_to, _multiplier, userUnlockIndexs[_to],  _amount);
    }

    function withdraw( uint256 _lockIndex, uint256 _amount) public {
        require(_amount > 0, "Farms: amount cannot be 0");
        UserLockInfo storage userLockInfo = userLock[msg.sender][_lockIndex];
        require(block.timestamp > userLockInfo.unLockTime, "Farm: Not expired");
        require(userLockInfo.amount > 0, "Farm: Not amount");
       
        updatePool(userLockInfo.pid);

        transfer(userLockInfo.pid, msg.sender, _amount);
        userLockInfo.amount = userLockInfo.amount - _amount;

        totalWeights = (totalWeights - _amount) * userLockInfo.multiplier;

        emit Withdraw(msg.sender, _lockIndex, _amount);
    }

    function claim(uint256 _userUnlockIndex, uint256 _period, address _to) public {
        UserLockInfo storage userLockInfo = userLock[msg.sender][_userUnlockIndex];
        updatePool(userLockInfo.pid);
        
        uint256 _accCakePerShare = accCakePerShareArchive[_period];

        if (userLockInfo.amount > 0) {
            uint256 pending = userLockInfo.amount * userLockInfo.multiplier * 
                _accCakePerShare / 1e12 - userLockInfo.rewardDebt;

            // Update user's reward debt before making any external calls
            userLockInfo.rewardDebt = userLockInfo.amount * userLockInfo.multiplier * _accCakePerShare / 1e12;

            if(pending > 0) {
                IERC20(un).transfer(_to, pending);
            }

            emit Claim(
                msg.sender,
                _userUnlockIndex,
                _period,
                pending,
                _to
            );
        }

    }

    function claimAll(uint256[] memory _userUnlockIndexs, uint256 _period,  address _to) public {
        uint256 length = _userUnlockIndexs.length;
        for (uint256 i = 0; i < length; i++) {
            claim(_userUnlockIndexs[i], _period, _to);
        }
    }

    function pendingRewards(uint256 _userUnlockIndex, address _user) 
        public 
        view 
        returns(uint256, uint256, uint256, uint256) 
    {
        UserLockInfo storage userLockInfo = userLock[_user][_userUnlockIndex];
        PoolInfo storage pool = poolInfo[userLockInfo.pid];
     
        uint256 lpSupply = totalWeights;

        uint256 totalPending;
        uint256 unLockPending;
        uint256 accCakePerShare = pool.accCakePerShare;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 time = getTime(pool.lastRewardBlock, block.number);
            uint256 cakeReward = time * cakePerBlock * pool.allocPoint / totalAllocPoint;
    
            accCakePerShare = (accCakePerShare + cakeReward) * 1e12 / lpSupply;
        }
        
        totalPending = userLockInfo.amount * userLockInfo.multiplier * accCakePerShare / 1e12 - userLockInfo.rewardDebt;

        if(accCakePerShareArchive.length > 0) {
            for(uint i = 0; i< accCakePerShareArchive.length; i++) {
                uint256 accCakePerShare1 = accCakePerShareArchive[i];
                unLockPending += userLockInfo.amount * userLockInfo.multiplier * 
                    accCakePerShare1 / 1e12 - userLockInfo.rewardDebt;
            }
        }
    
        return (
            userLockInfo.amount,
            userLockInfo.unLockTime,
            totalPending,
            unLockPending
        );
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points + poolInfo[pid].allocPoint;
        }
        if (points != 0) {
            points = points / 3;
            totalAllocPoint = totalAllocPoint - poolInfo[0].allocPoint + points;
            poolInfo[0].allocPoint = points;
        }
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 _accCakePerShare =  pool.accCakePerShare;
        uint256 _lastRewardBlock =  pool.lastRewardBlock;

        uint256 time = getTime(pool.lastRewardBlock, block.number);
        uint256 cakeReward = time * cakePerBlock * pool.allocPoint / totalAllocPoint;

        pool.accCakePerShare = (pool.accCakePerShare + cakeReward) * 1e12 / lpSupply;
        pool.lastRewardBlock = block.number;

        updatePeriod(_lastRewardBlock, pool.allocPoint, _accCakePerShare, lpSupply);
    }

    function updatePeriod(
        uint256 _lastRewardBlock, 
        uint256 _allocPoint, 
        uint256 _accCakePerShare, 
        uint256 _lpSupply
    ) internal {
        uint256 diffBlock = block.number - lastPeriodStartBlock;
        if(diffBlock >= periodBlock) {
             uint256 time = getTime(_lastRewardBlock, startBlock + periodBlock);
             uint256 cakeReward = time * cakePerBlock * _allocPoint / totalAllocPoint;
            accCakePerShareArchive.push((_accCakePerShare + cakeReward) * 1e12 / _lpSupply);
            lastPeriodStartBlock = lastPeriodStartBlock + periodBlock;
            periodIndex = periodIndex + 1;
            cakePerBlock = unPerBlockList[periodIndex]; // 减半
        }
    }

    function transfer(uint256 _pid, address _to, uint256 _amount) internal {
        PoolInfo memory pool = poolInfo[_pid];
        pool.lpToken.transfer(_to, _amount);
    }

    function getTime(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to - _from;
    }

    function transferLockOwner(address _newOwner, uint256 _userUnlockIndex) public {
        UserLockInfo storage userLockInfo = userLock[msg.sender][_userUnlockIndex];
        require(userLockInfo.amount > 0, "Farm: amount 0");
        UserLockInfo storage newUserLockInfo = userLock[_newOwner][_userUnlockIndex];
        require(userLockInfo.amount == 0, "Farm: newOnwer amount not 0");

        newUserLockInfo.amount = userLockInfo.amount;
        newUserLockInfo.unLockTime = userLockInfo.unLockTime;
        newUserLockInfo.multiplier = userLockInfo.multiplier;
        newUserLockInfo.rewardDebt = userLockInfo.rewardDebt;
        newUserLockInfo.pid = userLockInfo.pid;
        userLockInfo.amount = 0;

        emit TransferLockOwner(msg.sender, _newOwner, _userUnlockIndex, newUserLockInfo.amount);
    }
}