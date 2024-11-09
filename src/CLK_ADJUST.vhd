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

entity CLK_ADJUST is
    port(
        CLOCK_50             : IN STD_LOGIC;
        
        RST,
        incr,
        decr                 : IN STD_LOGIC := '1' ;
        
        LED8                 : OUT STD_LOGIC_VECTOR(7 downto 0);
        I2C_CLK_SPEED        : OUT INTEGER := 400_000
        
    );
    
end CLK_ADJUST;

architecture ADJUSTING of CLK_ADJUST is
    signal prev_incr,
           prev_decr        : STD_LOGIC := '1';
    
begin
    process(CLOCK_50, RST) is
    begin
        
        if RST = '0' then
            LED8                     <= (others => '0');
            I2C_CLK_SPEED         	 <= 400_000;
        
        elsif rising_edge(CLOCK_50) then
            
            if incr = '0' and prev_incr = '1' then
                case I2C_CLK_SPEED is
                    when 100_000     => 
                        I2C_CLK_SPEED     <= 400_000;
                    
                    when 400_000     => 
                        I2C_CLK_SPEED     <= 1_700_000;
                    
                    when 1_700_000 => 
                        I2C_CLK_SPEED     <= 100_000;
                    
                    when others     => 
                        I2C_CLK_SPEED     <= 400_000;
                    
                end case;
			    elsif decr = '0' and prev_decr = '1' then
                case I2C_CLK_SPEED is
                    when 1_700_000 => 
                        I2C_CLK_SPEED     <= 400_000;
                        
                    when 400_000     => 
                        I2C_CLK_SPEED     <= 100_000;
                        
                    when 100_000     => 
                        I2C_CLK_SPEED    <= 1_700_000;
                        
                    when others => 
                        I2C_CLK_SPEED <= 400_000;
                        
                end case;
            
            end if;
				
				case I2C_CLK_SPEED is
					when 100_000 => LED8 <= "00000001";
					when 400_000 => LED8 <= "00000011";
					when 1_700_000 => LED8 <= "00000111";
					when others => LED8 <= "00000000";
					
				end case;
				
				prev_incr <= incr;
				prev_decr <= decr;
        end if;
		
        
    end process;
    

end ADJUSTING;