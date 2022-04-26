`timescale 1ns / 1ps

module tron (
        Clk, SCEN, Reset, Start, Ack,
        q_I, q_Driving, q_Collision, q_Done,
        hSync, vSync, vgaR, vgaG, vgaB
	);

    input   Clk, SCEN, Reset, Start, Ack;
    input   p1_dir;
    input   p2_dir;


    output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,

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
// Grid Representation
    localparam GRID_SIZE = 64;
    localparam GRID_BITS = 6;

    // Player Grids
    reg p1_grid [GRID_SIZE - 1:0] [GRID_SIZE - 1:0];
    reg p2_grid [GRID_SIZE - 1:0] [GRID_SIZE - 1:0];

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

    // State Machine Wires
    wire q_I    


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

                        p1_grid[i][0] <= 1;
                        p1_grid[i][GRID_SIZE - 1] <= 1;
                        p1_grid[0][i] <= 1;
                        p1_grid[GRID_SIZE - 1][i] <= 1;
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



    end
