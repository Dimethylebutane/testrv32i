library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity RegCntrll is
    port (
        --ctrl
        clk : in std_logic;

        --OUT 0  RS1
        addr_o0 : in RegisterAddr;
        dbus_o0 : out BUS_type := (others => 'Z');
        f0 : out std_logic_vector(1 downto 0);

        --OUT 1  RS2
        addr_o1 : in RegisterAddr;
        dbus_o1 : out BUS_type := (others => 'Z');
        f1 : out std_logic_vector(1 downto 0);
            -- +Decode & Jmp conn

        --WB conn
        addr_i : in RegisterAddr;
        dbus_i : in BUS_type := (others => 'Z');
        fwb_op : in std_logic_vector(2 downto 0) --see Register OP
    );
end RegCntrll;

architecture behaviour of RegCntrll is
    signal registersMat : RegisterMatrix;

    signal selct : std_logic_vector(31+2 downto 1) := (others => 'L');

    signal setJM : std_logic;
    signal internal_busy : std_logic;

    signal addr_1_internal : RegisterAddr;
begin

    addr_1_internal <= addr_o1;

    GEN_REG: for i in 1 to 31+2 generate
        REGX : entity work.Reg(behaviour) port map
            (clk => clk,
            outp_val => registersMat(i).val, ld_flag => registersMat(i).ld, jm_flag => registersMat(i).jm,
            INPT => dbus_i, slct => selct(i), OP => fwb_op, setJM => setJM
            );
        selct(i) <= '1' when unsigned(addr_i) = to_unsigned(i, 5) else '0';
    end generate GEN_REG;

    --pull down for R0:
    registersMat(0).val <= (others => '0');
    registersMat(0).ld <= '0';
    registersMat(0).jm <= '0';

    --output value on busses
    dbus_o0 <= registersMat(to_integer( unsigned(addr_o0) )).val;
    dbus_o1 <= registersMat(to_integer( unsigned(addr_1_internal) )).val;
    
    f0(0) <= registersMat(to_integer( unsigned(addr_o0) )).ld;
    f0(1) <= registersMat(to_integer( unsigned(addr_o0) )).jm;
    
    f1(0) <= registersMat(to_integer( unsigned(addr_1_internal) )).ld;
    f1(1) <= registersMat(to_integer( unsigned(addr_1_internal) )).jm;
end behaviour;