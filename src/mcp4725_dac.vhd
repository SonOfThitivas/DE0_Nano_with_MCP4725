-- REF. IOT ENGINEERING EDUCATION, https://iot-kmutnb.github.io/blogs/fpga/fpga_mcp4725_dac/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcp4725_dac is
  port (
    NRESET  		: in std_logic;
    CLK     		: in std_logic;
	 sample  		: in std_logic_vector(11 downto 0);
    I2C_SDA 		: inout std_logic;
    I2C_SCL 		: inout std_logic;
	 I2C_CLK_SPEED : in integer;
	 incr,
	 decr				: in std_logic;
    STATUS  		: out std_logic
  );
end mcp4725_dac;

architecture behavior of mcp4725_dac is
  -- 7-bit I2C device address for MCP4725 (0x60)
  constant I2C_ADDR      : std_logic_vector(6 downto 0) := "1100000";

  type state_type is (ST_IDLE, ST_START, ST_WR_1, ST_WR_2, ST_STOP);
  signal state : state_type := ST_IDLE;

  signal busy        : std_logic;
  signal ack_error   : std_logic;
  signal ena         : std_logic := '0';
  signal rw          : std_logic := '0';
  signal data_wr     : std_logic_vector(7 downto 0);
  signal data_buffer : std_logic_vector(15 downto 0);
  signal busy_prev   : std_logic_vector(1 downto 0);
  signal wait_cnt    : integer := 0;
  signal prev_incr,
			prev_decr	: std_logic := '1';
  
begin

  -- I2C Master Instantiation
  i2c_master_inst : entity work.i2c_master
    generic map(
      input_clk => 50_000_000 -- Assume system clock of 50 MHz
    )
    port map
    (
      clk       => CLK,
      reset_n   => NRESET,
		bus_clk	 => I2C_CLK_SPEED,
      ena       => ena,
      addr      => I2C_ADDR,
      rw        => rw,
      data_wr   => data_wr,
      busy      => busy,
      ack_error => ack_error,
      sda       => I2C_SDA,
      scl       => I2C_SCL,
		incr		 => incr,
		decr		 => decr
    );

  STATUS <= busy;

  process (NRESET, CLK)
  begin
    if NRESET = '0' or
		 (incr = '0' and prev_incr = '1') or
		 (decr = '0' and prev_decr = '1') then
      state        <= ST_IDLE;
      ena          <= '0';
      rw           <= '0';
      busy_prev    <= (others => '0');
      wait_cnt     <= 10000;

    elsif rising_edge(CLK) then
			prev_incr <= incr;
			prev_decr <= decr;
			
			busy_prev <= busy_prev(0) & busy;

			case state is
			  when ST_IDLE =>
				 -- Prepare the data (Fast Write Mode)
				 data_buffer <= "0000" & sample;
				 state       <= ST_START;
				 ena         <= '0';

			  when ST_START =>
				 -- Set up for I2C transmission  
				 ena     <= '1'; -- Start I2C transaction
				 rw      <= '0'; -- write operation  
				 data_wr <= data_buffer(15 downto 8); -- the high byte 
				 state   <= ST_WR_1;

			  when ST_WR_1 =>
				 if I2C_SCL = '0' and busy = '1' then
					data_wr <= data_buffer(7 downto 0); -- the low byte         
				 end if;
				 if busy_prev = "10" then -- busy goes low
					if ack_error = '0' then -- ACK
					  state <= ST_WR_2;
					else -- No ACK
					  ena   <= '0';
					  state <= ST_STOP;
					end if;
				 end if;

			  when ST_WR_2 =>
				 if busy_prev = "01" then -- busy goes high
					ena <= '0';
				 elsif busy_prev = "10" then -- busy goes low
					if ack_error = '0' then -- ACK
					  state <= ST_IDLE;
					else -- No ACK
					  state <= ST_STOP;
					end if;
				 end if;

			  when ST_STOP =>
				 if wait_cnt = 0 then
					wait_cnt     <= 10000;
					ena          <= '0';
					state        <= ST_IDLE;
				 else
					wait_cnt <= wait_cnt - 1;
				 end if;
					state        <= ST_IDLE;
			  when others =>
				 state <= ST_IDLE;

			end case;
			
    end if;
  end process;

end behavior;
