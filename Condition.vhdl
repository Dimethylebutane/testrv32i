library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity Condition is
  port (
    clk: in std_logic;

    val : in BUS_type;
    cond : out std_logic_vector(1 downto 0) --[Z, N]
    );
end Condition;

architecture behaviour of Condition
is
begin
    cond(0) <= '1' when signed(val) = 0 else '0';
    cond(1) <= '1' when signed(val) < 0 else '0';
end behaviour;