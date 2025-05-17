library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity decode_tb is
end decode_tb;

architecture Behavioral of decode_tb is
    component decode
        port (
            instruction : in  STD_LOGIC_VECTOR(31 downto 0);
            clock       : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            RegDst      : in  STD_LOGIC;
            RegWrite    : in  STD_LOGIC;
            MemToReg    : in  STD_LOGIC;
            memory_data : in  STD_LOGIC_VECTOR(31 downto 0);
            alu_result  : in  STD_LOGIC_VECTOR(31 downto 0);
            register_rs : out STD_LOGIC_VECTOR(31 downto 0);
            register_rt : out STD_LOGIC_VECTOR(31 downto 0);
            immediate   : out STD_LOGIC_VECTOR(31 downto 0);
            jump_addr   : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    -- Signals
    signal instruction : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal clock       : STD_LOGIC := '0';
    signal reset       : STD_LOGIC := '0';
    signal RegDst      : STD_LOGIC := '0';
    signal RegWrite    : STD_LOGIC := '0';
    signal MemToReg    : STD_LOGIC := '0';
    signal memory_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal alu_result  : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal register_rs, register_rt, immediate, jump_addr : STD_LOGIC_VECTOR(31 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    signal test_passed : boolean := true;

    function slv_to_hexstr(slv : STD_LOGIC_VECTOR) return STRING is
        constant hex_chars : STRING := "0123456789ABCDEF";
        variable result : STRING(1 to slv'length / 4);
        variable i, nibble : INTEGER;
    begin
        for j in 0 to (slv'length / 4 - 1) loop
            nibble := to_integer(unsigned(slv(slv'length - 1 - j * 4 downto slv'length - 4 - j * 4)));
            result(j + 1) := hex_chars(nibble + 1);
        end loop;
        return result;
    end function;

begin
    -- Instantiate DUT
    uut: decode port map (
        instruction => instruction,
        clock => clock,
        reset => reset,
        RegDst => RegDst,
        RegWrite => RegWrite,
        MemToReg => MemToReg,
        memory_data => memory_data,
        alu_result => alu_result,
        register_rs => register_rs,
        register_rt => register_rt,
        immediate => immediate,
        jump_addr => jump_addr
    );

    -- Clock generation
    clock <= not clock after CLK_PERIOD / 2;

    -- Test process
    stimulus: process
        procedure check_output(
            name     : string;
            actual   : STD_LOGIC_VECTOR(31 downto 0);
            expected : STD_LOGIC_VECTOR(31 downto 0)) is
        begin
            if actual /= expected then
                report "ERROR: " & name & " mismatch";
                report "  Expected: " & slv_to_hexstr(expected);
                report "  Actual:   " & slv_to_hexstr(actual);
                test_passed <= false;
            end if;
        end procedure;
    begin
        -- Reset system
        reset <= '1';
        wait for CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;

        ----------------------------------------------------------------------
        -- Test 1: R-type ADD ($3 = $1 + $2) - ALU writeback
        ----------------------------------------------------------------------
        instruction <= "000000" & "00001" & "00010" & "00011" & "00000" & "100000";
        RegDst <= '1';      -- Select rd = 3
        RegWrite <= '1';
        MemToReg <= '0';
        alu_result <= X"AAAAAAAA";
        wait for CLK_PERIOD;
        check_output("register_rs", register_rs, X"11111111");
        check_output("register_rt", register_rt, X"22222222");

        ----------------------------------------------------------------------
        -- Test 2: I-type LW with negative offset (-4)
        ----------------------------------------------------------------------
        instruction <= "100011" & "00100" & "00101" & "1111111111111100";
        RegDst <= '0';      -- Select rt = 5
        RegWrite <= '1';
        MemToReg <= '1';
        memory_data <= X"BBBBBBBB";
        wait for CLK_PERIOD;
        check_output("immediate", immediate, X"FFFFFFFC");

        ----------------------------------------------------------------------
        -- Test 3: J-type Jump to 0x0000000C
        ----------------------------------------------------------------------
        instruction <= "000010" & "00000000000000000000000011";
        RegWrite <= '0';
        wait for CLK_PERIOD;
        check_output("jump_addr", jump_addr, X"0000000C");

        ----------------------------------------------------------------------
        -- Test 4: Attempt write to register 0 (should be ignored)
        ----------------------------------------------------------------------
        instruction <= "000000" & "00001" & "00010" & "00000" & "00000" & "100000";
        RegDst <= '1';      -- rd = 0
        RegWrite <= '1';
        MemToReg <= '0';
        alu_result <= X"DEADBEEF";
        wait for CLK_PERIOD;

        -- Re-read rs = 0 to verify it didn't change
        instruction <= "000000" & "00000" & "00000" & "00001" & "00000" & "100000";  -- rs = 0
        RegWrite <= '0';
        wait for CLK_PERIOD;
        check_output("register_rs (reg 0)", register_rs, X"00000000");

        ----------------------------------------------------------------------
        -- Test 5: Immediate = 0x7FFF (positive max 16-bit)
        ----------------------------------------------------------------------
        instruction <= "001000" & "00001" & "00010" & "0111111111111111";
        RegWrite <= '0';
        wait for CLK_PERIOD;
        check_output("immediate (0x7FFF)", immediate, X"00007FFF");

        ----------------------------------------------------------------------
        -- Test 6: Immediate = 0x8000 (negative min 16-bit)
        ----------------------------------------------------------------------
        instruction <= "001000" & "00001" & "00010" & "1000000000000000";
        RegWrite <= '0';
        wait for CLK_PERIOD;
        check_output("immediate (0x8000)", immediate, X"FFFF8000");

        ----------------------------------------------------------------------
        -- Final Result
        ----------------------------------------------------------------------
        wait for CLK_PERIOD;
        if test_passed then
            report "=== ALL TESTS PASSED ===" severity note;
        else
            report "=== SOME TESTS FAILED ===" severity error;
        end if;
        wait;
    end process;
end Behavioral;
