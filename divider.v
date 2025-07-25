module divider#(
  parameter width = 25
)(
  input clk,
  input reset,
  input en,
  input [width - 1 : 0] num, den,

  output reg [width - 1 : 0] q, r,
  output reg done
);

integer count;

reg [width - 1 : 0] d;
wire [width : 0] s;

assign s = {1'b0, r} - {1'b0, d};

always @(posedge clk or posedge reset) begin
  if(reset) begin
    d <= 0;
    q <= 0;
    r <= 0;
    done <= 0;
    count <= 0;
  end else if(!en) begin
    d <= 0;
    q <= 0;
    r <= 0;
    done <= 0;
    count <= 0;
  end else begin
    if (count == 0) begin
      r <= num;
      q <= 0;
      d <= den;
      count <= count + 1;
    end else if (count < width) begin
      if (r == 0) begin
        done <= 1;
        count <= width;
      end else if (s[width]) begin
        r <= {r[width - 2 : 0], q[width - 1]};
        q <= q << 1;
        count <= count + 1;
      end else begin
        r <= {s[width - 1 : 0], q[width - 1]};
        q <= {q[width - 2 : 0], 1'b1};
        count <= count + 1;
      end
    end else begin
      done <= 1;
    end
  end
end
endmodule

    
