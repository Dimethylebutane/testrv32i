library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity BrAndJmp is
    port (
        --ctrl
        clk : in std_logic;
        w_i : in std_logic;
        w_o : out std_logic;

        --PC
        PC : in BUS_type;
        PC_jmp : out std_logic;
        PC_zer : out std_logic;

        --Bus
        Imm_i   : in ImmPipe;
        Op_i    : in OpPipe;
        Reg_i   : in RegisterAddrPipe;
        
        Imm_o   : out ImmPipe           := (others => '0');
        Reg_o   : out RegisterAddrPipe  := (others => '0');
        Op_o    : out OpPipe            := (others => '0')
    );
end BrAndJmp;

architecture behaviour of BrAndJmp is
    signal w_internal : std_logic := "0";

    signal Imm   : ImmPipe;
    signal Op    : OpPipe;
    signal Reg   : RegisterAddrPipe;

    --signal usePC : std_logic;
        signal AUIPC_sig : std_logic;
        signal JAL_sig : std_logic;
        signal JALR_sig : std_logic;
        signal Branch_sig : std_logic;

    signal delay_sig : std_logic_vector(1 downto 0);
    signal delay_set : std_logic_vector(1 downto 0);

    signal delayCLK : std_logic;
begin
    delayCLK <= (clk and not w_i); --do not shift if waiting
    delay: entity work.Delayer(behaviour) port map(clk => delayCLK,
        set1 => delay_set(0), set2 => delay_set(1),
        out0 => delay_sig(0), out1 => delay_sig(1));

    --if stage is waiting then make upper stage to wait
    w_o <= "1" when w_internal = "1" else w_i;

    w_internal <= delay(0) or delay(1); --wait if delay

    --detect instruction that uses PC
        --TODO: smaller condition that set flag, if more than 1 flag then not usePC and condition are easier to compute
    AUIPC_sig   <= '1' when Op_i(6 downto 0) = "0010111" else '0';
    JAL_sig     <= '1' when Op_i(6 downto 0) = "1101111" else '0';
    JALR_sig    <= '1' when Op_i(6 downto 0) = "1100111" else '0';
    Branch_sig  <= '1' when Op_i(6 downto 0) = "1100011" else '0';
    --    usePc <= JALR_sig or JAL_sig or AUIPC_sig or Branch_sig;

    --set delay based on Op
    delay_set(0) <= '1' when (JAL_sig or JALR_sig or AUIPC_sig or Branch_sig) 
                    else '0';
    delay_set(1) <= '0';

    --JALR is weird bcs of inverted jmp then addi
    PC_jmp <= (JAL_sig or JALR_sig or Branch_sig) and delay_set(0);
    PC_zer <= JALR_sig and not delay_set(0);

    --pass uOp based on Op and delay state
    process(Op_i, delay_sig)
        variable op : std_logic_vector(3 downto 0) := (AUIPC_sig, JAL_sig, JALR_sig, Branch_sig);
    begin
        --JMP uOp:
        --  JMP rs1, IMM   and BR(fnct3) rs1, rs2 (rd must always be resp. sh1 = ACR and sh0 = COND)
        --  opcode: 1100c11 (= jalr RV32I opcode with c = 1, else branch) (exactly same as JALR and branch RV32 instruction)
        --  fnct[3:0]: <.u.i (same as branch fnct3 of rv32)
        --      flag:
        --          c : if not set : ignore condition and jmp at rs1 + Imm - 4 (ignore rs2) (JMP)
        --              if set     : if condition(rs1, rs2) then jmp at sh - 4 (ignore Imm) (BR for branch)
        --          u : interpret as unsigned
        --          i : invert condition
        --          < : 
        --              - '0' : val = 0
        --              - '1' : val < 0
        --                   c_fnct3
        --          -> beq : 1_0-0
        --          -> bne : 1_0u1
        --          -> blt : 1_1u0
        --          -> bge : 1_1u1 (could also blt with inverted rs1 and rs2)
        --          -> JAL : 0_--- (always jmp)
        -- idea: ACR = 32b addr + 1b ack
        -- ack <= !c or (value <ui 0), if not ack then front end will ignore value and nothing happen, else : flush pipe and update PC
        -- PC ALU is controlled by Br&Jmp and can do PC*!zero + 4 or PC*!zero + IMM
        -- ISSUE: when br: should be not taken by default, ADDI sh1, r0, PC | ADDI sh1, sh1, Imm | br(f3) rs1, rs2 but 3 clk

        -- TODO: PC jmp_addr 32b bus not set
        case op is
            --PC_jmp and PC_zero signal are defined above
            when "1000" => --AUIPC
                if delay_sig(0) then        --ADDI rd, r0, PC ok
                    Reg(0) <= Reg_i(0); --rd
                    Reg(1) <= "00000";  --r0
                    Reg(2) <= "00000";  --dnc
                    Imm <= PC;
                    Op(6 downto 0) <= "0010011";--addi
                    Op(16 downto 7) <= (others => '0');
                else                        --ADDI rd, rd, IMM ok
                    Reg(0) <= Reg_i(0);--rd
                    Reg(1) <= Reg_i(0);--rd
                    Reg(2) <= "00000"; --dnc
                    Imm <= Imm_i;
                    Op(6 downto 0) <= "0010011";--addi
                    Op(16 downto 7) <= (others => '0');
                end if;
            when "0100" => --Jal
                if delay_sig(0) then        --ADDI rd, r0, PC  &&  PC <= PC + Imm ok
                    Reg(0) <= Reg_i(0); --rd
                    Reg(1) <= "00000";  --r0
                    Reg(2) <= "00000";  --dnc
                    Imm <= PC;
                    Op(6 downto 0) <= "0010011"; --ADDI
                    Op(16 downto 7) <= (others => '0');
                else                        --ADDI rd, rd, 4 ok
                    Reg(0) <= Reg_i(0); --sh1
                    Reg(1) <= Reg_i(0); --sh1
                    Reg(2) <= "00000";  --dnc
                    Imm <= std_logic_vector(to_unsigned(4, 32));
                    Op(6 downto 0) <= "0010011"; --ADDI
                end if;
            when "0010" => --JALR
                if delay_sig(0) then        --Jmp rs1, Imm  &&  PC <= PC+4 <- jmp not the last uOP so be carefull when flushing pipe ok
                    Reg(0) <= "11111"; --sh1 TODO
                    Reg(1) <= Reg_i(1);--rs1
                    Reg(2) <= "00000"; --dnc
                    Imm <= Imm_i;
                    Op(16 downto 3) <= Op_i(16 downto 3);
                    Op(1 downto 0)  <= Op_i(1 downto 0); --jalr
                    Op(2) <= Op_i(2); --jalr
                else                        --ADDI rd, r0, PC (PC is now PC+4) ok
                    Reg(0) <= Reg_i(0); --rd
                    Reg(1) <= "00000";  --r0
                    Reg(2) <= "00000";  --dnc
                    Imm <= PC;          --PC
                    Op(6 downto 0) <= "0010011";--addi
                    Op(16 downto 7) <= (others => '0');
                end if;
            when "0001" => --BRANCH taken, if not then sh1 is PC, need to pc + 4???
                if delay_sig(0) then        --ADDI sh1, r0, PC  &&  PC <= PC + Imm ok
                    Reg(0) <= Reg_i(0); --rd
                    Reg(1) <= "00000";  --r0
                    Reg(2) <= "00000";  --dnc
                    Imm <= PC;
                    Op(6 downto 0) <= "0010011";--addi
                    Op(16 downto 7) <= (others => '0');
                else                        --BR(f3) rs1, rs2 : PC <= sh1 - 0 = PC + IMM -0
                    Reg(0) <= "11111"; --sh0 todo: shadow register
                    Reg(1) <= Reg_i(1);--rs1
                    Reg(2) <= Reg_i(2);--rs2
                    Imm <= std_logic_vector(to_unsigned(-4, 32));
                    Op <= Op_i; --branch
                end if;
            when others =>
                Reg <= Reg_i;
                Imm <= Imm_i;
                Op <= Op_i;
        end case;
    end process;

    --Flush ?
    --adress compute return?

    process(clk)
    begin
        -- rinsing edge and not waiting
        if rising_edge(clk) and w_i='0' then
            --do work here
        end if;
        if falling_edge(clk) then
            if w_i = "1" then --if below wait send nop
                Imm_o <= (others => '0');
                Reg_o <= (others => '0');
                Op_o  <= (others => '0');
            else --pass processed instruction
                Imm_o <= Imm;
                Reg_o <= Reg;
                Op_o  <= Op;
            end if;
        end if;
      end process;
end behaviour;