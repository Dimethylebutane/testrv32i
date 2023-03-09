library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity Reg is
    port (
        clk : in std_logic;

        --Input management
        INPT : in BUS_type;
        slct : in std_logic;
        OP   : in std_logic_vector(2 downto 0); --Nop, set, setIfLd, rstLD, rstJM
            -- 000 : Nop (= rst LD)
            -- 001 : set
            -- -11 : set if ld
            -- 100 : set LD
            -- 110 : Nop (set JM)
            -- 010 : rst JM
        setJM : in std_logic;

        --output value
        outp_val : out BUS_Type;
        ld_flag  : out std_logic; --usefull?
        jm_flag  : out std_logic; --usefull? -> if 2 jalr wth same reg, pause until resolve (else may cause issue bcs rst by first jalr)

        FlushJalr : out std_logic
    );
end Reg;

architecture behaviour of Reg is
    signal Data : BUS_Type := (others => '0');
    signal ldData : std_logic := '0';
    signal jmData : std_logic := '0';

    signal updt : std_logic;

    signal outp_internal : BUS_Type;
begin
    --condition on which store the input value
    updt <= slct and (ldData or not OP(1)) and OP(0);
         -- slct * (LD + !checkLD) * OpIsSetValue

    --value to output
    outp_internal <= Data when updt = '0' else INPT;


    --TODO: JM flag : if decode fetch a register that is being update, flush instant the pipe so decode has to wait
    FlushJalr <= '1' when (updt = '1' and jmData = '1') else 'L'; --if update when JM flag is set then trigger pipe flush

    --output port
    outp_val <= outp_internal;
    jm_flag  <= jmData;
    ld_flag  <= ldData and not updt;

    process(clk)
    begin
        if rising_edge(clk) then
            Data <= outp_internal; --store
            
            --set rst LD
            if OP = "100" and slct = '1' then
                ldData <= '1';
            end if;
            if updt = '1' then --updt already use slct
                ldData <= '0';
            end if;
            
            --set rst JM
            if setJM = '1' and slct = '1' then --set jm
                jmData <= '1';
            end if;
            if OP = "010" and slct = '1' then --rst jm
                jmData <= '0';
            end if;
        end if;
    end process;
end behaviour;