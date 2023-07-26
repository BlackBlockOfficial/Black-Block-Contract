//SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import './interfaces/IBlockLiquidity.sol';
import './librarys/SafeMath.sol';

contract BlockLiquidity is IBlockLiquidity, IERC721Receiver { 

    using SafeMath for uint;

    INonfungiblePositionManager public constant nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IUniswapV3Factory public constant uniswapV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /**********************************BlackBlock*******************************/

    address private blackblock;

    /*******************************Token Reserve*******************************/

    mapping (address => uint256) public swapReserve;

    /*************************Pool Token previous Balance***********************/

    mapping (address => mapping (address => uint256)) public previousBalance;

    /*********************************Liquidity*********************************/

    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
        uint24 fee;
    }

    mapping(uint256 => Deposit) private deposits;

    /****************************Token0 Token1 Pool*****************************/

    mapping(address => mapping(address => address)) private pool;

    /********************************Token ID************************************/

    mapping(address => uint256) private tokenID;

    /**********************************Pools************************************/

    address[] private pools;

    /*******************************Previous Time*******************************/

    uint256 private previousTime;

    /*********************************Creator***********************************/

    constructor() {
         previousTime = block.timestamp + 86400;
    }

    /**************************Set BlackBlock address***************************/

    function setBlackBlockAddress() external override {
       require(blackblock == address(0), "BlackBlock is Here!");
       blackblock = msg.sender;
       swapReserve[msg.sender] = balanceOf(msg.sender, address(this));
    }

    /*****************************Receive Liquidity*****************************/

    function onERC721Received(address operator, address, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        require(address(this) == operator, "Only Liquidity");
        _createDeposit(operator, tokenId);
        return this.onERC721Received.selector;
    }

    /***************************************************************************/
    /*************************LOCK LIQUIDITY: ATTENTION!************************/ 
    /***************************************************************************/

    /*The liquidity transferred to the contract through the lockLiquidity function is in no way withdrawable.*/
    /*This function should only be used if you understand how this smart contract works.*/
    /*Using this function is equivalent to burning your capital.*/
    /*The use of this function does not bring any personal benefit.*/

    function lockLiquidity(uint256 tokenId) external override {
        nonfungiblePositionManager.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    /*****************************Sync Swap Reserve*****************************/

    function syncSwapReserve(address poolAddress, address token) external {

        uint256 tokenId = tokenID[poolAddress];

        (, , address token0, address token1, ) = getDeposits(tokenId);

        if(token0 == token || token1 == token) {
            swapReserve[token] = balanceOf(token, address(this));
        } else {
            revert("The token not exist");
        }

    }

    /************Collects the fees associated with provided liquidity***********/

    function collectAllFees(uint256 tokenId) public override {

        if(block.timestamp > previousTime) {

            address token0 = deposits[tokenId].token0;
            address token1 = deposits[tokenId].token1;

            INonfungiblePositionManager.CollectParams memory params =
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenId,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                });

            (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.collect(params);

            if(amount0 > 0) {
                swapReserve[token0] = swapReserve[token0].add(amount0);
            }

            if(amount1 > 0) {
                swapReserve[token1] = swapReserve[token1].add(amount1);
            }

            previousTime = block.timestamp + 86400;

        }

    }

    /**************************Swap Exact Input Single**************************/

    function swapExactInputSingle(uint256 amountIn,  uint256 tokenId, address tokenIn) external override
    returns (uint256 amountOut, address tokenOut) {

        address token0 = deposits[tokenId].token0;
        address token1 = deposits[tokenId].token1;

        tokenOut = tokenIn == token0 ? token1 : token0;

        address poolAddress = getPool(token0, token1);

        (uint256 mAmountIn, , ) = monitoring(poolAddress);

        if(swapReserve[tokenIn] >= amountIn && mAmountIn >= amountIn) {

            uint24 poolFee = deposits[tokenId].fee;

            TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp + 30,
                    amountIn: amountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

            amountOut = swapRouter.exactInputSingle(params);

            if(amountOut > 0) {

                collectAllFees(tokenId);

                (uint256 balance0, uint256 balance1, ) = _currentBalances(token0, token1);

                previousBalance[poolAddress][token0] = balance0;
                previousBalance[poolAddress][token1] = balance1;

                swapReserve[tokenIn] = swapReserve[tokenIn].sub(amountIn);

                if(tokenIn == blackblock) {
                    swapReserve[tokenOut] = swapReserve[tokenOut].add(amountOut);
                } else {
                    TransferHelper.safeTransfer(blackblock, blackblock, amountOut);
                    IBlackBlock(blackblock).burnLiquidity();
                }

            }

        } else {
            revert("Insufficient Swap Reserve");
        }

    }

    /********************************Monitoring 2B******************************/

    function monitoring(address poolAddress) public view override returns(uint256 amountIn, uint256 tokenId, address tokenIn) {

        tokenId = getTokenID(poolAddress);

        address token0 = deposits[tokenId].token0;
        address token1 = deposits[tokenId].token1;

        address token = blackblock == token0 ? token1 : token0;

        uint256 _previousBlackBlockBalance =  previousBalance[poolAddress][blackblock];
        uint256 _balanceBlackBlock = balanceOf(blackblock, poolAddress);

        if (_balanceBlackBlock < _previousBlackBlockBalance) {

            uint256 _amount = _previousBlackBlockBalance.sub(_balanceBlackBlock);

            uint256 percentage =  _percentage(_amount);

            uint256 amount = FullMath.mulDiv(min(swapReserve[blackblock], _amount), percentage, 100);

            if(swapReserve[blackblock] >= amount) {
                amountIn = amount;
                tokenId = tokenId;
                tokenIn = blackblock;
            }

        } else if (_balanceBlackBlock > _previousBlackBlockBalance) {

            uint256 _amount = _balanceBlackBlock.sub(_previousBlackBlockBalance);

            uint256 percentage =  _percentage(_amount);

            uint256 amount = FullMath.mulDiv(swapReserve[token], percentage, 100);

            if(swapReserve[token] >= amount) {
                amountIn = amount;
                tokenId = tokenId;
                tokenIn = token;
            }

        }

    }

    /**********************************Deposits*********************************/

    function getDeposits(uint256 tokenId) public view override
    returns (address owner, uint128 liquidity, address token0, address token1, uint24 fee) {

        Deposit memory deposit = deposits[tokenId];

        owner = deposit.owner;
        liquidity = deposit.liquidity;
        token0 = deposit.token0;
        token1 = deposit.token1;
        fee = deposit.fee;

    }

    /******************************Get Pool Address*****************************/

    function getPool(address tokenA, address tokenB) public view override returns (address poolAddress) {
        poolAddress = pool[tokenA][tokenB];
    }

    /*******************************Get Token Id*********************************/

    function getTokenID(address poolAddress) public view override returns(uint256 tokenId) {
      tokenId = tokenID[poolAddress];
    }

    /*****************************Get Pools Address*****************************/

    function getPools() public view override returns(address[] memory) {
      return pools;
    }

    /*****************************Supply Functions******************************/

    function balanceOf(address token_, address account) public view override returns(uint) {
      return IERC20(token_).balanceOf(account);
    }

    /****************************BlackBlock Contract****************************/

    function blackblockContract() external view override returns (address) {
        return blackblock;
    }

    /******************************Deposit id token*****************************/

    function _createDeposit(address owner_, uint256 tokenId) internal {

        (, , address token0, address token1, uint24 fee, , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(tokenId);

        require(token0 == blackblock || token1 == blackblock, "Error token ID");

        deposits[tokenId] = Deposit({
            owner: owner_,
            liquidity: liquidity,
            token0: token0,
            token1: token1,
            fee: fee
        });

        _poolAddress(token0, token1, fee, tokenId);

        (uint256 balance0, uint256 balance1, address poolAddress) = _currentBalances(token0, token1);

        previousBalance[poolAddress][token0] = balance0;
        previousBalance[poolAddress][token1] = balance1;
    }

    /*****************************Add Pools Address*****************************/

    function _poolAddress(address _token0, address _token1, uint24 _fee, uint256 tokenId) internal {

        address _pool = uniswapV3Factory.getPool(_token0, _token1,_fee);

        require(_pool != address(0), "pool doesn't exist");

        pool[_token0][_token1] = _pool;
        tokenID[_pool] = tokenId;
        pools.push(_pool);

    }

    /**************************Calculate Previous Price*************************/

    function _currentBalances(address token0, address token1) internal view
    returns (uint256 balance0, uint256 balance1, address poolAddress) {

        poolAddress = getPool(token0, token1);

        balance0 = balanceOf(token0, poolAddress);
        balance1 = balanceOf(token1, poolAddress);

    }

    /***************************Return min amount******************************/

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z =( x < y ? x : y);
    }

    /********************************Percentage*********************************/

    function _percentage(uint256 amount) internal pure returns(uint8 percentage) {

        if (amount < 100000000e18) {
            percentage = 1;
        } else if (amount >= 100000000e18 && amount < 500000000e18) {
            percentage = 5;
        } else if (amount >= 500000000e18 && amount < 1000000000e18) {
            percentage = 10;
        } else if (amount >= 1000000000e18 && amount < 5000000000e18) {
            percentage = 15;
        } else if (amount >= 5000000000e18 && amount < 10000000000e18) {
            percentage = 20;
        } else if (amount >= 10000000000e18 && amount < 50000000000e18) {
            percentage = 25;
        } else if (amount >= 50000000000e18 && amount < 100000000000e18) {
            percentage = 30;
        } else if (amount >= 100000000000e18 && amount < 500000000000e18) {
            percentage = 35;
        } else if (amount >= 500000000000e18 && amount < 1000000000000e18) {
            percentage = 40;
        } else {
            percentage = 45;
        }

    }

}
