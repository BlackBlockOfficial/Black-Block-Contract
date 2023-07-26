// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./token/ERC20/extensions/draft-ERC20Permit.sol";
import "./token/ERC20/extensions/ERC20Burnable.sol";
import "./token/ERC20/extensions/ERC20Snapshot.sol";
import "./interfaces/IBlackBlock.sol";
import "./token/ERC20/ERC20.sol";
import "./access/Ownable.sol";

interface IBlockLiquidity {   
    function setBlackBlockAddress() external;
}

contract BlackBlock is ERC20, Ownable, IBlackBlock, ERC20Burnable, ERC20Snapshot, ERC20Permit {

    address public immutable blockLiquidity;

    constructor(address blockLiquidity_, address pool_) ERC20("Black Block", "2B") ERC20Permit("Black Block") {
         blockLiquidity = blockLiquidity_;
        _mint(blockLiquidity_, 40000000000000 * 10 ** decimals());
        _mint(pool_, 40000000000000 * 10 ** decimals());
        _mint(msg.sender, 20000000000000 * 10 ** decimals());
    }

    /**************************Block Liquidity set address**********************/

    function setBlackBlockAddress() external {
        IBlockLiquidity(blockLiquidity).setBlackBlockAddress();
    }

    /*******************************Burn Liquidity******************************/

    function burnLiquidity() external {
        _burn(address(this), balanceOf(address(this)));
    }

    /*************************Override _beforeTokenTransfer*********************/

    function _beforeTokenTransfer(address from, address to, uint amount) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /*********************************Snapshot**********************************/

    function snapshot() public onlyOwner() {
        _snapshot();
    }

}
