################### BATTLESHIP GAME ÇALIÞIYOR #############################
.data

# --- Prompts and Messages ---##
prompt_row:         .asciiz "Enter the row (0-4): "
prompt_col:         .asciiz "Enter the column (0-4): "
prompt_player_ship_row: .asciiz "Enter row for your ship (0-4): "
prompt_player_ship_col: .asciiz "Enter column for your ship (0-4): "
already_placed_msg: .asciiz "Ship already placed at this location. Try again.\n"
player_turn_msg:    .asciiz "\nYour Turn:\n"
ai_turn_msg:        .asciiz "\nAI's Turn:\n"
ai_guess_msg:       .asciiz "AI guesses row: "
ai_guess_col_msg:   .asciiz ", col: "
ai_hit_msg:         .asciiz "AI Hit!\n"
ai_miss_msg:        .asciiz "AI Miss!\n"
player_wins_msg:    .asciiz "Congratulations! You sank all AI ships!\n"
ai_wins_msg:        .asciiz "AI wins! All your ships have been sunk.\n"
hit_msg:            .asciiz "Hit!\n"
miss_msg:           .asciiz "Miss!\n"
error_msg:          .asciiz "Invalid input. Enter between 0-4.\n"
already_msg:        .asciiz "Already guessed this square.\n"

# - FOR TESTING MESSAGES ---
debug_ai_ship_intro_msg: .asciiz "\n--- AI Ship Locations (for testing) ---\n"
debug_ai_ship_loc_msg:   .asciiz "AI Ship "
debug_ai_ship_row_msg:   .asciiz " at (Row: "
debug_ai_ship_col_msg:   .asciiz ", Col: "
debug_ai_ship_end_msg:   .asciiz ")\n"
debug_ai_ship_outro_msg: .asciiz "---------------------------------------\n"

# --- Game Configuration -------
num_ships:      .word 3

# --- Player Data ---
player_ship_rows: .word 0, 0, 0
player_ship_cols: .word 0, 0, 0
player_hit_flags: .word 0, 0, 0
player_score:   .word 0
player_guess_grid: .word 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0

# --- AI Data ---
ai_ship_rows:     .word 0, 0, 0
ai_ship_cols:     .word 0, 0, 0
ai_hit_flags:     .word 0, 0, 0
ai_score:         .word 0
ai_guess_grid:    .word 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0

.text
.globl main
main:
    jal init_constants
    jal draw_grid

    jal player_place_ships
    jal ai_place_ships
    jal debug_show_ai_ships ##eðer testi kaldýracaksan bunu yorum yap

game_loop_main:
    jal player_turn
    jal check_winner  # If winner, jumps to end_game

    jal ai_turn
    jal check_winner  # If winner, jumps to end_game

    j game_loop_main  # Loop if no winner yet

end_game:
    li  $v0, 10       # Exit program
    syscall

# ------------------------------------------------------------
# init_constants: Set up global constants.
# Globals (in $s registers):
# $s0: grid_offset_x
# $s1: grid_offset_y
# $s2: cell_size (100)
# $s3: white_color
# $s4: red_color (HIT)
# $s5: blue_color (MISS)
# $s6: display_width (512)
# $s7: display_height (512)
# ------------------------------------------------------------
init_constants:
    li   $s2, 100           # cell_size
    li   $t0, 5             # grid_dimension (5x5 cells)
    mul  $t1, $t0, $s2      # total_grid_pixel_width/height

    	li   $s6, 512           # display_width
    	li   $s7, 512           # display_height

    		sub  $t2, $s6, $t1
    		sra  $s0, $t2, 1        # $s0 = grid_offset_x
    		sub  $t2, $s7, $t1
    		sra  $s1, $t2, 1        # $s1 = grid_offset_y

    li   $s3, 0x00FFFFFF    # white_color
    li   $s4, 0x00FF0000    # red_color
    li   $s5, 0x000000FF    # blue_color

    # --- Improved Random Seeding ---
    li   $v0, 30            # Syscall for Time
    syscall                 #(the seed)

   	 move $t0, $a0           # Store the seed from $a0 into a temporary $t0
    
    li   $a0, 0             # Random generator ID (0 for default)
    move $a1, $t0           # Move the seed (time) into $a1 (argument for seed value)
    li   $v0, 40            # Syscall for set random seed
    syscall
    # --- End of Improved Random Seeding ---

    		jr   $ra

# ------------------------------------------------------------
# draw_grid: Draws the 5x5 grid lines.
# $s0-$s3. Temporaries: $t0-$t9.
# ------------------------------------------------------------
draw_grid:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t0, 5             # Grid dimension (5 cells)
    addi $t1, $t0, 1        # Loop limit for lines (6 lines for 5 cells)
    li   $t2, 0             # Loop counter for lines

    lui  $t7, 0x1001        # Base address of bitmap display
    ori  $t7, $t7, 0x0000

vline_loop: # Draw vertical lines
    	beq  $t2, $t1, hline_start

    mul  $a0, $t2, $s2      # current_x_offset = line_index * cell_size ($s2)
    add  $a0, $a0, $s0      # x_coord_of_line = grid_offset_x ($s0) + current_x_offset
    move $a1, $s1           # y_start_coord = grid_offset_y ($s1)
    mul  $t3, $t0, $s2      # total_grid_height_pixels = grid_dim * cell_size
    add  $a2, $t3, $s1      # y_end_coord = grid_offset_y + total_grid_height_pixels



draw_vline_pixel:
    beq  $a1, $a2, vline_next_line
    sll  $a3, $a1, 9
    add  $a3, $a3, $a0
    sll  $a3, $a3, 2
    add  $a3, $a3, $t7
    sw   $s3, 0($a3)        # Draw pixel with white_color ($s3)
    addi $a1, $a1, 1
    j    draw_vline_pixel
    
    
vline_next_line:
    addi $t2, $t2, 1
    j    vline_loop



hline_start: # Draw horizontal lines
    li   $t2, 0             # Reset loop counter
    
    
hline_loop:
    beq  $t2, $t1, grid_drawing_done
    mul  $a0, $t2, $s2
    add  $a0, $a0, $s1
    move $a1, $s0
    mul  $t3, $t0, $s2
    add  $a2, $t3, $s0

draw_hline_pixel:
    beq  $a1, $a2, hline_next_line
    sll  $a3, $a0, 9
    add  $a3, $a3, $a1
    sll  $a3, $a3, 2
    add  $a3, $a3, $t7
    sw   $s3, 0($a3)
    addi $a1, $a1, 1
    j    draw_hline_pixel
hline_next_line:
    addi $t2, $t2, 1
    j    hline_loop

grid_drawing_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


# player_place_ships: Player inputs ship locations.
# Temporaries: $t0-$t7. Stack for $ra.
######################################################
player_place_ships:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # $t0: ship_idx (current ship being placed)
     # $t1: input_row
     # $t2: input_col
     # $t3: conflict_loop_idx
     # $t4: loaded existing_row
     # $t5: loaded existing_col / temp base address
     # $t6: num_ships_to_place
      # $t7: temp for offset calculation

    lw   $t6, num_ships
    li   $t0, 0

place_player_ship_loop:
    beq  $t0, $t6, player_ships_all_placed

get_player_ship_input:
    li   $v0, 4
    la   $a0, prompt_player_ship_row
    	syscall
    li   $v0, 5
    	syscall
    move $t1, $v0

    blt  $t1, 0, player_place_input_error
    bgt  $t1, 4, player_place_input_error

    li   $v0, 4
    la   $a0, prompt_player_ship_col
    	syscall
    li   $v0, 5
    	syscall
    move $t2, $v0

    blt  $t2, 0, player_place_input_error
    bgt  $t2, 4, player_place_input_error

    li   $t3, 0           # conflict_loop_idx = 0
    
    
   
check_player_ship_conflict_loop:
    beq  $t3, $t0, player_ship_no_conflict # If conflict_loop_idx == ship_idx, checked all previous ships

    sll  $t7, $t3, 2      # $t7 = offset = conflict_loop_idx * 4
    la   $t5, player_ship_rows
    add  $t5, $t5, $t7
    lw   $t4, 0($t5)      # $t4 = existing_row

    la   $t5, player_ship_cols # $t5 base address for cols
    add  $t5, $t5, $t7    # Add same offset
    lw   $t5, 0($t5)      # $t5 now holds existing_col

    bne  $t1, $t4, next_player_ship_to_check_internal # if input_row != existing_row
    bne  $t2, $t5, next_player_ship_to_check_internal # if input_col != existing_col
    # Conflict found if both are equal
    j    player_ship_conflict_is_found

next_player_ship_to_check_internal:
    addi $t3, $t3, 1
    j    check_player_ship_conflict_loop

player_ship_conflict_is_found:
    li   $v0, 4
    la   $a0, already_placed_msg
    syscall
    j    get_player_ship_input

player_place_input_error:
    li   $v0, 4
    la   $a0, error_msg
    syscall
    j    get_player_ship_input

player_ship_no_conflict:
    sll  $t7, $t0, 2      # $t7 = offset for current ship_idx
    la   $t5, player_ship_rows
    add  $t5, $t5, $t7
    sw   $t1, 0($t5)      # player_ship_rows[ship_idx] = input_row

    la   $t5, player_ship_cols
    add  $t5, $t5, $t7    # Re-use offset for cols array
    sw   $t2, 0($t5)      # player_ship_cols[ship_idx] = input_col

    addi $t0, $t0, 1      # Increment ship_idx
    j    place_player_ship_loop

player_ships_all_placed:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


# ai_place_ships: AI randomly places its ships.
# Temporaries: $t0-$t9. Stack for $ra.
#################################################3
ai_place_ships:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # $t0: ai_ship_idx
    # $t1: rand_row
    # $t2: rand_col
    # $t3: conflict_idx
    # $t4: conflict_flag (0 or 1)
    # $t5: current_offset (for row/col arrays based on $t3)
    # $t6: num_ships_to_place
    # $t7: existing_row_val
    # $t8: existing_col_val
    # $t9: Array base address temp

    lw   $t6, num_ships
    li   $t0, 0           # ai_ship_idx = 0

ai_place_one_ship_loop:
    beq  $t0, $t6, ai_ships_all_placed # If ai_ship_idx == num_ships_to_place

generate_ai_coords:
    li   $v0, 42
    li   $a0, 0           # Default random generator
    li   $a1, 5           # Range [0, 5-1] -> 0-4
    	syscall
    move $t1, $a0         # $t1 = rand_row

    li   $v0, 42
    li   $a0, 0
    li   $a1, 5
    	syscall
    move $t2, $a0         # $t2 = rand_col

    li   $t3, 0           # conflict_idx = 0
    li   $t4, 0           # conflict_flag = 0 (0 = no conflict, 1 = conflict)
ai_check_conflict_loop_internal:
    beq  $t3, $t0, ai_no_conflict_decision # If conflict_idx == ai_ship_idx, checked all previous ships

    sll  $t5, $t3, 2      # $t5 = current_offset = conflict_idx * 4

    la   $t9, ai_ship_rows  # $t9 = base address of ai_ship_rows
    add  $t9, $t9, $t5    # address of ai_ship_rows[conflict_idx]
    lw   $t7, 0($t9)      # $t7 = existing_row_val

    la   $t9, ai_ship_cols  # $t9 = base address of ai_ship_cols
    add  $t9, $t9, $t5    # address of ai_ship_cols[conflict_idx] (reuse $t5 offset)
    lw   $t8, 0($t9)      # $t8 = existing_col_val

    bne  $t1, $t7, ai_inc_conflict_check_internal # If rand_row ($t1) != existing_row_val ($t7)
    bne  $t2, $t8, ai_inc_conflict_check_internal # If rand_col ($t2) != existing_col_val ($t8)
    # Conflict found if both are equal####!!!
    li   $t4, 1           # Set conflict_flag ($t4) = 1
    j    ai_no_conflict_decision # Go to decision directly if conflict found

ai_inc_conflict_check_internal:
    addi $t3, $t3, 1
    j    ai_check_conflict_loop_internal

ai_no_conflict_decision:
    bne  $t4, $zero, generate_ai_coords # If conflict_flag is 1, retry generating coordinates

    # Store the valid ship location for AI
    sll  $t5, $t0, 2      # $t5 = offset for current ai_ship_idx
    la   $t9, ai_ship_rows
    add  $t9, $t9, $t5
    sw   $t1, 0($t9)      # ai_ship_rows[ai_ship_idx] = rand_row

    la   $t9, ai_ship_cols
    add  $t9, $t9, $t5    # Re-use offset
    sw   $t2, 0($t9)      # ai_ship_cols[ai_ship_idx] = rand_col

    addi $t0, $t0, 1      # Increment ai_ship_idx
    j    ai_place_one_ship_loop

ai_ships_all_placed:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


#################FOR TEST###################3
debug_show_ai_ships:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # $t0: loop counter (ship_index)
    # $t1: num_ships
    # $t2: base address of ai_ship_rows
    # $t3: base address of ai_ship_cols
    # $t4: current ship row
    # $t5: current ship col
    # $t6: offset

    # Print intro message
    li   $v0, 4
    la   $a0, debug_ai_ship_intro_msg
    syscall

    lw   $t1, num_ships
    la   $t2, ai_ship_rows
    la   $t3, ai_ship_cols
    li   $t0, 0                  # ship_index = 0

debug_show_loop:
    beq  $t0, $t1, debug_show_done # If ship_index == num_ships, exit loop

    # Print "AI Ship "
    li   $v0, 4
    la   $a0, debug_ai_ship_loc_msg
    	syscall

    # Print ship_index + 1 (for 1-based display)
    li   $v0, 1
    addi $a0, $t0, 1
    	syscall

    # Print " at (Row: "
    li   $v0, 4
    la   $a0, debug_ai_ship_row_msg
    	syscall

    # Load and print AI ship row
       sll  $t6, $t0, 2             # offset = ship_index * 4
      add  $t6, $t2, $t6           # address of ai_ship_rows[ship_index]
     lw   $t4, 0($t6)             # $t4 = ai_ship_rows[ship_index]
     li   $v0, 1
     move $a0, $t4
    	syscall

    # Print ", Col: "
    li   $v0, 4
    la   $a0, debug_ai_ship_col_msg
    syscall

    # Load and print AI ship col
    	sll  $t6, $t0, 2             # offset = ship_index * 4 (can reuse or recalc)
     add  $t6, $t3, $t6           # address of ai_ship_cols[ship_index]
     lw   $t5, 0($t6)             # $t5 = ai_ship_cols[ship_index]
     li   $v0, 1
     move $a0, $t5
     syscall

    # Print ")\n"
    li   $v0, 4
    la   $a0, debug_ai_ship_end_msg
    syscall

    addi $t0, $t0, 1             # Next ship
    j    debug_show_loop

debug_show_done:
    # Print outro message
    li   $v0, 4
    la   $a0, debug_ai_ship_outro_msg
    syscall

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ------------------------------------------------------------
# player_turn: Player inputs guess, attacks AI ships.
# Uses globals $s0-$s5 for drawing. Temporaries $t0-$t9.
##########################################################
player_turn:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # $t0: guess_row
    # $t1: guess_col
    # $t2: loop_idx (for checking AI ships)
    # $t3: hit_this_turn_flag (0 or 1)
    # $t4: temp for AI ship row / address of ai_hit_flags[idx] / address of player_score
    # $t5: temp for AI ship col / value of ai_hit_flags[idx] / address of player_guess_grid[idx] / value of score
    # $t6: num_total_ships
    # $t7: temp for value of player_guess_grid[idx] / offset for ai_ship_cols
    # $t8, $t9 used by draw_cell (passed by caller)

    li   $v0, 4
    la   $a0, player_turn_msg
    	syscall

player_get_guess_input_loop:
    li   $v0, 4
    la   $a0, prompt_row
    	syscall
    li   $v0, 5
    	syscall
    move $t0, $v0         # $t0 = guess_row

    blt  $t0, 0, player_turn_input_err_rpt
    bgt  $t0, 4, player_turn_input_err_rpt

    li   $v0, 4
    la   $a0, prompt_col
 	  syscall
    li   $v0, 5
   	 syscall
    move $t1, $v0         # $t1 = guess_col

    blt  $t1, 0, player_turn_input_err_rpt
    bgt  $t1, 4, player_turn_input_err_rpt

    # Check player_guess_grid
    move $t4, $t0         # row
    li   $t5, 5
    mul  $t4, $t4, $t5      # row * 5
    add  $t4, $t4, $t1      # row * 5 + col
    sll  $t4, $t4, 2      # word offset for player_guess_grid
    la   $t5, player_guess_grid
    add  $t5, $t5, $t4      # $t5 = address of player_guess_grid[row][col]
    lw   $t7, 0($t5)        # $t7 = player_guess_grid[row][col] value
    bne  $t7, $zero, player_already_guessed_this_sq # If not 0, square already guessed

    # Mark this square as guessed by player
    li   $t7, 1
    sw   $t7, 0($t5)        # player_guess_grid[row][col] = 1

    lw   $t6, num_ships     # $t6 = num_total_ships
    li   $t2, 0           # loop_idx = 0 for AI ships
    li   $t3, 0           # hit_this_turn_flag = 0 (0=miss, 1=hit)

player_check_ai_ship_loop_internal:
    beq  $t2, $t6, player_turn_after_checking_ai_ships # If loop_idx == num_ships, checked all

    sll  $t4, $t2, 2      # $t4 = offset for current AI ship
    la   $t5, ai_ship_rows
    add  $t5, $t5, $t4
    lw   $t4, 0($t5)      # $t4 = ai_ship_rows[loop_idx]

    la   $t5, ai_ship_cols
    sll  $t7, $t2, 2      # $t7 = offset for current AI ship (recalc for clarity or use $t4 if sure)
    add  $t5, $t5, $t7
    lw   $t7, 0($t5)      # $t7 = ai_ship_cols[loop_idx]

    bne  $t0, $t4, player_skip_this_ai_ship_check # if guess_row != ai_ship_row
    bne  $t1, $t7, player_skip_this_ai_ship_check # if guess_col != ai_ship_col

    # ---- HIT on AI ship #######
    li   $v0, 4
    la   $a0, hit_msg
    syscall

    addi $sp, $sp, -4
    sw   $t2, 0($sp)
    
    # draw_cell($a0=row, $a1=col, $a2=color, $a3=cell_size, $t8=grid_base_x, $t9=grid_base_y)
    move $a0, $t0         # guess_row
    move $a1, $t1         # guess_col
    move $a2, $s4         # red_color (global $s4)
    move $a3, $s2         # cell_size (global $s2)
    move $t8, $s0         # grid_offset_x (global $s0)
    move $t9, $s1         # grid_offset_y (global $s1)

    jal  draw_cell
    
    lw   $t2, 0($sp)
    addi $sp, $sp, 4

    li   $t3, 1           # hit_this_turn_flag = 1

    # Check if this specific AI ship part was already hit (to avoid double scoring)
    la   $t4, ai_hit_flags  # Base of ai_hit_flags
    sll  $t5, $t2, 2      # offset for current ship (loop_idx)
    add  $t4, $t4, $t5      # Address of ai_hit_flags[loop_idx]
    lw   $t5, 0($t4)      # Current value of ai_hit_flags[loop_idx]
    beq  $t5, 1, player_turn_after_checking_ai_ships # Already hit & scored this specific ship part

    # Mark this AI ship part as hit and increment player score
    li   $t5, 1
    sw   $t5, 0($t4)      # ai_hit_flags[loop_idx] = 1

    la   $t4, player_score
    lw   $t5, 0($t4)
    addi $t5, $t5, 1
    sw   $t5, 0($t4)      # player_score++

    j    player_turn_after_checking_ai_ships # Hit processed, exit loop for this guess

player_skip_this_ai_ship_check:
    addi $t2, $t2, 1      # Next AI ship
    j    player_check_ai_ship_loop_internal

player_turn_after_checking_ai_ships:
    beq  $t3, 1, player_turn_is_done # If hit_this_turn_flag is 1 (was a hit), skip MISS

    # ---- MISS ----
    li   $v0, 4
    la   $a0, miss_msg
    	syscall

    move $a0, $t0
    move $a1, $t1
    move $a2, $s5         # blue_color (global $s5)
    move $a3, $s2
    move $t8, $s0
    move $t9, $s1
    jal  draw_cell

player_turn_is_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

player_turn_input_err_rpt:
    li   $v0, 4
    la   $a0, error_msg
    	syscall
    j    player_get_guess_input_loop

player_already_guessed_this_sq:
    li   $v0, 4
    la   $a0, already_msg
    syscall
    j    player_get_guess_input_loop


# ai_turn: AI makes a random guess.
# Temporaries $t0-$t9.
#################################################
ai_turn:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # $t0: ai_guess_row
    # $t1: ai_guess_col
    # $t2: loop_idx (for player ships)
    # $t3: hit_this_turn_flag
    # $t4: temp for player ship row / address of player_hit_flags[idx] / address of ai_score
    # $t5: temp for player ship col / value of player_hit_flags[idx] / address of ai_guess_grid[idx] / value of score
    # $t6: num_total_ships
    # $t7: temp for value of ai_guess_grid[idx] / offset for player_ship_cols

    li   $v0, 4
    la   $a0, ai_turn_msg
    syscall

ai_generate_random_guess_loop:
    li   $v0, 42
    li   $a0, 0
    li   $a1, 5
    	syscall
    move $t0, $a0         # $t0 = ai_guess_row

    li   $v0, 42
    li   $a0, 0
    li   $a1, 5
    	syscall
    move $t1, $a0         # $t1 = ai_guess_col

    # Check ai_guess_grid
    move $t4, $t0         # row
    li   $t5, 5
    mul  $t4, $t4, $t5      # row * 5
    add  $t4, $t4, $t1      # row * 5 + col
    sll  $t4, $t4, 2      # word offset
    la   $t5, ai_guess_grid
    add  $t5, $t5, $t4      # $t5 = address of ai_guess_grid[row][col]
    lw   $t7, 0($t5)        # $t7 = ai_guess_grid[row][col] value
    bne  $t7, $zero, ai_generate_random_guess_loop # If not 0, AI already guessed here, try again

    # Mark this square as guessed by AI
    li   $t7, 1
    sw   $t7, 0($t5)        # ai_guess_grid[row][col] = 1

    # Print AI's guess
    li   $v0, 4
    la   $a0, ai_guess_msg
    syscall
    li   $v0, 1
    move $a0, $t0
    syscall
    li   $v0, 4
    la   $a0, ai_guess_col_msg
    syscall
    li   $v0, 1
    move $a0, $t1
    syscall
    li   $v0, 11
    li   $a0, '\n'
    syscall

    lw   $t6, num_ships
    li   $t2, 0           # loop_idx for player ships
    li   $t3, 0           # hit_this_turn_flag

ai_check_player_ship_loop_internal:
    beq  $t2, $t6, ai_turn_after_checking_player_ships

    sll  $t4, $t2, 2
    la   $t5, player_ship_rows
    add  $t5, $t5, $t4
    lw   $t4, 0($t5)      # $t4 = player_ship_rows[loop_idx]

    la   $t5, player_ship_cols
    sll  $t7, $t2, 2
    add  $t5, $t5, $t7
    lw   $t7, 0($t5)      # $t7 = player_ship_cols[loop_idx]

    bne  $t0, $t4, ai_skip_this_player_ship_check
    bne  $t1, $t7, ai_skip_this_player_ship_check

    # ---- AI HIT on Player's ship ----
    li   $v0, 4
    la   $a0, ai_hit_msg
    syscall
    li   $t3, 1           # hit_this_turn_flag = 1

    # Check if this specific player ship part was already hit
    la   $t4, player_hit_flags
    sll  $t5, $t2, 2
    add  $t4, $t4, $t5    # Address of player_hit_flags[loop_idx]
    lw   $t5, 0($t4)      # Current value of player_hit_flags[loop_idx]
    beq  $t5, 1, ai_turn_after_checking_player_ships # Already hit & scored

    # Mark this player ship part as hit and increment AI score
    li   $t5, 1
    sw   $t5, 0($t4)      # player_hit_flags[loop_idx] = 1

    la   $t4, ai_score
    lw   $t5, 0($t4)
    addi $t5, $t5, 1
    sw   $t5, 0($t4)      # ai_score++
    j    ai_turn_after_checking_player_ships # Hit processed

ai_skip_this_player_ship_check:
    addi $t2, $t2, 1
    j    ai_check_player_ship_loop_internal

ai_turn_after_checking_player_ships:
    beq  $t3, 1, ai_turn_is_done # If it was a hit, skip miss message

    # ---- AI MISS ----
    li   $v0, 4
    la   $a0, ai_miss_msg
    syscall

ai_turn_is_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ------------------------------------------------------------
# check_winner: Checks if player or AI has won.
# Temporaries $t0, $t1. ÇALISIYOR ARTIK
# ------------------------------------------------------------
check_winner:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    lw   $t0, player_score
    lw   $t1, num_ships
    beq  $t0, $t1, player_has_won_game # If player_score == num_ships

    lw   $t0, ai_score
    # $t1 still holds num_ships from previous load
    beq  $t0, $t1, ai_has_won_game   # If ai_score == num_ships

    # No winner yet, continue game
    j    no_winner_yet_continue

player_has_won_game:
    li   $v0, 4
    la   $a0, player_wins_msg
    syscall
    j    end_game # Game over, player wins

ai_has_won_game:
    li   $v0, 4
    la   $a0, ai_wins_msg
    syscall
    j    end_game # Game over, AI wins

no_winner_yet_continue:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra           # Return to caller (main game loop)

# ------------------------------------------------------------
# draw_cell: Fills a single cell of the grid.
# Args: $a0=row, $a1=col, $a2=color, $a3=cell_size
#       $t8=grid_base_x, $t9=grid_base_y (passed by caller)
# Uses $t0-$t7 internally as temps.
################################################################
draw_cell:
    # No stack frame needed as it's a leaf function using only $t regs/args

    lui  $t7, 0x1001        # $t7 = Bitmap base address
    ori  $t7, $t7, 0x0000

    # Calculate top-left screen coordinates of the cell to be drawn
    # $t0 = cell_start_x_on_screen
    # $t1 = cell_start_y_on_screen
    mul  $t0, $a1, $a3      # cell_offset_x = col_index * cell_size
    add  $t0, $t0, $t8      # cell_start_x_on_screen = grid_base_x + cell_offset_x

    mul  $t1, $a0, $a3      # cell_offset_y = row_index * cell_size
    add  $t1, $t1, $t9      # cell_start_y_on_screen = grid_base_y + cell_offset_y

    li   $t2, 0             # $t2 = row_pixel_counter for the cell
dc_row_loop: # Loop for each row of pixels within the cell
    beq  $t2, $a3, dc_cell_drawing_done # If drawn all rows in cell (cell_size is $a3)

    add  $t3, $t1, $t2      # $t3 = current_y_pixel_on_screen (cell_start_y + row_px_count)

    li   $t4, 0             # $t4 = col_pixel_counter for the cell
dc_col_loop: # Loop for each column of pixels within the cell
    beq  $t4, $a3, dc_next_row_in_cell # If drawn all columns in this row of cell

    add  $t5, $t0, $t4      # $t5 = current_x_pixel_on_screen (cell_start_x + col_px_count)

    # Calculate memory address for the current pixel
    # $t6 = final_pixel_address
    sll  $t6, $t3, 9      # mem_addr = current_y_px * 512 (assuming display width 512)
    add  $t6, $t6, $t5      # mem_addr += current_x_px
    sll  $t6, $t6, 2      # mem_addr *= 4 (word addressing)
    add  $t6, $t6, $t7      # final_pixel_address += bitmap_base_address

    sw   $a2, 0($t6)        # Draw the pixel with the given color ($a2)

    addi $t4, $t4, 1      # Next pixel in column
    j    dc_col_loop
dc_next_row_in_cell:
    addi $t2, $t2, 1      # Next row in cell
    j    dc_row_loop
dc_cell_drawing_done:
    			jr   $ra
