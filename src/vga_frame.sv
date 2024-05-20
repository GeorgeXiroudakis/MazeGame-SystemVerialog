/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2023/02/06
 * Author: George Xiroudakis
 * Filename: vga_frame.sv
 * Description: Your description here
 *
 ******************************************************************************/

module vga_frame #(
    parameter int block_dividor = 4,
    
    parameter int rom_with = 16,
    
    parameter int player_size = 256,
    parameter int player_rom_row_size = 16,
    
    parameter int exit_size = 256,
    parameter int exit_rom_row_size = 16,
    
    parameter int maze_size = 2048,
    parameter int maze_rom_row_size = 64

)(
  input logic clk,
  input logic rst,
  
  input logic i_rom_en,
  input logic [10:0] i_rom_addr,
  output logic [15:0] o_rom_data,

  input logic i_pix_valid,
  input logic [9:0] i_col,
  input logic [9:0] i_row,

  input logic [5:0] i_player_bcol,
  input logic [5:0] i_player_brow,

  input logic [5:0] i_exit_bcol,
  input logic [5:0] i_exit_brow,
  
  input logic [5:0] i_two_seconds_intervals,

  output logic [3:0] o_red,
  output logic [3:0] o_green,
  output logic [3:0] o_blue
);


logic [3:0]red;
logic [3:0]green;
logic [3:0]blue;


logic player_en;
logic [($clog2(player_size))-1:0]player_addr;
logic [rom_with-1:0]player_pixel;


logic exit_en;
logic [($clog2(exit_size))-1:0]exit_addr;
logic [rom_with-1:0]exit_pixel;


logic maze_en;
logic [($clog2(maze_size))-1:0]maze_addr;
logic [rom_with-1:0]maze_pixel;


typedef enum logic[3:0] {progress_bar, player, exit, maze, nothing}Prev_state;

Prev_state prev_state;
Prev_state prev_state_reg;


always_ff @(posedge clk) begin
    if( rst ) begin
        o_red   <= '0;
        o_green <= '0;
        o_blue  <= '0;
        prev_state_reg <= nothing;
        
    end
    else begin
    // when rst is not active
        o_red   <= red;
        o_green <= green;
        o_blue  <= blue;
        
        prev_state_reg <= prev_state;
    end
end




always_comb begin
    maze_en = 0;
    maze_addr = '0;
    player_en = 0;
    player_addr = '0;
    exit_en = 0;
    exit_addr = '0;
    red = '0;
    green = '0;
    blue = '0;
    prev_state = nothing;
    
    //if we have to draw a pixel
    if(i_pix_valid) begin
        
        //if we are drawing the progress bar
        if((i_row >> block_dividor) == 29)begin
            
            prev_state = progress_bar;
        end
    
        //if we are drawing the player
        else if( ((i_row >> block_dividor) == i_player_brow) && ( (i_col >> block_dividor) == i_player_bcol) ) begin
            player_en = 1;
            
            //logic for finding addr
             player_addr = (i_row % player_rom_row_size) * player_rom_row_size + (i_col % player_rom_row_size);

            
            // saving want will be ready in the next clock
            prev_state = player;

        end
        // if we are drawing the exit
        else if ( ((i_row >> block_dividor) == i_exit_brow) && ( (i_col >> block_dividor) == i_exit_bcol)) begin
            exit_en = 1;
            
            //logic for finding addr
            exit_addr = (i_row % exit_rom_row_size) * exit_rom_row_size + (i_col % exit_rom_row_size);
            
             // saving want will be ready in the next clock
            prev_state = exit;
        end
        // else we just draw the exit
        else begin
            maze_en = 1;
            
            //logic for finding addr
            maze_addr = ( ((i_row >> block_dividor) * maze_rom_row_size) + (i_col >> block_dividor) );
            
             // saving want will be ready in the next clock
             prev_state = maze;
        end 
            
            
     end
    else begin prev_state = nothing; end
    
    
    // draw the pixel that is now ready form the prev clock
    if(prev_state_reg == progress_bar)begin
            if( ( (i_col >> block_dividor) < i_two_seconds_intervals) ) begin
            red = 4'b1111;
            green ='0;
            blue ='0;
        end
        else begin
            red   = 4'b0011;
            green = 4'b0001;
            blue  = 4'b0100;
        end
    end
    else if(prev_state_reg == player) begin
            red = player_pixel[15:12];
            green = player_pixel[11:8];
            blue = player_pixel[7:4];
    end
    else if(prev_state_reg == exit) begin
            red = exit_pixel[15:12];
            green = exit_pixel[11:8];
            blue = exit_pixel[7:4];
    end
     else if(prev_state_reg == maze) begin
            red = maze_pixel[15:12];
            green = maze_pixel[11:8];
            blue = maze_pixel[7:4];
    end
    
end


rom_dp #(
  .size(maze_size),
  .file("roms/maze1.rom") 
)
maze_rom (
  .clk(clk),
  
  .en(maze_en),
  .addr(maze_addr),
  .dout(maze_pixel),
  
  .en_b(i_rom_en),
  .addr_b(i_rom_addr),
  .dout_b(o_rom_data)
);


rom #(
  .size(player_size),
  .file("roms/player.rom") 
)
player_rom (
  .clk(clk),
  .en(player_en),
  .addr(player_addr),
  .dout(player_pixel)
);

rom #(
  .size(exit_size),
  .file("roms/exit.rom") 
)
exit_rom (
  .clk(clk),
  .en(exit_en),
  .addr(exit_addr),
  .dout(exit_pixel)
);


endmodule
