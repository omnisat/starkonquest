%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.models.common import Vector2, Dust, Cell, Context
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_nn_le

namespace grid:
    struct Grid:
        member cells : Cell*
        member size : felt
        member nb_cells : felt
    end

    # Create a new square grid of size*size cells stored in a single-dimension array
    # params:
    #   - grid_size: The number of rows/columns
    # returns:
    #   - grid: The created grid
    func create(size : felt) -> (grid : Grid):
        alloc_locals

        local grid : Grid
        assert grid.size = size
        assert grid.nb_cells = size * size
        let (new_cells : Cell*) = alloc()
        assert grid.cells = new_cells

        let empty_cell = Cell(Dust(FALSE, Vector2(0, 0)), 0)

        internal.init_grid_loop(grid, 0, empty_cell)

        return (grid=grid)
    end

    # Set a dust on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    #   - dust: The dust to set
    func set_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
        let (ship_id) = get_ship_at(x, y)
        return internal.set_cell_at(x, y, Cell(dust, ship_id))
    end

    # Get the dust on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    # Returns:
    #   - dust: The dust to set
    func get_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (dust : Dust):
        let (cell) = internal.get_cell_at(x, y)
        return (dust=cell.dust)
    end

    # Remove a dust on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    func clear_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt):
        let (ship_id) = get_ship_at(x, y)
        let NO_DUST = Dust(FALSE, Vector2(0, 0))
        return internal.set_cell_at(x, y, Cell(NO_DUST, ship_id))
    end

    # Set a ship on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    #   - ship_id: The ship to set
    func set_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt, ship_id : felt):
        let (dust) = get_dust_at(x, y)
        return internal.set_cell_at(x, y, Cell(dust, ship_id))
    end

    # Get the ship on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    # Returns:
    #   - ship_id: The ship to set
    func get_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (ship_id : felt):
        let (cell) = internal.get_cell_at(x, y)
        return (ship_id=cell.ship_id)
    end

    # Remove a ship on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    func clear_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt):
        let NO_SHIP = 0
        let (dust) = get_dust_at(x, y)
        return internal.set_cell_at(x, y, Cell(dust, NO_SHIP))
    end

    # func _get_grid_size{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }() -> (size : felt):
    #     return (context.grid_size)
    # end

    # func _get_ship_at{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }(x : felt, y : felt) -> (ship_id : felt):
    #     let (cell) = internal.get_cell_at(Context.grid, x, y)
    #     return (cell.ship_id)
    # end

    # func _get_next_turn_ship_at{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }(x : felt, y : felt) -> (ship_id : felt):
    #     let (cell) = _get_next_cell_at(x, y)
    #     return (cell.ship_id)
    # end

    # func _get_next_turn_dust_at{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }(x : felt, y : felt) -> (dust : Dust):
    #     let (cell) = _get_next_cell_at(x, y)
    #     return (dust=cell.dust)
    # end

    # func _set_ship_at{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }(x : felt, y : felt, ship_id : felt):
    #     internal.set_cell_at(x, y, Cell(Dust(FALSE, Vector2(0, 0)), ship_id))
    #     return ()
    # end

    # func _set_next_turn_ship_at{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }(x : felt, y : felt, ship_id : felt):
    #     _set_next_cell_at(x, y, Cell(Dust(FALSE, Vector2(0, 0)), ship_id))
    #     return ()
    # end

    # func _set_next_turn_dust_at{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }(x : felt, y : felt, dust : Dust):
    #     _set_next_cell_at(x, y, Cell(dust, 0))
    #     return ()
    # end

    # func _clear_next_turn_dust_at{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }(x : felt, y : felt):
    #     _set_next_cell_at(x, y, Cell(Dust(FALSE, Vector2(0, 0)), 0))
    #     return ()
    # end

    # func _get_grid_state{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }() -> (grid_state_len : felt, grid_state : Cell*):
    #     alloc_locals

    # let (local grid_state : Cell*) = alloc()

    # let (grid_state_len) = _rec_fill_grid_state(0, grid_state)

    # return (grid_state_len, grid_state)
    # end

    # func _rec_fill_grid_state{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }(grid_state_len : felt, grid_state : Cell*) -> (len : felt):
    #     let size = context.grid_size
    #     if size * size == grid_state_len:
    #         return (grid_state_len)
    #     end

    # let (y, x) = unsigned_div_rem(grid_state_len, size)
    #     let (cell) = _get_cell_at(x, y)

    # assert grid_state[grid_state_len] = Cell(cell.dust, cell.ship_id)
    #     return _rec_fill_grid_state(grid_state_len + 1, grid_state)
    # end

    # func _set_next_cell_at{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }(x : felt, y : felt, new_cell : Cell):
    #     alloc_locals
    #     let (index) = internal.to_grid_index(x, y)

    # local new_context : Context
    #     let next_grid : Cell* = alloc()
    #     assert new_context.grid_size = context.grid_size
    #     assert new_context.grid = context.grid
    #     assert new_context.next_grid = next_grid
    #     assert new_context.max_turn_count = context.max_turn_count
    #     assert new_context.max_dust = context.max_dust
    #     assert new_context.rand_contract = context.rand_contract
    #     assert new_context.ships_len = context.ships_len
    #     assert new_context.ships = context.ships

    # _get_updated_grid(
    #         new_context.grid_size * new_context.grid_size, new_context.next_grid, index, new_cell
    #     )
    #     let context = new_context
    #     return ()
    # end

    # func _get_next_cell_at{
    #     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : Context
    # }(x : felt, y : felt) -> (cell : Cell):
    #     # %{ print('Get next cell at({},{}) with grid size: {}'.format(ids.x, ids.y, ids.context.grid_size)) %}
    #     let (index) = internal.to_grid_index(x, y)
    #     # %{ print("Index: {}".format(ids.index)) %}
    #     let cell = [context.next_grid + index * Cell.SIZE]
    #     return (cell)
    # end

    # func _increment_ship_score{
    #     syscall_ptr : felt*,
    #     pedersen_ptr : HashBuiltin*,
    #     range_check_ptr,
    #     context : Context,
    #     scores : felt*,
    # }(ship_id : felt):
    #     alloc_locals

    # let (local new_scores : felt*) = alloc()
    #     _get_incremented_scores(context.ships_len, ship_id, new_scores)

    # let scores = new_scores
    #     return ()
    # end

    # func _get_incremented_scores{
    #     syscall_ptr : felt*,
    #     pedersen_ptr : HashBuiltin*,
    #     range_check_ptr,
    #     context : Context,
    #     scores : felt*,
    # }(ships_len : felt, ship_id : felt, new_scores : felt*):
    #     if ships_len == 0:
    #         return ()
    #     end

    # if ship_id == context.ships_len - ships_len + 1:
    #         assert [new_scores] = [scores + ship_id - 1] + 1
    #     else:
    #         assert [new_scores] = [scores + ship_id - 1]
    #     end

    # return _get_incremented_scores(ships_len - 1, ship_id, new_scores + 1)
    # end

    namespace internal:
        func init_grid_loop(grid : Grid, index : felt, init_cell : Cell):
            if index == grid.nb_cells:
                return ()
            end

            assert grid.cells[index] = init_cell
            init_grid_loop(grid, index + 1, init_cell)
            return ()
        end

        func to_grid_index{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (index : felt):
            let index = y * grid.size + x
            with_attr error_message("Out of bound"):
                assert_nn_le(index, grid.nb_cells)
            end

            return (index=index)
        end

        func get_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (cell : Cell):
            let (index) = to_grid_index(x, y)
            return (cell=grid.cells[index])
        end

        func set_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt, new_cell : Cell):
            alloc_locals
            let (new_cell_index) = to_grid_index(x, y)

            local new_grid : Grid
            assert new_grid.size = grid.size
            assert new_grid.nb_cells = grid.nb_cells

            let new_cells : Cell* = alloc()
            assert new_grid.cells = new_cells

            modify_grid_loop(new_grid, 0, new_cell_index, new_cell)

            let grid = new_grid
            return ()
        end

        func modify_grid_loop{grid : Grid}(
            new_grid : Grid, current_cell_index : felt, new_cell_index : felt, new_cell : Cell
        ):
            if current_cell_index == grid.nb_cells:
                return ()
            end

            if current_cell_index == new_cell_index:
                assert new_grid.cells[current_cell_index] = new_cell
            else:
                assert new_grid.cells[current_cell_index] = grid.cells[current_cell_index]
            end

            return modify_grid_loop(new_grid, current_cell_index + 1, new_cell_index, new_cell)
        end
    end
end