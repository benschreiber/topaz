/* The cache controller - contains the state machine for the cache */

/* cpu control contains the state machine for the cpu */
import lc3b_types::*; /* Import types defined in lc3b_types.sv */

module l2cache_control
(
    /* Input and output port declarations */
    input clk,
    input lc3b_word mem_address,
	 input [1:0] mem_byte_enable,
	 input mem_write,
	 input mem_read,
	 input cache_line mem_wdata,
	 input logic [1:0] pseudolru_out,
	 input logic way0and_out,
	 
     
     /* Datapath controls */
    input cache_line pmem_rdata,
	 input pmem_resp,
	 input logic dirtymux_out,
	 input logic hit,
	 
	 output logic rwmux_sel,
	 output logic stbwritemux_sel,
	 output logic mem_resp,
    output logic pmem_read,
	 output logic data0write, data1write,
	 output logic tag0write, tag1write,
	 output logic valid0write, valid1write,
	 output logic dirty0write, dirty1write,
	 output logic dirty0_in, dirty1_in,
	 output logic data2write, data3write,
	 output logic tag2write, tag3write,
	 output logic valid2write, valid3write,
	 output logic dirty2write, dirty3write,
	 output logic dirty2_in, dirty3_in,
    output logic pmem_write,
	 output logic pmemmux_sel,
	 output logic pseudolru_write     
);

enum int unsigned {
    /* List of states */
    s_idle,
	 s_update_cache,
	 s_pmem_complete,
	 s_write_back,
	 s_allocate
} state, next_state;

always_comb
begin : state_actions
    /* Default output assignments */
    tag0write = 1'b0;
	 stbwritemux_sel = 1'b0;
	 rwmux_sel = 1'b0;
	 tag1write = 1'b0;
	 data0write = 1'b0;
	 data1write = 1'b0;
	 valid0write = 1'b0;
	 valid1write = 1'b0;
	 dirty0write = 1'b0;
	 dirty1write = 1'b0;
	 dirty0_in = 1'b0;
	 dirty1_in = 1'b0;
	 tag2write = 1'b0;
	 tag3write = 1'b0;
	 data2write = 1'b0;
	 data3write = 1'b0;
	 valid2write = 1'b0;
	 valid3write = 1'b0;
	 dirty2write = 1'b0;
	 dirty3write = 1'b0;
	 dirty2_in = 1'b0;
	 dirty3_in = 1'b0;
	 mem_resp = 1'b0;
	 pmem_read = 1'b0;
	 pseudolru_write = 1'b0;
	 pmem_write = 1'b0;
	 pmemmux_sel = 1'b0;
    /* Actions for each state */
     
     case(state)
        s_idle: begin
				pseudolru_write = 0;
				if(mem_read && hit)
				begin
					mem_resp = 1;
					pseudolru_write = 1;
				end
				else if((mem_write && hit) && (mem_byte_enable != 2'b00))
				begin
					pseudolru_write = 1;
					if(way0and_out)
						begin
							data0write = 1;
							tag0write = 1;
							valid0write = 1;
							dirty0write = 1;
							dirty0_in = 1;
						end
						else 
						begin
							data1write = 1;
							tag1write = 1;
							valid1write = 1;
							dirty1write = 1;
							dirty1_in = 1;
						end
						mem_resp = 1;
						rwmux_sel = 1;
					end
				end
		  s_update_cache: begin
				if(mem_read)
					pseudolru_write = 1;
		  end
		  s_pmem_complete: begin
				if(mem_write)
				begin
					if((mem_byte_enable == 2'b10) | (mem_byte_enable == 2'b01))
						stbwritemux_sel = 1;
					rwmux_sel = 1;
					if(pseudolru_out == 2'b00)
					begin
						data0write = 1;
						tag0write = 1;
						valid0write = 1;
						dirty0write = 1;
						dirty0_in = 1;
					end
					else if(pseudolru_out == 2'b01)
					begin
						data1write = 1;
						tag1write = 1;
						valid1write = 1;
						dirty1write = 1;
						dirty1_in = 1;
					end
					else if(pseudolru_out == 2'b10)
					begin
						data2write = 1;
						tag2write = 1;
						valid2write = 1;
						dirty2write = 1;
						dirty2_in = 1;
					end
					else if(pseudolru_out == 2'b11)
					begin
						data3write = 1;
						tag3write = 1;
						valid3write = 1;
						dirty3write = 1;
						dirty3_in = 1;
					end
				end
				mem_resp = 1;
		  end
		  s_write_back: begin
				pmem_write = 1;
				pmemmux_sel = 1;
		  end
		  s_allocate: begin
				pmem_read = 1;
				if(pseudolru_out == 2'b00)
					begin
						data0write = 1;
						tag0write = 1;
						valid0write = 1;
						dirty0write = 1;
						dirty0_in = 1;
					end
					else if(pseudolru_out == 2'b01)
					begin
						data1write = 1;
						tag1write = 1;
						valid1write = 1;
						dirty1write = 1;
						dirty1_in = 1;
					end
					else if(pseudolru_out == 2'b10)
					begin
						data2write = 1;
						tag2write = 1;
						valid2write = 1;
						dirty2write = 1;
						dirty2_in = 1;
					end
					else if(pseudolru_out == 2'b11)
					begin
						data3write = 1;
						tag3write = 1;
						valid3write = 1;
						dirty3write = 1;
						dirty3_in = 1;
					end
		  end
     default:/* Do nothing */;
     endcase 
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
     next_state = state;

     case(state)
         s_idle:
				if(mem_read && hit)
					next_state = s_idle;
				else if(!hit && !dirtymux_out && (mem_read || mem_write))
					next_state = s_allocate;
				else if(!hit && dirtymux_out)
					next_state = s_write_back;
			s_update_cache:
				next_state = s_pmem_complete;
			s_pmem_complete:
				next_state = s_idle;
			s_write_back:
				if(pmem_resp == 0)
					next_state = s_write_back;
				else
					next_state = s_allocate;
			s_allocate:
				if(pmem_resp == 0)
					next_state = s_allocate;
				else
					next_state = s_update_cache;
			
		  default: 
				next_state = s_idle;
        endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
     begin : next_state_assignment
         state <= next_state;
     end
end

endmodule : l2cache_control
