library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity Decode is
    port (
        --ctrl
        clk : in std_logic;
        w_i : in std_logic;
        w_o : out std_logic;

        --Bus
        DataB   : in BUS_Type;
        
        Imm_o   : out ImmPipe           := (others => '0');
        Op_o    : out OpPipe            := (others => '0');
        Reg_o   : out RegisterAddrPipe  := (others => '0')
    );
end Decode;

architecture behaviour of Decode is
    signal w_internal : std_logic := "0";

    signal opcode : std_logic_vector(6 downto 0);
begin
    --if stage is waiting then make upper stage to wait
    w_o <= "1" when w_internal = "1" else w_i;

    opcode <= DataB(6 downto 0);

    process(opcode) --Instruction LUT
    variable opc : std_logic_vector(4 downto 0) := opcode(6 downto 2);
    begin
        Op_o(6 downto 0) <= opcode;
        
        case opc is
            when "00_000" =>--LOAD      -I
                Imm_o(11 downto 0)  <= DataB(31 downto 20);
                Imm_o(31 downto 12) <= (others => DataB(31));--Sign extent
                
                Op_o(16 downto 10) <= (others => '0');
                Op_o(9 downto 7) <= DataB(14 downto 12);
        
                Reg(0) <= DataB(11 downto 7);
                Reg(1) <= DataB(19 downto 15);
                Reg(2) <= (others => '0');
            when "01_000" =>--Store     -S
                Imm_o(4 downto 0)  <= DataB(11 downto 7);
                Imm_o(11 downto 5)  <= DataB(31 downto 25);
                Imm_o(31 downto 12) <= (others => DataB(31));--Sign extent
                
                Op_o(16 downto 10) <= (others => '0');
                Op_o(9 downto 7) <= DataB(14 downto 12);
        
                Reg(0) <= (others => '0');
                Reg(1) <= DataB(19 downto 15);
                Reg(2) <= DataB(24 downto 20);
            when "11_000" =>--Branch    -B
                Imm_o(0) <= "0";
                Imm_o(4 downto 1)  <= DataB(11 downto 8);
                Imm_o(10 downto 5)  <= DataB(30 downto 25);
                Imm_o(11) <= DataB(7);
                Imm_o(12) <= DataB(31);
                Imm_o(31 downto 13) <= (others =>  DataB(31));--Sign extent
                
                Op_o(16 downto 10) <= (others => '0');
                Op_o(9 downto 7) <= DataB(14 downto 12);
        
                Reg(0) <= (others => '0');
                Reg(1) <= DataB(19 downto 15);
                Reg(2) <= DataB(24 downto 20);
            when "11_001" =>--JALR      -I
                Imm_o(11 downto 0)  <= DataB(31 downto 20);
                Imm_o(31 downto 12) <= (others => DataB(31));--Sign extent
                
                Op_o(16 downto 10) <= (others => '0');
                Op_o(9 downto 7) <= DataB(14 downto 12);
        
                Reg(0) <= DataB(11 downto 7);
                Reg(1) <= DataB(19 downto 15);
                Reg(2) <= (others => '0');
            when "00_011" =>--MISC-MEM  -I
                Imm_o(11 downto 0)  <= DataB(31 downto 20);
                Imm_o(31 downto 12) <= (others => DataB(31));--Sign extent
                
                Op_o(16 downto 10) <= (others => '0');
                Op_o(9 downto 7) <= DataB(14 downto 12);
        
                Reg(0) <= DataB(11 downto 7);
                Reg(1) <= DataB(19 downto 15);
                Reg(2) <= (others => '0');
            when "11_011" =>--JAL       -J
                Imm_o(0) <= "0";
                Imm_o(10 downto 1)  <= DataB(30 downto 21);
                Imm_o(11)  <= DataB(20);
                Imm_o(19 downto 12)  <= DataB(19 downto 12);
                Imm_o(20) <= DataB(31);
                Imm(31 downto 21) <= (others => DataB(31));--sign extent

                Op_o(16 downto 10) <= (others => '0');
                Op_o(9 downto 7) <= (others => '0');
        
                Reg(0) <= DataB(11 downto 7);
                Reg(1) <= (others => '0');
                Reg(2) <= (others => '0');
            when "00_100" =>--OP-IMM    -I
                Imm_o(11 downto 0)  <= DataB(31 downto 20);
                Imm_o(31 downto 12) <= (others => DataB(31));--Sign extent
                
                Op_o(16 downto 10) <= (others => '0');
                Op_o(9 downto 7) <= DataB(14 downto 12);
        
                Reg(0) <= DataB(11 downto 7);
                Reg(1) <= DataB(19 downto 15);
                Reg(2) <= (others => '0');
            when "01_100" =>--OP        -R
                Imm_o <= (others => '0');
            
                Op_o(16 downto 10) <= DataB(31 downto 25);
                Op_o(9 downto 7) <= DataB(14 downto 12);
        
                Reg(0) <= DataB(11 downto 7);
                Reg(1) <= DataB(19 downto 15);
                Reg(2) <= DataB(24 downto 20);
            when "11_100" =>--SYSTEM    -I
                Imm_o(11 downto 0)  <= DataB(31 downto 20);
                Imm_o(31 downto 12) <= (others => DataB(31));--Sign extent
                
                Op_o(16 downto 10) <= (others => '0');
                Op_o(9 downto 7) <= DataB(14 downto 12);
        
                Reg(0) <= DataB(11 downto 7);
                Reg(1) <= DataB(19 downto 15);
                Reg(2) <= (others => '0');
            when "00_101" =>--AUIPC     -U
                Imm_o(31 downto 12)  <= DataB(31 downto 12);
                Imm_o(11 downto 0) <= (others => '0');
                    
                Op_o(16 downto 10) <= (others => '0');
                Op_o(9 downto 7) <= (others => '0');
        
                Reg(0) <= DataB(11 downto 7);
                Reg(1) <= (others => '0');
                Reg(2) <= (others => '0');
            when "01_101" =>--LUI       -U
                Imm_o(31 downto 12)  <= DataB(31 downto 12);
                Imm_o(11 downto 0) <= (others => '0');
                    
                Op_o(16 downto 10) <= (others => '0');
                Op_o(9 downto 7) <= (others => '0');
        
                Reg(0) <= DataB(11 downto 7);
                Reg(1) <= (others => '0');
                Reg(2) <= (others => '0');
            when others =>--INVALID TODO: trap
                Imm_o <= (others => '0');
                Op_o <= (others => '0');
                Reg_o <= (others => '0');
        end case;
    end process;

    process(clk)
    begin
        if rising_edge(clk) and w_i /= "1" then
            --TODO: Do work
        end if;
        if falling_edge(clk) then --pass work
            if w_o = "1" then --we are waiting
                Imm_o <= (others => '0');
                Op_o  <= (others => '0');
                Reg_o <= (others => '0');
            else
                Imm_o <= Imm_i;
                Op_o  <= Op_i;
                Reg_o <= Reg_i;
            end if;
        end if;
      end process;

end behaviour;