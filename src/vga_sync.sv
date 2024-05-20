/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2024/04/1
 * Author: Georgios Xiroudakis
 * Filename: vga_sync.sv
 * Description: Implements VGA HSYNC and VSYNC timings for 640 x 480 @ 60Hz
 *
 ******************************************************************************/

module vga_sync(
  input logic clk,
  input logic rst,

  output logic o_pix_valid,
  output logic [9:0] o_col,
  output logic [9:0] o_row,

  output logic o_hsync,
  output logic o_vsync
);


parameter int FRAME_HPIXELS     = 640;
parameter int FRAME_HFPORCH     = 16;
parameter int FRAME_HSPULSE     = 96;
parameter int FRAME_HBPORCH     = 48;
parameter int FRAME_MAX_HCOUNT  = 800;

parameter int FRAME_VLINES      = 480;
parameter int FRAME_VFPORCH     = 10;
parameter int FRAME_VSPULSE     = 2;
parameter int FRAME_VBPORCH     = 29;
parameter int FRAME_MAX_VCOUNT  = 521;

parameter int HCNT_N            = 10;
parameter int VCNT_N            = 10;

logic [HCNT_N - 1 : 0] hcnt;
logic hcnt_clr;

logic [VCNT_N - 1 : 0] vcnt;
logic vcnt_clr;

logic pix_valid;

logic hsync_pre;
logic hsync;
logic hsync_comb;
logic hs_set;
logic hs_clr;

logic vsync;
logic vsync_comb;
logic vs_set;
logic vs_clr;

always_ff @(posedge clk) begin
    if( rst ) begin
    // rst is active
    
        hcnt <= '0;
        vcnt <= '0;
        
        hsync_pre <= '0;
        hsync <= '0;
        vsync <= '0;
        
    end
    else begin
    // when rst is not active
    
        // ff logic for hcnt
        if(hcnt_clr) begin
            hcnt <= '0;
        end
        else begin
            hcnt <= hcnt + 1;
        end
        
        // ff logic for vcnt
        if(vcnt_clr) begin
            vcnt <= '0;
        end
        else if(hcnt_clr) begin
            vcnt <= vcnt + 1;
        end
        else begin
            vcnt <= vcnt;
        end
          
           
        hsync_pre <= hsync_comb;
        hsync <= hsync_pre;
        
        vsync <= vsync_comb;

    end
    
end


always_comb begin
    // comb logic for hcnt_clr 
    hcnt_clr = (hcnt == FRAME_MAX_HCOUNT - 1);
    
    // comb logic for vcnt_clr 
    vcnt_clr = (vcnt == FRAME_MAX_VCOUNT - 1) && (hcnt_clr); 
    
    // comb logic for pix_valid
    pix_valid = (hcnt < FRAME_HPIXELS) && (vcnt < FRAME_VLINES);
    
    // comb logic for hsync
    hs_set = (hcnt == (FRAME_HPIXELS + FRAME_HFPORCH - 1));
    hs_clr = (hcnt == (FRAME_HPIXELS + FRAME_HFPORCH + FRAME_HSPULSE - 1) );
    
    hsync_comb = ( (hs_set || hsync_pre)  && (~hs_clr) );
    
    // comb logic for vsync
    vs_set = ( ( vcnt == (FRAME_VLINES + FRAME_VFPORCH - 1) ) && (hcnt_clr) );
    vs_clr = ( ( vcnt == (FRAME_VLINES + FRAME_VFPORCH + FRAME_VSPULSE - 1) ) && (hcnt_clr) );
    
    vsync_comb = ( (vs_set || vsync) && (~vs_clr) );
    
    
    // assing the outputs
    o_col = hcnt;
    o_row = vcnt;
    o_pix_valid = pix_valid;
    
    o_hsync = ~hsync;
    
    o_vsync = ~vsync;
    
    
end




endmodule