library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity test_bench is
end test_bench;
  
  architecture behaviour of test_bench
  is
    --clock
    signal clk : std_logic;
    
    --register
    signal RegBus_i  : BUS_type ;
    signal RegBus_o0 : BUS_type ;
    signal RegBus_o1 : BUS_type ;

    signal RegAddr_i  : RegisterAddr := (others => 'L');
    signal RegAddr_o0 : RegisterAddr := (others => 'L');
    signal RegAddr_o1 : RegisterAddr := (others => 'L');

    signal RegFlag0  : std_logic_vector(1 downto 0);
    signal RegFlag1  : std_logic_vector(1 downto 0);
    signal RegFlagWB_Op : std_logic_vector(2 downto 0);

    --WriteBack
    signal WB_Imm_i : ImmPipe := (others => 'L');
    signal WB_Reg_i : BUS_Type := (others => 'L');
    signal WB_Op_i  : std_logic_vector(1 downto 0) := "LL";
    signal WB_jalr  : std_logic := 'L';

    --LdSt
    signal MemReq  : MEMORY_REQUEST  := ( addr => (others => 'L'), op => 'L', val => (others => 'L'));
    signal MemResp : MEMORY_RESPONSE := ( val => ('1', others => '0'), Reg => "00010");
    signal MemAckresp : std_logic := 'L';
    signal MemSendReq : std_logic := 'L';

    --DnJ (decode and jmp)
    

  begin
    clk0: entity work.heartbeat(behaviour) port map(clk => clk);

    WB: entity work.WriteBack(behaviour) port map(clk => clk,
      --w_i => '0', --wait sig
      MemReq => MemReq, MemResp => MemResp, MemAckresp => MemAckresp, MemSendReq => MemSendReq, --LDST conn
      rd_val => RegBus_i, rd_addr => RegAddr_i, rd_Op => RegFlagWB_Op, jalr_i => WB_jalr, --register conn
      Imm_i => WB_Imm_i, Reg_i => WB_Reg_i, op_i => WB_Op_i --Ex conn
      );

    Registers: entity work.RegCntrll(behaviour) port map(clk => clk,
      dbus_o0 => RegBus_o0, dbus_o1 => RegBus_o1, dbus_i => RegBus_i,
      addr_o0 => RegAddr_o0, addr_o1 => RegAddr_o1, addr_i => RegAddr_i,
      f0 => RegFlag0, f1 => RegFlag1, fwb_op => RegFlagWB_Op
      );

    process
    begin
      --start
      wait until falling_edge(clk);

      --WB NOP => read MemResp
      --WB_Op_i <= "00";
      --wait until falling_edge(clk);

      --WB wb
      WB_Op_i <= "01";

      RegAddr_o0 <= "00001";
      RegAddr_o1 <= "00000";
      WB_Imm_i <= (others => '1');

      --set registers (1 to 4) to -1
      for i in 0 to 4 loop
        WB_Reg_i <= std_logic_vector( to_unsigned(i, WB_Reg_i'length) );
        wait until falling_edge(clk);
      end loop;

      --WB NOP => read MemResp
      WB_Op_i <= "00";
      wait until falling_edge(clk);

      --WB wb
      WB_Op_i <= "01";
      WB_Imm_i <= (others => '0');

      --set registers (1 to 4) to 0
      for i in 1 to 4 loop
        WB_Reg_i <= std_logic_vector( to_unsigned(i, WB_Reg_i'length) );
        wait until falling_edge(clk);
      end loop;

      wait for 20 ns;
      report "End of simulation" severity failure;
    end process;

  end behaviour;