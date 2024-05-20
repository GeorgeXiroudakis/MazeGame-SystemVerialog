/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2024/XX/XX
 * Author: George Xiroudakis
 * Filename: maze_controller.sv
 * Description: Your description here
 *
 ******************************************************************************/

module maze_controller #(
     parameter int CLOCK_FREQ_HZ = 25_000_000,  //clock speed nedded to keep track of time
     
     parameter int maze_rom_row_size = 64,
     parameter int NUM_OF_CYCLES_FOR_2_SECS = (2 * CLOCK_FREQ_HZ)
)(
  input  logic clk,
  input  logic rst,

  input  logic i_control,
  input  logic i_up,
  input  logic i_down,
  input  logic i_left,
  input  logic i_right,

  output logic        o_rom_en,
  output logic [10:0] o_rom_addr,
  input  logic [15:0] i_rom_data,

  output logic [5:0] o_player_bcol,
  output logic [5:0] o_player_brow,

  input  logic [5:0] i_exit_bcol,
  input  logic [5:0] i_exit_brow,

  output logic [7:0] o_leds,
  
  output logic [5:0] o_two_seconds_intervals   //it will only go up to 40 (2*40 = 80 secs)
);





typedef enum logic [3:0]{ 
    IDLE,
    START_SEQUENCE_1, START_SEQUENCE_2,
    PLAY,
    UP, DOWN, LEFT, RIGHT,
    READROM,
    CHECK,
    UPDATE,
    END_S
}state_t;
state_t current_state, next_state;

logic [5:0] next_player_bcol;
logic [5:0] next_player_brow;

logic [5:0] new_bcol_r;
logic [5:0] new_brow_r;

logic [5:0] new_bcol;
logic [5:0] new_brow;

logic only_control_pressed;
logic any_other_ex_control_pressed;
logic only_up_pressed;
logic only_down_pressed;
logic only_right_pressed;
logic only_left_pressed;
logic player_reahced_end;
logic game_is_running;

logic [2:0] player_reset_count_r;
logic [2:0] player_reset_count;

logic [$clog2(NUM_OF_CYCLES_FOR_2_SECS)-1:0] clocks_couter;
logic [$clog2(NUM_OF_CYCLES_FOR_2_SECS)-1:0] clocks_couter_next;
logic [5:0] nexttwo_seconds_intervals;


always_ff @( posedge clk) begin

    if ( rst ) begin
        current_state <= IDLE;
        
        o_player_bcol <= 1;
        o_player_brow <= 1;
        
        new_bcol_r <= 1;
        new_brow_r <= 1;
        
        o_leds <= 0;
        
        player_reset_count_r <= 0;
        
        o_two_seconds_intervals <= 0;
        clocks_couter <= 0;
    end
    else begin
        current_state <= next_state;
        
        o_player_bcol <= next_player_bcol;
        o_player_brow <= next_player_brow;

        new_bcol_r <= new_bcol;
        new_brow_r <= new_brow;
        
        player_reset_count_r <= player_reset_count;
        
        o_leds <= next_state;
        
        o_two_seconds_intervals <= nexttwo_seconds_intervals;
        clocks_couter <= clocks_couter_next;
        
   end
   
end


always_comb begin
    next_state = current_state;
    
    next_player_bcol = o_player_bcol;
    next_player_brow = o_player_brow;
    
    new_bcol = new_bcol_r;
    new_brow = new_brow_r;
    
    player_reset_count = player_reset_count_r;
    
    nexttwo_seconds_intervals = o_two_seconds_intervals;
    clocks_couter_next = clocks_couter;
    
    o_rom_addr = 0;
    
    only_control_pressed = i_control && ~i_up && ~i_down && ~i_left && ~i_right;
    any_other_ex_control_pressed = i_up || i_down || i_left || i_left;
    only_up_pressed = i_up && ~i_down && ~i_left && ~i_right;
    only_down_pressed = ~i_up && i_down && ~i_left && ~i_right;
    only_left_pressed = ~i_up && ~i_down && i_left && ~i_right;
    only_right_pressed = ~i_up && ~i_down && ~i_left && i_right;
    player_reahced_end = (o_player_bcol == i_exit_bcol) && (o_player_brow == i_exit_brow);
    game_is_running = current_state != IDLE && current_state != START_SEQUENCE_1 && current_state !=  START_SEQUENCE_2 && current_state != END_S;
    

    case(current_state)
        
        //start condition
        IDLE: begin
            //reset players possition
            next_player_bcol = 1;
            next_player_brow = 0;
            
            //reset time couters
            nexttwo_seconds_intervals = 0;
            clocks_couter_next = 0;
            
            
            if(only_control_pressed) 
                next_state = START_SEQUENCE_1;        
            else if (any_other_ex_control_pressed) 
                next_state = IDLE;
        end
        
        START_SEQUENCE_1: begin
            if(only_control_pressed) 
                next_state = START_SEQUENCE_2;
            else if (any_other_ex_control_pressed) 
                next_state = IDLE; 
        end
        
        START_SEQUENCE_2: begin
             if(only_control_pressed) 
                next_state = PLAY;
             else if (any_other_ex_control_pressed) 
                next_state = IDLE;
        end
        
        PLAY: begin
               //check if the player has reached the end
               if(player_reahced_end)
                    next_state = END_S;
               
               //cheack/update the player reset counter (when he presses control 6 time it resets the game)
               else if(player_reset_count == 6) begin
                    player_reset_count = 0;
                    next_state = IDLE; 
               end
               
               else begin
                    if(only_control_pressed)
                        player_reset_count++;
                    
                    else if(any_other_ex_control_pressed)
                        player_reset_count = 0;
                    
                   //check the movement
                   if(only_up_pressed) next_state = UP;
                   else if(only_down_pressed) next_state = DOWN;
                   else if(only_left_pressed) next_state = LEFT;
                   else if(only_right_pressed) next_state = RIGHT;
              end
        end
        
        
        UP: begin
             if(o_player_brow > 0)
                new_brow = o_player_brow - 1;
             else 
                new_brow = o_player_brow;
                
             new_bcol = o_player_bcol;
                
             next_state = READROM;
        end
       
        DOWN: begin
             if(o_player_brow < 29)
                new_brow = o_player_brow + 1;
             else 
                new_brow = o_player_brow;
                
             new_bcol = o_player_bcol;
             
             next_state = READROM;
        end
       
        LEFT: begin
             if(o_player_bcol > 0)
                new_bcol = o_player_bcol - 1;
             else
                new_bcol = o_player_bcol;
                
             new_brow = o_player_brow;
             
             next_state = READROM;
        end
       
        RIGHT: begin
             if(o_player_bcol < 39)
                new_bcol = o_player_bcol + 1;
             else
                new_bcol = o_player_bcol;
                
             new_brow = o_player_brow;
             
             next_state = READROM;
        end
        
        
        READROM: begin 
              o_rom_en = 1;
              o_rom_addr = ( (new_brow_r * maze_rom_row_size) + new_bcol_r );
              new_bcol = new_bcol_r;
              new_brow = new_brow_r;
              
              next_state = CHECK;
        end
        
        CHECK: begin
            //check if where we about to move (the address we gave to the rom in the case READROM and is now ready) is a wall(all rgb value 0).
            if(|i_rom_data[15:4] == 1 )
                next_state = UPDATE; 
            else 
                next_state = PLAY; 
            
            o_rom_en = 0;
        end
        
        UPDATE: begin
            next_player_bcol = new_bcol_r;
            next_player_brow = new_brow_r;
            
            next_state = PLAY;
        end

        END_S: begin
            if(only_control_pressed) 
                next_state = IDLE;
        end
        
        
        // Handle unexpected states
        default: begin
            next_state = IDLE; 
        end
    
    endcase
    
    
    //logic for time (nexttwo_seconds_intervals)
    if(game_is_running)begin
        if(clocks_couter == NUM_OF_CYCLES_FOR_2_SECS - 1)begin
            clocks_couter_next = 0;
            if(o_two_seconds_intervals < 40) 
                nexttwo_seconds_intervals++; 
            else
                next_state = END_S;
        end
        else
            clocks_couter_next++;    
     end
        
end


endmodule
