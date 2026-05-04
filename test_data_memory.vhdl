library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_data_memory is
end test_data_memory;

architecture Behavioral of test_data_memory is

    component data_memory
        port(
            addr: in std_logic_vector(7 downto 0);
            IN: in std_logic_vector(7 downto 0);
            RW: in std_logic;
            RST: in std_logic;
            CLK: in std_logic;
            OUT: out std_logic_vector(7 downto 0)
        );
    end component;

    signal addr: std_logic_vector(7 downto 0);
    signal data_in: std_logic_vector(7 downto 0);
    signal RW: std_logic;
    signal RST: std_logic;
    signal CLK: std_logic;
    signal data_out: std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    begin
        uut: data_memory port map ( addr, data_in, RW, RST, CLK, data_out );

        CLK_process: process
        begin
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
        end process;

        test_process: process
        begin
            -- Initialize: reset the memory
            RST <= '0'; RW <= '1'; addr <= x"00"; data_in <= x"00";
            wait for 2 * CLK_PERIOD;

            -- Release reset, write 0x42 to address 0x01
            RST <= '1'; RW <= '0'; addr <= x"01"; data_in <= x"42";
            wait for CLK_PERIOD;

            -- Read back address 0x01 → expect 0x42
            RW <= '1'; addr <= x"01";
            wait for CLK_PERIOD;

            -- Verify reset clears data
            RST <= '0';
            wait for CLK_PERIOD;
            RST <= '1'; RW <= '1'; addr <= x"01";
            wait for CLK_PERIOD;

            -- OUT should be 0x00
            RST <= '1'; RW <= '0'; addr <= x"01"; data_in <= x"15";
            wait for CLK_PERIOD;

            -- Read back address 0x01 → expect 0x15
            RW <= '1'; addr <= x"01";
            wait for CLK_PERIOD;
            
            -- Verify reset clears data
            RST <= '0';
            wait for CLK_PERIOD;
            RST <= '1'; RW <= '1'; addr <= x"01";
            wait for CLK_PERIOD;

            wait;  -- stop
        end process;

end Behavioral;
