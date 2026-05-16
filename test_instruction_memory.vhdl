library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_instruction_memory is
end entity;

architecture Behavioral of test_instruction_memory is

    component instruction_memory
        port(
            addr : in  std_logic_vector(7 downto 0);
            CLK  : in  std_logic;
            out1 : out std_logic_vector(31 downto 0)
        );
    end component;

    signal addr     : std_logic_vector(7 downto 0) := x"00";
    signal CLK      : std_logic := '0';
    signal data_out : std_logic_vector(31 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    uut: instruction_memory port map (
        addr => addr,
        CLK  => CLK,
        out1 => data_out
    );

    CLK_process: process
    begin
        CLK <= '0';
        wait for CLK_PERIOD / 2;
        CLK <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    test_process: process
    begin
        wait for CLK_PERIOD;

        addr <= x"00";
        wait for CLK_PERIOD;
        assert data_out = x"06010500"
            report "FAIL addr 0x00: expected 0x06010500, got " & to_hstring(data_out)
            severity error;
        report "PASS addr 0x00: AFC R1 5 = 0x06010500" severity note;

        addr <= x"01";
        wait for CLK_PERIOD;
        assert data_out = x"06020300"
            report "FAIL addr 0x01: expected 0x06020300, got " & to_hstring(data_out)
            severity error;
        report "PASS addr 0x01: AFC R2 3 = 0x06020300" severity note;

        addr <= x"02";
        wait for CLK_PERIOD;
        assert data_out = x"01030102"
            report "FAIL addr 0x02: expected 0x01030102, got " & to_hstring(data_out)
            severity error;
        report "PASS addr 0x02: ADD R3 R1 R2 = 0x01030102" severity note;

        addr <= x"03";
        wait for CLK_PERIOD;
        assert data_out = x"02040102"
            report "FAIL addr 0x03: expected 0x02040102, got " & to_hstring(data_out)
            severity error;
        report "PASS addr 0x03: MUL R4 R1 R2 = 0x02040102" severity note;

        addr <= x"04";
        wait for CLK_PERIOD;
        assert data_out = x"03050302"
            report "FAIL addr 0x04: expected 0x03050302, got " & to_hstring(data_out)
            severity error;
        report "PASS addr 0x04: SOU R5 R3 R2 = 0x03050302" severity note;

        addr <= x"05";
        wait for CLK_PERIOD;
        assert data_out = x"04060302"
            report "FAIL addr 0x05: expected 0x04060302, got " & to_hstring(data_out)
            severity error;
        report "PASS addr 0x05: DIV R6 R3 R2 = 0x04060302" severity note;

        addr <= x"06";
        wait for CLK_PERIOD;
        assert data_out = x"05070100"
            report "FAIL addr 0x06: expected 0x05070100, got " & to_hstring(data_out)
            severity error;
        report "PASS addr 0x06: COP R7 R1 = 0x05070100" severity note;

        addr <= x"07";
        wait for CLK_PERIOD;
        assert data_out = x"080A0300"
            report "FAIL addr 0x07: expected 0x080A0300, got " & to_hstring(data_out)
            severity error;
        report "PASS addr 0x07: STORE @10 R3 = 0x080A0300" severity note;

        addr <= x"08";
        wait for CLK_PERIOD;
        assert data_out = x"07080A00"
            report "FAIL addr 0x08: expected 0x07080A00, got " & to_hstring(data_out)
            severity error;
        report "PASS addr 0x08: LOAD R8 @10 = 0x07080A00" severity note;

        addr <= x"FF";
        wait for CLK_PERIOD;
        assert data_out = x"00000000"
            report "FAIL addr 0xFF: expected 0x00000000, got " & to_hstring(data_out)
            severity error;
        report "PASS addr 0xFF: uninitialized = 0x00000000" severity note;

        report "All instruction memory tests complete" severity note;
        wait;

    end process;

end Behavioral;