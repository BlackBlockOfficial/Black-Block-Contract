// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IBlackBlock {

    function burnLiquidity() external;
    
}

interface IBlockLiquidity {

   function blockNFT(uint256 tokenId) external;

   function collectAllFees(uint256 tokenId) external;

   function swapExactInputSingle(uint256 amountIn,  uint256 tokenId, address tokenIn) external 
   returns (uint256 amountOut, address tokenOut);

   function monitoring(address poolAddres) external view returns(uint256 amountIn, uint256 tokenId, address tokenIn);

   function getDeposits(uint256 tokenId) external view
   returns (address owner, uint128 liquidity, address token0, address token1, uint24 fee);

   function getPool(address tokenA, address tokenB) external view returns (address poolAddres);

   function getPools() external view returns(address[] memory);

   function getPoolNTF(address poolAddres) external view returns(uint256 tokenId);

   function balanceOf(address token_, address account) external view returns(uint);

   function blackblockContract() external view returns (address);

}