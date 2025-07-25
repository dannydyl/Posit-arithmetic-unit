module CLZ #(
  parameter width = 8,
  localparam index_width = $clog2(width)
  )( // count leading zeros, outputs the index of the first 1
  input [width - 1 : 0] in,
  output reg [index_width : 0] index
);

integer i;
reg found_one;

always @* begin
  index = width;
  found_one = 1'b0;
  for (i = width - 1; i >= 0 && !found_one; i = i - 1) begin
    if (in[i] == 1'b1) begin
      index = i;
      found_one = 1'b1;
    end
  end
end

endmodule