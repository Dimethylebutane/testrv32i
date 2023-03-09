library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity Fetch is
    port (
        --ctrl
        clk : in std_logic;

        --RAM
        RAM_data_bus : in  BUS_Type;
        RAM_addr_bus : out BUS_Type;
        
        --PC
        PC         : in BUS_Type;
        PC_is_wait : in std_logic;
        PC_to_wait : out std_logic;

        --LDST
        LS_data : in BUS_Type;
        LS_addr : in BUS_Type;

        --Decode
        Instr : out BUS_Type
    );
end Fetch;

architecture behaviour of Fetch is
    signal addr : BUS_Type;
begin

    addr <= PC when "1" = "1" else (others => 'L');

    process(clk)
    begin
        if rising_edge(clk) and w_i /= "1" then
            --TODO: Do work
        end if;
        if falling_edge(clk) and w_o /= "1" then --pass work
            Imm_o <= Imm_i;
            Op_o <= Op_i;
            Reg_o <= Reg_i;
        end if;
      end process;

end behaviour;