// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract UN is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20Votes {

    /**
     * @notice Max supply of UN, which is 2^33 = 8589934592
     */
    uint256 private _maxTokenSupply = 8589934592 * 10 ** decimals();

    constructor(address initialOwner)
        ERC20("UNIT DAO", "UN")
        Ownable(initialOwner)
        ERC20Permit("UNIT DAO")
    {}

    /**
     * @dev Only owner can mint UN, as long as it doesn't exceed _maxTokenSupply
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= getMaxSupply(), "Exceed max supply");
        _mint(to, amount);
    }

    /**
     * @dev Returns the max supply of UN
     */
    function getMaxSupply() public view returns (uint256) {
         return _maxTokenSupply;
    }

    /**
     * @dev Overriding the _update function to properly 
     *      manage vote balances during token transfers.
     */
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value); // Call parent function from both ERC20 and ERC20Votes.
    }

    /**
     * @dev Overriding the nonces function to support gasless transactions.
     */
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner); // Return the current nonce for the owner.
    }
}
