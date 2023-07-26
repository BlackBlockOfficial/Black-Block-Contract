// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IBlockLiquidity {

   function swapExactInputSingle(uint256 amountIn, uint256 tokenId, address tokenIn) external 
   returns (uint256 amountOut, address tokenOut);

   function monitoring(address poolAddres) external view returns(uint256 amountIn, uint256 tokenId, address tokenIn);

   function getPools() external view returns(address[] memory);

}

contract GelatoChecker {

    IBlockLiquidity public liquidity;

    constructor(IBlockLiquidity _liquidity) {
        liquidity = _liquidity;
    }

    /***********************************checker*********************************/

    function checker() external view returns (bool canExec, bytes memory execPayload) {

        address[] memory pools = liquidity.getPools();

        uint256 amountIn;
        uint256 tokenId;
        address tokenIn;

        uint i = 0;

        while (i < pools.length) {

            (amountIn, tokenId, tokenIn) = liquidity.monitoring(pools[i]);

            if (amountIn > 0 && tokenId > 0 && tokenIn != address(0)) {
                canExec = true;
            }

            i++;

        }

        execPayload = abi.encodeCall(IBlockLiquidity.swapExactInputSingle, (amountIn, tokenId, tokenIn));

    }


}
