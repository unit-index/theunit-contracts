// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";

abstract contract BaseScript is Script {
    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev Used to derive the broadcaster's address if $ETH_FROM is not defined.
    string internal mnemonic;

    address internal bridgedUN;

    /// @dev Initializes the transaction broadcaster like this:
    ///
    /// - If $ETH_FROM is defined, use it.
    /// - Otherwise, derive the broadcaster address from $MNEMONIC.
    /// - If $MNEMONIC is not defined, default to a test mnemonic.
    ///
    /// The use case for $ETH_FROM is to specify the broadcaster key and its address via the command line.
    constructor() {
        address from = vm.envOr({ name: "ETH_FROM", defaultValue: address(0) });
        if (from != address(0)) {
            broadcaster = from;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (broadcaster,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
        }

        bridgedUN = 0x983542016D5417Cf36A10521756a790c2c5BFDA3;
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }

    function _getContractAddress(string memory scriptName) internal view returns(address contractAddress) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/broadcast/Deploy", scriptName, ".s.sol/", vm.toString(block.chainid), "/run-latest.json");
        string memory json = vm.readFile(path);
        contractAddress = abi.decode(
          stdJson.parseRaw(
            json,
            ".transactions[0].contractAddress"
          ),
          (address)
        );
    }
}
