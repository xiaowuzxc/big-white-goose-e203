module IMG_DPR #(
	parameter RAM_WIDTH = 17,                       // Specify RAM data width
	parameter RAM_DEPTH = 784,                     // Specify RAM depth (number of entries)
	parameter RAM_PERFORMANCE = "LOW_LATENCY", // no_output_register
	parameter INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
) (
	input [clogb2(RAM_DEPTH-1)-1:0] addra,  // Port A address bus, width determined from RAM_DEPTH
	input [clogb2(RAM_DEPTH-1)-1:0] addrb,  // Port B address bus, width determined from RAM_DEPTH
	input [RAM_WIDTH-1:0] dina,           // Port A RAM input data
	input [RAM_WIDTH-1:0] dinb,           // Port B RAM input data
	input clka,                           // Clock
	input wea,                            // Port A write enable
	input web,                            // Port B write enable
	input ena,                            // Port A RAM Enable, for additional power savings, disable port when not in use
	input enb,                            // Port B RAM Enable, for additional power savings, disable port when not in use
	input rsta,                           // Port A output reset (does not affect memory contents)
	input rstb,                           // Port B output reset (does not affect memory contents)
	input regcea,                         // Port A output register enable
	input regceb,                         // Port B output register enable
	output [RAM_WIDTH-1:0] douta,         // Port A RAM output data
	output [RAM_WIDTH-1:0] doutb          // Port B RAM output data
);


reg [RAM_WIDTH-1:0] BRAM [RAM_DEPTH-1:0];
reg [RAM_WIDTH-1:0] ram_data_a = {RAM_WIDTH{1'b0}};
reg [RAM_WIDTH-1:0] ram_data_b = {RAM_WIDTH{1'b0}};



always @(posedge clka)
	if (ena)
		if (wea) begin
			BRAM[addra] <= dina;
			ram_data_a <= dina;
		end else
			ram_data_a <= BRAM[addra];

always @(posedge clka)
	if (enb)
		if (web) begin
			BRAM[addrb] <= dinb;
			ram_data_b <= dinb;
		end else
			ram_data_b <= BRAM[addrb];

//  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
generate
	if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register

		// The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
		 assign douta = ram_data_a;
		 assign doutb = ram_data_b;

	end else begin: output_register

		// The following is a 2 clock cycle read latency with improve clock-to-out timing

		reg [RAM_WIDTH-1:0] douta_reg = {RAM_WIDTH{1'b0}};
		reg [RAM_WIDTH-1:0] doutb_reg = {RAM_WIDTH{1'b0}};

		always @(posedge clka)
			if (rsta)
				douta_reg <= {RAM_WIDTH{1'b0}};
			else if (regcea)
				douta_reg <= ram_data_a;

		always @(posedge clka)
			if (rstb)
				doutb_reg <= {RAM_WIDTH{1'b0}};
			else if (regceb)
				doutb_reg <= ram_data_b;

		assign douta = douta_reg;
		assign doutb = doutb_reg;

	end
endgenerate

//  The following function calculates the address width based on specified RAM depth
function integer clogb2;
	input integer depth;
		for (clogb2=0; depth>0; clogb2=clogb2+1)
			depth = depth >> 1;
endfunction



endmodule