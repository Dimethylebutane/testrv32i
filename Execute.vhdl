library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity Ex is
    port (
        --ctrl
        clk : in std_logic;
        w_i : in std_logic;
        w_o : out std_logic;

        --Bus
        Imm_i   : in ImmPipe;
        Op_i    : in OpPipe;
        Reg_i   : in RegisterAddrPipe;
        
        Imm_o   : out ImmPipe   := (others => '0');
        rd_o    : out BUS_Type  := (others => '0');
        Op_o    : out std_logic_vector(1 downto 0);

        --TODO: if rd is rs in next instr => nop to WBr
        --TODO: if result is discared (eg. rd = 0 )=> nop to WB

        -- reg
        rs0_addr : out RegisterAddr;
        rs1_addr : out RegisterAddr;

        rs0 : in BUS_Type;
        rs1 : in BUS_Type
    );
end Ex;

architecture behaviour of Ex is
    signal w_internal : std_logic := "0";
begin
    --if stage is waiting then make upper stage to wait
    w_o <= "1" when w_internal = "1" else w_i;

    --route register addr
    rs1_addr <= Reg_i(1);
    rs1_addr <= Reg_i(2);

    process(clk)
    begin
        -- rinsing edge and not waiting
        if rising_edge(clk) and w_i /= "1" then
            --TODO: execute
        end if;
        if falling_edge(clk) then
            if w_o = "1" then --if wait send nop
                Imm_o <= Imm_i;
                Rd_o <= (others => '0'); --last stage before RegStore    
                Op_o <= "00";
            else
                Imm_o             <= Imm_i;
                Rd_o(4 downto 0)  <= Reg_i(0); --last stage before RegStore
                Rd_o(31 downto 5) <= (others => '0');
                Op_o <= "00"; --TODO
            end if;
        end if;
      end process;
end behaviour;