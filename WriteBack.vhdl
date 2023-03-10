library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

-- => WB never sleep
entity WriteBack is
    port (
        -- ctrl
        clk : in std_logic;

        -- Bus-Ex
        Imm_i   : in ImmPipe;   --result of Execute
        Op_i    : in std_logic_vector(1 downto 0);--Store Operation (nop, WB, load, store), load and store are async ram operation
        Reg_i   : in BUS_Type;  --Register part (32 bit bcs may hold an adress (ram operation))
        Jalr_i  : in std_logic; --Jalr instruction, reset jm flag of register Reg_i[4:0]

        -- LDST
        MemReq  : out MEMORY_REQUEST;
        MemResp : in MEMORY_RESPONSE;
        MemAckresp : out std_logic;
        MemSendReq : out std_logic;

        -- reg
        rd_addr    : out RegisterAddr;
        rd_val     : out BUS_Type;
        rd_Op      : out std_logic_vector(2 downto 0); --shall Register consider LD flag before updating value?
        rd_resetJM : out std_logic

        -- Front-end
        jmp_sig : out std_logic;
    );
end WriteBack;

architecture behaviour of WriteBack is
    signal w_internal : std_logic := '0';

    --signal for Memory to Register op
    signal i_Reg_addr  : BUS_Type := (others => 'L');
    signal i_Reg_value : BUS_Type := (others => 'L');
begin

    --route register addr and value (based on Op)
    i_Reg_addr  <= Reg_i when Op_i = "01" else  std_logic_vector(resize(unsigned(MemResp.Reg), i_Reg_addr'length));
    i_Reg_value <= Imm_i when Op_i = "01" else MemResp.val;
    
    rd_Op <= "010" when Jalr_i = '1' else      -- JALR (rst jm)
             "001" when Op_i = "01" else       -- WB
             "111" when Op_i(0) = Op_i(1) else -- MemResp
             "100" when Op_i = "10" else       -- Load (set ld)
             "000";                            -- NOP

    rd_addr(4 downto 0) <= i_Reg_addr(4 downto 0);
    rd_addr(5) <= '0';
    rd_val  <= i_Reg_value;



    --MemReq
    MemReq.addr <= Imm_i;
    MemReq.op   <= Op_i(0); -- !load/store
    MemReq.val  <= i_Reg_addr;
    MemSendReq  <= Op_i(1); --The operation involve memory access
    MemAckresp  <= '1' when Op_i /= "01" else '0' ; --ack MemResp (fifo go next response)
        --If MemResp is empty then addr shall be 0 and write is discard_valed

end behaviour;