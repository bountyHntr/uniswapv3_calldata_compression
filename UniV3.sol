// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract UniV3 {
    struct TokenInfo {
        address tokenAddress;
        uint8 decimals;
    }

    address payable internal immutable owner;
    address internal constant router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint24[4] private fees  = [100, 500, 3000, 10_000];

    bytes4 internal constant EXACT_INPUT_SINGLE_ID = 0x414bf389; // router exactInputSingle
    bytes4 internal constant TRANSFER_FROM_ID = 0x23b872dd; // ERC20 transferFrom

    TokenInfo[] public tokensInfo;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function registerTokens(TokenInfo[] calldata _tokensInfo) external onlyOwner {
        for(uint i = 0; i < _tokensInfo.length; i++) {
            TokenInfo memory tokenInfo = _tokensInfo[i];

            bool seen;
            for(uint j = 0; j < tokensInfo.length; j++) {
                if (tokenInfo.tokenAddress == tokensInfo[j].tokenAddress) {
                    seen = true;
                    break;
                }
            }

            if (!seen) {
                tokensInfo.push(tokenInfo);
                require(IERC20(tokenInfo.tokenAddress).approve(router, type(uint).max));
            }
        }
    }

    function updateTokenInfo(TokenInfo calldata _tokenInfo) external onlyOwner {
        for(uint i = 0; i < tokensInfo.length; i++) {
            if (tokensInfo[i].tokenAddress == _tokenInfo.tokenAddress) {
                tokensInfo[i].decimals = _tokenInfo.decimals;
            }
        }
    }

    function kill() external payable onlyOwner {
        require(msg.value != 0); // protection against accidental destruction
        selfdestruct(owner);
    }

    function withdraw(address token) external onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        require(balance != 0);
        require(IERC20(token).transfer(owner, balance));
    }

    receive() external payable {
    }

    // 3 bytes - amountIn
    // path:
    // 1 byte: 6 bits - token id; 2 bits - fee
    fallback() external {
        assembly {
            mstore(0x00, tokensInfo.slot)
            let firstTokenSlot := keccak256(0x00, 0x20)

            let path := calldataload(0x03)
            let swapsAmount := sub(calldatasize(), 0x04)

            let tokenInInfo := sload(add(firstTokenSlot, shr(250, path)))
            path := shl(6, path)
            let tokenIn := and(tokenInInfo, 0xffffffffffffffffffffffffffffffffffffffff)
            let amount := mul(shr(232, calldataload(0x00)), exp(10, shr(160, tokenInInfo)))
            pop(tokenInInfo)


            // ********
            // transferFrom(address from, address to, uint256 amount)
            mstore(0x7c, TRANSFER_FROM_ID)
            mstore(0x80, caller())
            mstore(0xa0, address())
            mstore(0xc0, amount)

            if iszero(call(gas(), tokenIn, 0, 0x7c, 0x64, 0x00, 0x00)) {
                returndatacopy(0x80, 0x00, returndatasize())
                revert(0x80, returndatasize())
            }
            // ********



            // ********
            // struct ExactInputSingleParams {
            //     address tokenIn;
            //     address tokenOut;
            //     uint24 fee;
            //     address recipient;
            //     uint256 deadline;
            //     uint256 amountIn;
            //     uint256 amountOutMinimum;
            //     uint160 sqrtPriceLimitX96;
            // }

            // function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

            let tokenOut
            let _fees := sload(fees.slot)

            mstore(0x7c, EXACT_INPUT_SINGLE_ID)
            mstore(0xe0, address())
            mstore(0x100, not(0))

            for { let i := 0 } lt(i, swapsAmount) { i := add(i, 1) } {
                let b := shr(248, path)
                tokenOut := and(sload(add(firstTokenSlot, and(b, 0x3f))), 0xffffffffffffffffffffffffffffffffffffffff)

                mstore(0x80, tokenIn)
                mstore(0xa0, tokenOut)
                mstore(0xc0, and(shr(mul(24, shr(6, b)), _fees), 0xffffff))
                mstore(0x120, amount)

                if eq(i, sub(swapsAmount, 1)) {
                    mstore(0xe0, caller())
                }

                if iszero(call(gas(), router, 0, 0x7c, 0x104, 0x80, 0x20)) {
                    returndatacopy(0x80, 0x00, returndatasize())
                    revert(0x80, returndatasize())
                }
                
                amount := mload(0x80)
                path := shl(8, path)
                tokenIn := tokenOut
            }
            // ********
        }
    }
}