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
        procedure check_output(test_name : string; signal_name : string;
                               actual, expected : STD_LOGIC_VECTOR(31 downto 0)) is
        begin
            if actual = expected then
                report "PASS: " & test_name & " - " & signal_name & " OK.";
            else
                report "FAIL: " & test_name & " - " & signal_name;
                report "  Expected: " & slv_to_hexstr(expected);
                report "  Actual:   " & slv_to_hexstr(actual);
                test_passed <= false;
            end if;
        end procedure;

    begin
        -- Reset
        reset <= '1';
        wait for CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;

        -- === TEST 1: R-type ADD ===
        instruction <= "000000" & "00001" & "00010" & "00011" & "00000" & "100000";
        RegDst <= '1'; RegWrite <= '1'; MemToReg <= '0';
        alu_result <= X"AAAAAAAA";
        wait for CLK_PERIOD;
        check_output("R-type ADD", "register_rs", register_rs, X"11111111");
        check_output("R-type ADD", "register_rt", register_rt, X"22222222");

        -- === TEST 2: I-type LW (offset -4) ===
        instruction <= "100011" & "00100" & "00101" & "1111111111111100";
        RegDst <= '0'; RegWrite <= '1'; MemToReg <= '1';
        memory_data <= X"BBBBBBBB";
        wait for CLK_PERIOD;
        check_output("I-type LW", "immediate", immediate, X"FFFFFFFC");

        -- === TEST 3: J-type jump to 0x0000000C ===
        instruction <= "000010" & "00000000000000000000000011";
        RegWrite <= '0';
        wait for CLK_PERIOD;
        check_output("Jump", "jump_addr", jump_addr, X"0000000C");

        -- === TEST 4: Write to register 0 (ignore) ===
        instruction <= "000000" & "00001" & "00010" & "00000" & "00000" & "100000";
        RegDst <= '1'; RegWrite <= '1'; MemToReg <= '0';
        alu_result <= X"DEADBEEF";
        wait for CLK_PERIOD;

        instruction <= "000000" & "00000" & "00000" & "00001" & "00000" & "100000";
        RegWrite <= '0';
        wait for CLK_PERIOD;
        check_output("Write to R0", "register_rs (reg 0)", register_rs, X"00000000");

        -- === TEST 5: Immediate = 0x7FFF ===
        instruction <= "001000" & "00001" & "00010" & "0111111111111111";
        RegWrite <= '0';
        wait for CLK_PERIOD;
        check_output("Immediate 0x7FFF", "immediate", immediate, X"00007FFF");

        -- === TEST 6: Immediate = 0x8000 ===
        instruction <= "001000" & "00001" & "00010" & "1000000000000000";
        RegWrite <= '0';
        wait for CLK_PERIOD;
        check_output("Immediate 0x8000", "immediate", immediate, X"FFFF8000");

        -- === TEST 7: Boundary jump address near 0xFFFFFFFC ===
        instruction <= "000010" & "11111111111111111111111111";  -- index = 0x3FFFFFF
        wait for CLK_PERIOD;
        check_output("Jump max", "jump_addr", jump_addr, X"0FFFFFFC");

        -- === TEST 8: R-type SUB ===
        instruction <= "000000" & "00001" & "00010" & "00100" & "00000" & "100010";
        RegDst <= '1'; RegWrite <= '1'; MemToReg <= '0';
        alu_result <= X"12345678";
        wait for CLK_PERIOD;
        check_output("R-type SUB", "register_rs", register_rs, X"11111111");

        -- === TEST 9: R-type AND ===
        instruction <= "000000" & "00001" & "00010" & "00101" & "00000" & "100100";
        alu_result <= X"CAFEBABE";
        wait for CLK_PERIOD;
        check_output("R-type AND", "register_rt", register_rt, X"22222222");

        -- === TEST 10: R-type OR ===
        instruction <= "000000" & "00001" & "00010" & "00110" & "00000" & "100101";
        alu_result <= X"0BADBEEF";
        wait for CLK_PERIOD;
        check_output("R-type OR", "register_rs", register_rs, X"11111111");

        -- === TEST 11: RegDst = 0, write to rt ===
        -- Write to register 2 (with RegDst = 0)
			instruction <= "000000" & "00001" & "00010" & "00000" & "00000" & "100000"; -- write to rt=2
			RegDst <= '0'; RegWrite <= '1'; MemToReg <= '0';
			alu_result <= X"55667788";
			wait for CLK_PERIOD;

			-- Issue a NOP or instruction that reads register 2 (rs=2)
			instruction <= "000000" & "00010" & "00000" & "00000" & "00000" & "100000"; -- rs=2 (read)
			RegWrite <= '0';
			wait for CLK_PERIOD;

			-- Now check the register_rs output for register 2's updated value
			check_output("RegDst = 0 write", "register_rs (reg 2)", register_rs, X"55667788");

        -- === FINAL SUMMARY ===
        wait for CLK_PERIOD;
        if test_passed then
            report "=== ALL TESTS PASSED ===" severity note;
        else
            report "=== SOME TESTS FAILED ===" severity error;
        end if;
        wait;
    end process;
end Behavioral;
