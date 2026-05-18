library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Test_ALU is
end Test_ALU;

architecture Behavioral of Test_ALU is

    component alu
        Port (
            A        : in  STD_LOGIC_VECTOR(7 downto 0);
            B        : in  STD_LOGIC_VECTOR(7 downto 0);
            Ctrl_Alu : in  STD_LOGIC_VECTOR(2 downto 0);
            S        : out STD_LOGIC_VECTOR(7 downto 0);
            N        : out STD_LOGIC;
            O        : out STD_LOGIC;
            Z        : out STD_LOGIC;
            C        : out STD_LOGIC
        );
    end component;

    signal a, b : std_logic_vector(7 downto 0);
    signal op   : std_logic_vector(2 downto 0);

    signal s    : std_logic_vector(7 downto 0);
    signal n, o, z, c : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    uut: alu port map (
        A        => a,
        B        => b,
        Ctrl_Alu => op,
        S        => s,
        N        => n,
        O        => o,
        Z        => z,
        C        => c
    );

    stim_proc: process
    begin
        -- Test 1: Addition 10 + 5 = 15
        a  <= "00001010";  -- 10
        b  <= "00000101";  -- 5
        op <= "001";
        wait for CLK_PERIOD;

        -- Test 2: Addition with carry 200 + 100 = 300 (overflow on 8 bits)
        a  <= "11001000";  -- 200
        b  <= "01100100";  -- 100
        op <= "001";
        wait for CLK_PERIOD;

        -- Test 3: Subtraction 20 - 5 = 15
        a  <= "00010100";  -- 20
        b  <= "00000101";  -- 5
        op <= "011";
        wait for CLK_PERIOD;

        -- Test 4: Subtraction resulting in 0 (Z flag)
        a  <= "00000111";  -- 7
        b  <= "00000111";  -- 7
        op <= "011";
        wait for CLK_PERIOD;

        -- Test 5: Subtraction with negative result (N flag)
        a  <= "00000011";  -- 3
        b  <= "00001010";  -- 10
        op <= "011";
        wait for CLK_PERIOD;

        -- Test 6: Multiplication 3 * 4 = 12
        a  <= "00000011";  -- 3
        b  <= "00000100";  -- 4
        op <= "010";
        wait for CLK_PERIOD;

        -- Test 7: Multiplication with overflow 16 * 16 = 256
        a  <= "00010000";  -- 16
        b  <= "00010000";  -- 16
        op <= "010";
        wait for CLK_PERIOD;

        -- Test 8: Default case (unknown opcode)
        a  <= "11111111";
        b  <= "11111111";
        op <= "111";
        wait for CLK_PERIOD;

        wait;
    end process;

end Behavioral;
