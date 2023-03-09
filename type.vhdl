library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is --RV32I

    subtype byte is std_logic_vector(7 downto 0); --bit 0 is lsb, 8bit
    subtype halfword is std_logic_vector(15 downto 0); --bit 0 is lsb, 16bit
    subtype word is std_logic_vector(31 downto 0); --bit 0 is lsb, 32bit
    
    subtype BUS_type is STD_LOGIC_VECTOR(31 downto 0); --bit 0 is lsb, 32bit

    -- Register
        type RegisterData is record
            val : word;
            ld  : std_logic;
            jm  : std_logic;
        end record RegisterData;

            --Bus matrix
        type RegisterMatrix is array(0 to 31+2) of RegisterData;

            --type alias for register address
        subtype RegisterAddr is std_logic_vector(5 downto 0);
            --Mapping:
                -- 0 : R0
                -- 1 to 31 : registers
                -- 32 : shadow 0 = ACR
                -- 33 : shadow 1 = Condition
    
    -- Data flow
    type RegisterAddrPipe is array(2 downto 0) of RegisterAddr; -- rs1, rs0, rd
    subtype OpPipe is std_logic_vector(16 downto 0);            --fn9-0, opcode
    subtype ImmPipe is BUS_Type;

    --LDST
    type MEMORY_REQUEST is record
        addr : BUS_Type;
        op   : std_logic; --0 is load, 1 is store
        val  : BUS_Type;
    end record MEMORY_REQUEST;

    type MEMORY_RESPONSE is record
        val : BUS_Type;
        Reg : RegisterAddr;
    end record MEMORY_RESPONSE;

end types;