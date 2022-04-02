%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.math import assert_lt, assert_not_zero

from contracts.token.ERC20.IDTKERC20 import IDTKERC20

from contracts.token.ERC20.ERC20_base import (
    ERC20_name,
    ERC20_symbol,
    ERC20_totalSupply,
    ERC20_decimals,
    ERC20_balanceOf,
    ERC20_allowance,
    ERC20_mint,

    ERC20_initializer,
    ERC20_approve,
    ERC20_increaseAllowance,
    ERC20_decreaseAllowance,
    ERC20_transfer,
    ERC20_transferFrom
)

@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_dummy_token_address: felt):
    dummy_token_address_storage.write(_dummy_token_address)
    return ()
end

#########################################################
############### storage variables #######################
#########################################################

@storage_var
func account_balance(account: felt) -> (balance: Uint256):
end

@storage_var
func dummy_token_address_storage() -> (dummy_token_address_storage: felt):
end

@storage_var
func EST_token_address_storage() -> (account: felt):
end

#########################################################
############### view functions ##########################
#########################################################

@view
func tokens_in_custody{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account : felt) -> (amount : Uint256):
    return account_balance.read(account)
end

@view
func deposit_tracker_token{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (deposit_tracker_token_address : felt):
    let (deposit_tracker_token_address : felt) = EST_token_address_storage.read()
    return (deposit_tracker_token_address)

end

#########################################################
########### internal functions ##########################
#########################################################

# func increase_account_balance{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     }(amount: Uint256) -> ():

# end

#########################################################
########### external functions ##########################
#########################################################

@external
func deposit_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(amount : Uint256) -> (total_amount : Uint256):
    let EST_token_address = deposit_tracker_token
    let (caller) = get_caller_address()
    let (read_dtk_address) = dummy_token_address_storage.read()
    let (contract_address) = get_contract_address()
    # sth is wrong with this
    IDTKERC20.mint(EST_token_address, caller, amount)
    IDTKERC20.transferFrom(read_dtk_address, caller, contract_address, amount)
    let (current_amount: Uint256) = account_balance.read(caller)
    let (total_amount, _) = uint256_add(current_amount, amount)
    account_balance.write(caller, total_amount)
    return (amount)
end

@external
func get_tokens_from_contract{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (amount : Uint256):
    let (caller) = get_caller_address()
    let balance: Uint256 = account_balance.read(caller)
    let (read_dtk_address) = dummy_token_address_storage.read()

    IDTKERC20.faucet(read_dtk_address)
    let amount: felt = balance.low
    let faucet_amount: felt = 100*1000000000000000000
    let amt: Uint256 = Uint256(amount + faucet_amount, 0)
    account_balance.write(caller, amt)
    return (amt)
end

@external
func withdraw_all_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
        }() -> (amount : Uint256):
    #Evaluator needs to go up by the same amount that ExerciseSolution goes down
    let (read_dtk_address) = dummy_token_address_storage.read()
    let (evaluator_address) = get_caller_address()
    let (exercise_solution_address) = get_contract_address()
    let all_tokens: Uint256 = IDTKERC20.balanceOf(read_dtk_address, exercise_solution_address)
    IDTKERC20.transfer(read_dtk_address, evaluator_address, all_tokens)
    return (all_tokens)
end

@external
func set_deposit_tracker_token{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(deposit_tracker_token_address: felt) -> ():
    EST_token_address_storage.write(deposit_tracker_token_address)
    return ()
end