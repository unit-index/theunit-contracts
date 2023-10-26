// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract Unit is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20Votes {

    uint256 public maxSupply;

    constructor(address initialOwner, uint256 _maxSupply)
        ERC20("Unit", "UN")
        Ownable(initialOwner)
        ERC20Permit("Unit")
    {
        maxSupply = _maxSupply;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceed max supply");
        _mint(to, amount);
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function maxSupply() public view override {
        return maxSupply;
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
