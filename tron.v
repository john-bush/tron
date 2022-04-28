`timescale 1ns / 1ps

module tron (
        input Clk, 
        input Reset, Start, Ack,
        // q_I, q_Driving, q_Collision, q_Done,
        hSync, vSync, vgaR, vgaG, vgaB,
        input BtnU, input BtnD, input BtnL, input BtnC, input BtnR,
        input [9:0] hCount, vCount,
        output hsync, vsync, 
        output [3:0] vga_r, vga_g, vga_b,
        output reg [11:0] background,
        output reg [1:0] p1_score,
        output reg [1:0] p2_score
	);


    input   p1_dir;
    input   p2_dir;
    
    reg vga_r, vga_g, vga_b;

    wire inDisplayArea;
    wire [9:0] hsync;
    wire [9:0] vsync;

    output q_I, q_Straight, q_Turn, q_Collision;
    reg[3:0] state;
    assign {q_I, q_Straight, q_Turn, q_Collision} = state;

    localparam 	
	I =         4'b0001, 
    STRAIGHT =  4'b0010, 
    TURN =      4'b0100, 
    COLLISION = 4'b1000, 
    UNK =       4'bXXXX;

//===================================================
// Button Inputs for Player Direction
    always @(posedge DIV_CLK[19])
    begin
        if (BtnU)
            p1_dir <= 2'b00;
        else if (BtnR)
            p1_dir <= 2'b01;
        else if (BtnD)
            p1_dir <= 2'b11;
        else if (BtnL)
            p1_dir <= 2'b10;
    end

// ==================================================
// Display Controller Instantiation
    display_controller display(
        .clk(ClkPort), 
        .hSync(hSync), 
        .vSync(vSync), 
        .bright(bright), 
        .hCount(hc), 
        .vCount(vc)
    );

    assign vgaR = rgb[11 : 8];
	assign vgaG = rgb[7  : 4];
	assign vgaB = rgb[3  : 0];

//===================================================
// Grid Representation
    localparam GRID_SIZE = 64;
    localparam GRID_BITS = 6;

    // Player Grids
    reg p1_grid     [GRID_SIZE - 1:0] [GRID_SIZE - 1:0];
    reg p2_grid     [GRID_SIZE - 1:0] [GRID_SIZE - 1:0];
    reg border_grid [GRID_SIZE - 1:0] [GRID_SIZE - 1:0];

//===================================================
// Player Variables
    // Player Directions
    reg [1:0] p1_dir;
	reg [1:0] p2_dir;

    // Player Positions
    reg [GRID_BITS - 1:0] p1_x
    reg [GRID_BITS - 1:0] p1_y
    reg [GRID_BITS - 1:0] p2_x
    reg [GRID_BITS - 1:0] p2_y

    // Player Scores
    reg [3:0] p1_score;
    initial p1_score <= 0;
    reg [3:0] p2_score;
    initial p2_score <= 0;

    // Collision Flags
    wire p1_collision;
    wire p2_collision;
    wire draw;
    wire collision;   

    // Local variables to loop through the grid during processing
	integer i, j;

    // Collision Checker
    assign p1_collision = p2_grid[p1_x][p1_y] || p1_grid[p1_x][p1_y];
    assign p2_collision = p1_grid[p2_x][p2_y] || p2_grid[p2_x][p2_y];
    assign draw = (p1_collision && p2_collision);
    assign collision = p1_collision || p2_collision || draw;

	// Game State Machine
	always @(posedge DIV_CLK[23])
    begin
        if (reset)
        begin
            state <= I;
            p1_score = 0;
            p2_score = 0;
        end

        else
            case (state)
                I:
                begin
                    if (start)
                        state <= DRIVING;
                    
                    // reset player start positions
                    p1_x <= GRID_SIZE / 2;
                    p1_y <= GRID_SIZE / 4;
                    p2_x <= GRID_SIZE / 2;
                    p2_y <= 3 * GRID_SIZE / 4;

                    // Set the border of the starting grids as visited
                    for (i = 0; i < GRID_SIZE - 1; i = i + 1) 
                    begin
                        p1_grid[i][0] <= 1;
                        p1_grid[i][GRID_SIZE - 1] <= 1;
                        p1_grid[0][i] <= 1;
                        p1_grid[GRID_SIZE - 1][i] <= 1;

                        p2_grid[i][0] <= 1;
                        p2_grid[i][GRID_SIZE - 1] <= 1;
                        p2_grid[0][i] <= 1;
                        p2_grid[GRID_SIZE - 1][i] <= 1;

                        border_grid[i][0] <= 1;
                        border_grid[i][GRID_SIZE - 1] <= 1;
                        border_grid[0][i] <= 1;
                        border_grid[GRID_SIZE - 1][i] <= 1;
                    end 

                    // Set the inside of the player grids as unvisited 
                    for (i = 1; i < GRID_SIZE - 2; i = i + 1 )
                    begin
                        for (j = 1; j < GRID_SIZE - 2; j = j + 1)
                        begin
                            p1_grid[i][j] <= 0;
                            p2_grid[i][j] <= 0;
                        end
                    end

                end

                DRIVING:
                begin
                    if (collision)
                        begin
                            state <= COLLISION;
                            if (p1_crash && !draw)
                                p2_score <= p2_score + 1;
                            if (p2_crash && !draw)
                                p1_score <= p1_score + 1;
                        end

                    else
                        begin
                            // mark current p1, p2 positions as visited
                            p1_grid[p1_x][p1_y] <= 1;
                            p2_grid[p2_x][p2_y] <= 1;

                            case (p1_dir)
                                // update p1_position
                                UP:
                                    p1_y <= p1_y + 1;
                                DOWN:
                                    p1_y <= p1_y - 1;
                                LEFT:
                                    p1_x <= p1_x - 1;
                                RIGHT:
                                    p1_x <= p1_x + 1;
                            endcase

                            case (p2_dir)
                                // update p2_position
                                UP:
                                    p2_y <= p2_y + 1;
                                DOWN:
                                    p2_y <= p2_y - 1;
                                LEFT:
                                    p2_x <= p2_x - 1;
                                RIGHT:
                                    p2_x <= p2_x + 1;
                            endcase
                        end

                end

                COLLISION:
                begin
                    if (start) state <= DONE;
                end

                DONE:
                begin
                    if (start) state <= I;
                end

                default:
                    state <= UNK;
            endcase

// ====================================================
// ==================   VGA CODE  =====================
// ====================================================
    wire bl_fill, bu_fill, br_fill, bd_fill, border_fill;
	wire p1_head_fill, p2_head_fill, p1_trail_fill, p2_trail_fill;
	
    parameter border_color = 12'b1111_0000_0000;
	parameter RED   = 12'b1111_0000_0000;
    parameter GREEN = 12'b0000_1111_0000;

    parameter P1_HEAD = 12'b0000_0000_1111;
    parameter P2_HEAD = 12'b1111_0011_0000;
    parameter P1_TRAIL = 12'b0000_1111_1111;
    parameter P2_TRAIL = 12'b1111_0110_0000;
    


	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )begin	//force black if not inside the display area
			rgb = 12'b0000_0000_0000;
		    background = 12'b0000_0000_0000;
		end
		else if (p1_head_fill)
			rgb = P1_HEAD;
        else if (p2_head_fill)
            rgb = P2_HEAD;
        else if (p1_trail_fill)
            rgb = P1_TRAIL;
        else if (p2_trail_fill)
            rgb = P2_TRAIL;
        else if (border_fill)
            rgb = border_color;
		// else if (bl_fill)
		// 	rgb = border_color;
		// else if (bu_fill)
		// 	rgb = border_color;
		// else if (br_fill)
		// 	rgb = border_color;
		// else if (bd_fill)
		// 	rgb = border_color;
        
		else	
			rgb=background;
	end

    localparam SCALE = 8;

		//the +-1 for the positions give the dimension of the block (i.e. it will be 2x2 pixels)
	assign p1_head_fill=vCount>=(p1_y-2) && vCount<=(p1_y+2) && hCount>=(p1_x-2) && hCount<=(p1_x+2);
	assign p2_head_fill = vCount >= (p2_y - 2) && vcount <= (p2_y + 2) && hcount >= (p2_x - 2) && hcount <= (p2_x + 2);

    assign p1_trail_fill = p1_grid[vCount / SCALE] [hCount / SCALE];
    assign p2_trail_fill = p2_grid[vCount / SCALE] [hCount / SCALE];

	// assign bl_fill=vCount>=(70) && vCount<=(480) && hCount>=(246) && hCount<=(250);
	// assign bu_fill=vCount>=(70) && vCount<=(75) && hCount>=(246) && hCount<=(654);
	// assign br_fill=vCount>=(70) && vCount<=(480) && hCount>=(650) && hCount<=(654);
	// assign bd_fill=vCount>=(475) && vCount<=(480) && hCount>=(246) && hCount<=(654);

    assign border_fill = border_grid[vCount / SCALE] [hCount / SCALE];

    always @(posedge Clk)
    begin
        vgaR = rgb[11 : 8];
	    vgaG = rgb[7  : 4];
	    vgaB = rgb[3  : 0];
    end

endmodule

