// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Importing the ERC20 standard interface from OpenZeppelin.
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ITicketToken } from "../interfaces/ITicketToken.sol";

// The TicketUN contract, which is an ERC20 token and also implements the ITicketToken interface.
contract TicketUN is ERC20, ITicketToken {

    // Event to log minting of new tokens.
    event Mint (
        address indexed to,
        uint256 value
    );
    
    // Event to log burning of tokens.
    event Burn (
        address indexed from,
        uint256 value
    );

    // Address that is allowed to mint new tickets, which is the Ticket Factory
    address public factory;

    // Timestamp indicating when the tokens can be unlocked.
    uint256 public unLockTime;
    
    // Constructor to initialize the Ticket with name, symbol and unlock time.
    constructor(string memory _name, string memory _symbol, uint256 _unLockTime) ERC20(_name, _symbol) {
        factory = msg.sender; // Set the contract deployer as the initial minter.
        unLockTime = _unLockTime; // Set the unlock time.
    }

    // Function to mint new tokens. Can only be called by the factory.
    function mint(address _to, uint256 _value) external override returns(bool) {
        require(msg.sender == factory, "No rights!"); // Check if the caller is the factory.
        _mint(_to, _value); // Mint the tokens.
        emit Mint(_to, _value); // Emit the Mint event.
        return true;
    }

    // Function to burn tokens. Can be called by any token holder.
    function burn(uint256 _value) external override returns(bool) {
        _burn(msg.sender, _value); // Burn the tokens from the caller's balance.
        emit Burn(msg.sender, _value); // Emit the Burn event.
        return true;
    }
}
