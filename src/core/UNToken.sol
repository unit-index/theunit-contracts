// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/ITinuToken.sol";
// import "hardhat/console.sol";

// Everyone can mint, as long as there is enough collateral.
contract UNToken is ERC20, ITinuToken {

    event Mint (
        address indexed to,
        uint256 value
    );
    event Burn (
        address indexed from,
        uint256 value
    );

    address public gov;

    address public minter;

    uint256 public maxSupply = 8589934592 ether;
    
    modifier onlyGov{
        require(msg.sender == gov, "only gov!");
        _;
    }
    constructor() ERC20("The UN Token", "UN") {
        gov = msg.sender;
        minter = msg.sender;
    }

    function setGov(address _gov) public onlyGov{
          gov = _gov;
    }

    function setMinter(address _newMinter) public onlyGov {
        minter = _newMinter;
    }

    function mint(address _to, uint256 _value) external override returns(bool) {
        require(msg.sender == minter, "No rights!");
        _mint(_to, _value);
        require(totalSupply() <= maxSupply, "Out of range");
        emit Mint(_to, _value);
        return true;
    }

    function burn(uint256 _value) external override returns(bool) {
        _burn(msg.sender, _value);
        emit Burn(msg.sender, _value);
        return true;
    }
}
