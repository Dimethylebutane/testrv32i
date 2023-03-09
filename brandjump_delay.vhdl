library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity Delayer is
    port (
        --ctrl
        clk : in std_logic;

        --JMP
        set1 : in std_logic;
        set2 : in std_logic;

        --Data
        out0 : out std_logic;
        out1 : out std_logic
    );
end Delayer;

architecture behaviour of Delayer is
    signal data : std_logic_vector(1 downto 0) := "00";
begin
    process(set1)
    begin
        if rising_edge(set1) then
            data(0) <= '1';
        end if;
    end process;

    out0 <= data(0);
    out1 <= data(1);

    process(set2)
    begin
        if rising_edge(set2) then
            data(1) <= '1';
        end if;
    end process;

    process(clk)
    begin
        if falling_edge(clk) then --change at falling edge bcs is an input of br&jmp process
            data(0) <= data(1);
            data(1) <= '0';
        end if;
    end process;

end behaviour;