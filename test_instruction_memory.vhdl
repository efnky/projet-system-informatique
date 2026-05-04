library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_instruction_memory is
end entity;

architecture Behavioral of test_instruction_memory is

    component instruction_memory
        port(
            addr: in std_logic_vector(7 downto 0);
            CLK: in std_logic;
            OUT: out std_logic_vector(31 downto 0)
        );
    end component;

    signal addr: std_logic_vector(7 downto 0);
    signal CLK: std_logic;
    signal data_out: std_logic_vector(31 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    begin
        uut: instruction_memory port map ( addr, CLK, data_out );
        CLK_process: process
        begin
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
        end process;

        -- not finished yet
        test_process: process
        begin
            addr <= x"00";
            wait for CLK_PERIOD;
            assert data_out = x"E0000000" report "Error: addr 0x00 should be 0xE0000000" severity error;

            addr <= x"01";
            wait for CLK_PERIOD;
            assert data_out = x"E0010001" report "Error: addr 0x01 should be 0xE0010001" severity error;

            addr <= x"02";
            wait for CLK_PERIOD;
            assert data_out = x"E0020002" report "Error: addr 0x02 should be 0xE0020002" severity error;

            addr <= x"03";
            wait for CLK_PERIOD;
            assert data_out = x"E0030003" report "Error: addr 0x03 should be 0xE0030003" severity error;

            addr <= x"FF";
            wait for CLK_PERIOD;
            assert data_out = x"00000000" report "Error: uninitialized addr 0xFF should be 0x00000000" severity error;

            wait;
        end process;
end Behavioral;