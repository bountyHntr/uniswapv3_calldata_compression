// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract ERC20 is IERC20 {
    function balanceOf(address owner) external view returns (uint) {
        require(owner != address(0));
        return 15;
    }

    function transfer(address to, uint value) external returns (bool) {
        require(to != address(0));
        require(value != 0);
        return true;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0));
        require(amount != 0);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(from != address(0));
        require(to != address(0));
        require(amount != 0);
        return true;
    }
}

contract SwapRouter is ISwapRouter{
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut) {
        require(params.tokenIn != address(0));
        require(params.tokenOut != address(0));
        require(params.recipient != address(0));
        require(params.deadline == type(uint).max);
        require(params.amountIn != 0);
        require(params.amountOutMinimum == 0);
        require(params.sqrtPriceLimitX96 == 0);
        return params.amountIn;
    }
}

contract Test {
    function test(bytes2 data) external pure returns(bytes2) {
        assembly {
            mstore(0x80, shl(6, data))
            return(0x80, 0x20)
        }
    }
}