-----------------------------------------------------------------------------
-- Mini-Project: Clock Adjustable for Adjusting Sampling Rate					--
-- Aurthors 	: Puwit 		Luedara		6601012610113								--
--					  Karn 		Suksomkit  	6601012620011								--
--					  Phumwit 	Wongmool		6601012630068								--
-- Date			: November / 9 / 2024													--
-- Class			: Introduction of Signals and Systems				 				--
--	Major			: Computer Engineering (Cpr.E)										--
-- Department 	: Eletrical and Computer Engineering (ECE)						--
-- Faculty		: Engineering																--
-- King's Monkut University of Technology North Bangkok (KMUTNB)				--
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_level is
end tb_top_level;

architecture sim of tb_top_level is

	-- Component declaration for the Unit Under Test (UUT)
	component top_level
		port (
			CLOCK_50 : in std_logic;
			RST      : in std_logic;

			-- ADC SPI Protocol
			ADC_SDAT  : in std_logic;
			ADC_SADDR : out std_logic;
			ADC_CS_N  : out std_logic;
			ADC_SCLK  : out std_logic;
			
			-- DAC I2C Protocol
			SDA : inout std_logic;
			SCL : inout std_logic
		);
	end component;

	-- Testbench signals
	signal CLOCK_50    : std_logic := '0';
	signal RST         : std_logic := '1';
	signal ADC_SDAT    : std_logic := '0';
	signal ADC_SADDR   : std_logic;
	signal ADC_CS_N    : std_logic;
	signal ADC_SCLK    : std_logic;
	signal SDA         : std_logic := 'Z';
	signal SCL         : std_logic := 'Z';

	-- Variables for simulation
	signal test_adc_data   : std_logic_vector(15 downto 0) := (others => '0');
	signal counter         : integer := 0;

	-- Clock generation (50 MHz)
	constant CLOCK_PERIOD : time := 20 ns;

begin

	-- Instantiate the Unit Under Test (UUT)
	UUT: top_level
		port map (
			CLOCK_50 => CLOCK_50,
			RST      => RST,
			ADC_SDAT => ADC_SDAT,
			ADC_SADDR => ADC_SADDR,
			ADC_CS_N  => ADC_CS_N,
			ADC_SCLK  => ADC_SCLK,
			SDA      => SDA,
			SCL      => SCL
		);

	-- Clock process
	clock_process : process
	begin
		CLOCK_50 <= '0';
		wait for CLOCK_PERIOD / 2;
		CLOCK_50 <= '1';
		wait for CLOCK_PERIOD / 2;
	end process;

	-- Stimulus process to simulate ADC input signals
	stim_proc: process
	begin
		-- Reset sequence
		RST <= '1';
		wait for 100 ns;
		RST <= '0';
		wait for 100 ns;
		RST <= '1';
		
		-- Simulate ADC conversion by toggling ADC signals
		while counter < 1000 loop  -- Run for 1000 cycles
			-- Assert ADC_CS_N low to enable ADC communication
			ADC_CS_N <= '0';
			-- Generate clock pulses for ADC_SCLK
			for i in 0 to 15 loop
				ADC_SCLK <= '1';
				wait for CLOCK_PERIOD / 4;
				ADC_SCLK <= '0';
				wait for CLOCK_PERIOD / 4;
				ADC_SDAT <= test_adc_data(15 - i);  -- Shift ADC data bit-by-bit
			end loop;
			
			-- End ADC transaction by setting ADC_CS_N high
			ADC_CS_N <= '1';
			wait for CLOCK_PERIOD * 4;
			
			-- Increment the test ADC data for variation in the next cycle
			test_adc_data <= std_logic_vector(unsigned(test_adc_data) + 1);
			counter <= counter + 1;
		end loop;

		-- End of test, stop the simulation
		wait;
	end process;

end sim;
