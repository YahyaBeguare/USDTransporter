// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Deploy this contract on Ethereum sepolia

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract USDCTransporter is Ownable {
    using SafeERC20 for IERC20;

    error NotEnoughBalanceForFees(uint256 currentBalance, uint256 calculatedFees);
    error NotEnoughBalanceUsdcForTransfer(uint256 currentBalance);
    error NothingToWithdraw();

    IRouterClient private immutable ccipRouter;
    IERC20 private immutable linkToken;
    IERC20 private immutable usdcToken;

    // https://docs.chain.link/ccip/supported-networks/v1_2_0/testnet#op-sepolia
    address ccipRouterAddress = 0x114A20A10b43D4115e5aeef7345a1A71d2a60C57;

    // https://docs.chain.link/resources/link-token-contracts#op-sepolia
    address linkAddress = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;

    // https://developers.circle.com/stablecoins/docs/usdc-on-test-networks
    address usdcAddress = 0x5fd84259d66Cd46123540766Be93DFE6D43130D7;



    event UsdcTransferred(
        bytes32 messageId,
        uint64 destinationChainSelector,
        address receiver,
        uint256 amount,
        uint256 ccipFee
    );

    constructor() Ownable(msg.sender) {
        ccipRouter = IRouterClient(ccipRouterAddress);
        linkToken = IERC20(linkAddress);
        usdcToken = IERC20(usdcAddress);
    }

    function transferUsdcToSepolia(
        uint64 _destinationChainSelector,
        address _receiver,
        uint256 _amount
    )
        external
        returns (bytes32 messageId)
    {
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: address(usdcToken),
            amount: _amount
        });
        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0})
            ),
            feeToken: address(linkToken)
        });

        uint256 ccipFee = ccipRouter.getFee(
            _destinationChainSelector,
            message
        );

        if (ccipFee > linkToken.balanceOf(address(this)))
            revert NotEnoughBalanceForFees(linkToken.balanceOf(address(this)), ccipFee);
        linkToken.approve(address(ccipRouter), ccipFee);

        if (_amount > usdcToken.balanceOf(msg.sender))
            revert NotEnoughBalanceUsdcForTransfer(usdcToken.balanceOf(msg.sender));
        usdcToken.safeTransferFrom(msg.sender, address(this), _amount);
        usdcToken.approve(address(ccipRouter), _amount);

        // Send CCIP Message
        messageId = ccipRouter.ccipSend(_destinationChainSelector, message);

        emit UsdcTransferred(
            messageId,
            _destinationChainSelector,
            _receiver,
            _amount,
            ccipFee
        );
    }

    function allowanceUsdc() public view returns (uint256 usdcAmount) {
        usdcAmount = usdcToken.allowance(msg.sender, address(this));
    }

    function balancesOf(address account) public view returns (uint256 linkBalance, uint256 usdcBalance) {
        linkBalance =  linkToken.balanceOf(account);
        usdcBalance = usdcToken.balanceOf(account);
    }


    function withdrawToken(
        address _beneficiary,
        address _token
    ) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        IERC20(_token).transfer(_beneficiary, amount);
    }
}