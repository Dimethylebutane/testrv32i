library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity PC is
    port (
        --ctrl
        clk : in std_logic;

        --JMP
        jmp : in std_logic;
        jmp_addr : in BUS_Type;
        zero : in std_logic;

        --Management
        w_i : in std_logic; --from fetch = from Br_and_Jmp % jmp signal
        w_o : out std_logic;

        --Data
        PC_addr : out BUS_type
    );
end PC;

architecture behaviour of PC is
    signal incVal : BUS_type;
    signal pcval : BUS_type;
begin

    w_o <= w_i;

    incVal <= x"00000004" when jmp = '0' else jmp_addr;
    pcval <= PC_addr when zero='0' else (others => '0');

    process(clk)
    begin
        -- PC work at rising edge bcs br&jmp may send addr at this time and bcs fetch work inverted
        -- (only one IR for front end, all is only logic circuit)
        if rising_edge(clk) and w_i /= "1" then
            PC_addr <= std_logic_vector(to_unsigned( to_integer(unsigned(pcval)) + to_integer(unsigned(incVal)) ));
        end if;
      end process;

end behaviour;